#!/usr/bin/env bash

set -euo pipefail

HARNESS_REPOSITORY="${HARNESS_REPOSITORY:-haketienloc10/agent-repo-harness}"
HARNESS_REF="${HARNESS_REF:-main}"
GITHUB_ARCHIVE_BASE_URL="${GITHUB_ARCHIVE_BASE_URL:-https://github.com}"
HARNESS_INSTALL_MODE="${HARNESS_INSTALL_MODE:-}"

usage() {
  cat <<'USAGE'
Usage: curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | bash -s -- --target /path/to/target [--mode workspace|repository] [--dry-run] [--overwrite]

Downloads the harness source archive from GitHub, lets the user choose a target
shape, and installs the matching template.

Modes:
  workspace   Install workspace-template into a workspace containing multiple
              independent Git repositories.
  repository  Install repo-template into one Git repository. This delegates to
              install.sh and preserves the existing installer behavior.

Options:
  --target PATH  Existing workspace root or Git repository root.
  --mode MODE    workspace or repository. When omitted, read the choice from
                 /dev/tty so the menu also works with curl | bash.
  --dry-run      Report actions without changing the filesystem.
  --overwrite    Back up and replace conflicting harness files.
  -h, --help     Show this help.

Environment:
  HARNESS_REPOSITORY       GitHub repository in OWNER/REPO form.
                           Default: haketienloc10/agent-repo-harness
  HARNESS_REF              Branch, tag, or commit SHA to install.
                           Default: main
  HARNESS_INSTALL_MODE     Non-interactive default: workspace or repository.
  GITHUB_ARCHIVE_BASE_URL  GitHub base URL. Intended for testing or GitHub Enterprise.
                           Default: https://github.com
USAGE
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

normalize_mode() {
  case "$1" in
    1|workspace)
      printf 'workspace\n'
      ;;
    2|repository|repo)
      printf 'repository\n'
      ;;
    *)
      return 1
      ;;
  esac
}

select_mode() {
  local selected="${HARNESS_INSTALL_MODE:-}"
  local normalized=""

  if [[ -n "$selected" ]]; then
    normalized="$(normalize_mode "$selected")" || \
      fail "unsupported install mode: $selected (expected workspace or repository)."
    printf '%s\n' "$normalized"
    return
  fi

  [[ -r /dev/tty && -w /dev/tty ]] || \
    fail "cannot open an interactive terminal; pass --mode workspace or --mode repository."

  while true; do
    cat > /dev/tty <<'MENU'
Select installation type:
  1. Multi-repository workspace
  2. Single Git repository
Choice [1-2]:
MENU
    IFS= read -r selected < /dev/tty || fail "could not read installation type."
    if normalized="$(normalize_mode "$selected")"; then
      printf '%s\n' "$normalized"
      return
    fi
    printf 'Invalid choice. Enter 1 or 2.\n' > /dev/tty
  done
}

target_input=""
mode_input=""
dry_run=false
overwrite=false

while (($# > 0)); do
  case "$1" in
    --target)
      (($# >= 2)) || fail "--target requires a path."
      [[ -z "$target_input" ]] || fail "--target may only be specified once."
      target_input="$2"
      shift 2
      ;;
    --mode)
      (($# >= 2)) || fail "--mode requires workspace or repository."
      [[ -z "$mode_input" ]] || fail "--mode may only be specified once."
      mode_input="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --overwrite)
      overwrite=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

[[ -n "$target_input" ]] || fail "--target is required."
[[ -d "$target_input" ]] || fail "target does not exist or is not a directory: $target_input"
TARGET_DIR="$(cd -- "$target_input" && pwd -P)" || fail "cannot resolve target: $target_input"

if [[ -n "$mode_input" ]]; then
  HARNESS_INSTALL_MODE="$mode_input"
fi
install_mode="$(select_mode)"

nested_git_marker="$(find "$TARGET_DIR" -mindepth 2 \( -type d -o -type f \) -name .git -print -quit 2>/dev/null || true)"
if [[ "$install_mode" == "repository" && -n "$nested_git_marker" ]]; then
  fail "target contains a nested Git repository at ${nested_git_marker#"$TARGET_DIR"/}; choose workspace mode."
fi
if [[ "$install_mode" == "workspace" && -z "$nested_git_marker" ]]; then
  printf 'Warning: no nested Git repository was found under the workspace target. Setup may remain blocked until modules are cloned.\n' >&2
fi

[[ "$HARNESS_REPOSITORY" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || \
  fail "HARNESS_REPOSITORY must use OWNER/REPO form."
[[ "$HARNESS_REF" =~ ^[A-Za-z0-9._/-]+$ && "$HARNESS_REF" != . && "$HARNESS_REF" != ./* && \
  "$HARNESS_REF" != */. && "$HARNESS_REF" != .. && "$HARNESS_REF" != ../* && \
  "$HARNESS_REF" != */../* && "$HARNESS_REF" != */.. ]] || \
  fail "HARNESS_REF contains unsupported characters."
command -v curl >/dev/null 2>&1 || fail "curl is required."
command -v tar >/dev/null 2>&1 || fail "tar is required."

if [[ "$dry_run" == true && "$overwrite" == true ]]; then
  printf 'Mode: %s, dry-run with overwrite preview\n' "$install_mode"
elif [[ "$dry_run" == true ]]; then
  printf 'Mode: %s, dry-run\n' "$install_mode"
elif [[ "$overwrite" == true ]]; then
  printf 'Mode: %s, overwrite with backup\n' "$install_mode"
else
  printf 'Mode: %s, safe install (no overwrite)\n' "$install_mode"
fi
printf 'Target: %s\n' "$TARGET_DIR"

temporary_dir="$(mktemp -d)" || fail "cannot create temporary directory."
cleanup() {
  rm -rf -- "$temporary_dir"
}
trap cleanup EXIT

archive_path="$temporary_dir/harness.tar.gz"
source_dir="$temporary_dir/source"
archive_url="${GITHUB_ARCHIVE_BASE_URL%/}/${HARNESS_REPOSITORY}/archive/${HARNESS_REF}.tar.gz"

printf 'Downloading harness from %s at ref %s...\n' "$HARNESS_REPOSITORY" "$HARNESS_REF"
curl --fail --location --silent --show-error --retry 3 --output "$archive_path" "$archive_url" || \
  fail "could not download harness archive: $archive_url"

mkdir -p -- "$source_dir"
tar -xzf "$archive_path" -C "$source_dir" --strip-components=1 || \
  fail "downloaded archive is not a valid harness source archive."

workspace_conflict_count=0
workspace_created_count=0
workspace_skipped_count=0
workspace_backup_created=false
workspace_unsafe_parent=""
workspace_backup_root="$TARGET_DIR/.harness/backups/$(date -u +'%Y%m%dT%H%M%SZ')-$$"

validate_relative_path() {
  local path="$1"
  [[ -n "$path" && "$path" != /* && "$path" != ".." && "$path" != ../* && "$path" != */../* && "$path" != */.. ]]
}

find_workspace_unsafe_parent() {
  local relative_path="$1"
  local parent_path current component
  local -a components

  workspace_unsafe_parent=""
  parent_path="$(dirname -- "$relative_path")"
  [[ "$parent_path" != "." ]] || return 1
  current="$TARGET_DIR"
  IFS='/' read -r -a components <<< "$parent_path"
  for component in "${components[@]}"; do
    current="$current/$component"
    if [[ -L "$current" || ( -e "$current" && ! -d "$current" ) ]]; then
      workspace_unsafe_parent="$current"
      return 0
    fi
  done
  return 1
}

ensure_workspace_backup_root() {
  [[ "$workspace_backup_created" == false ]] || return 0
  [[ ! -L "$TARGET_DIR/.harness" && ( ! -e "$TARGET_DIR/.harness" || -d "$TARGET_DIR/.harness" ) ]] || \
    fail "cannot create backups under unsafe path: $TARGET_DIR/.harness"
  [[ ! -L "$TARGET_DIR/.harness/backups" && ( ! -e "$TARGET_DIR/.harness/backups" || -d "$TARGET_DIR/.harness/backups" ) ]] || \
    fail "cannot use unsafe backup path: $TARGET_DIR/.harness/backups"
  mkdir -p -- "$workspace_backup_root" || fail "cannot create backup directory: $workspace_backup_root"
  workspace_backup_created=true
}

backup_workspace_file() {
  local relative_path="$1"
  local destination="$TARGET_DIR/$relative_path"
  local backup_path="$workspace_backup_root/$relative_path"

  ensure_workspace_backup_root
  mkdir -p -- "$(dirname -- "$backup_path")" || fail "cannot create backup parent for: $relative_path"
  cp -a -- "$destination" "$backup_path" || fail "cannot back up: $relative_path"
}

record_workspace_conflict() {
  printf 'Conflicts: %s\n' "$1"
  ((workspace_conflict_count += 1))
}

copy_workspace_file() {
  local template_dir="$1"
  local source_path="$2"
  local relative_path="${source_path#"$template_dir"/}"
  local destination="$TARGET_DIR/$relative_path"

  validate_relative_path "$relative_path" || fail "unsafe path in workspace-template: $relative_path"

  if find_workspace_unsafe_parent "$relative_path"; then
    record_workspace_conflict "$relative_path (unsafe parent path: $workspace_unsafe_parent)"
    return
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    if [[ -f "$destination" && ! -L "$destination" ]] && cmp -s -- "$source_path" "$destination"; then
      printf 'Skipped: %s (already current)\n' "$relative_path"
      ((workspace_skipped_count += 1))
      return
    fi
    if [[ "$overwrite" != true ]]; then
      record_workspace_conflict "$relative_path (existing path preserved)"
      return
    fi
    if [[ -d "$destination" && ! -L "$destination" ]]; then
      record_workspace_conflict "$relative_path (existing directory cannot be overwritten as a file)"
      return
    fi
    if [[ "$dry_run" == true ]]; then
      printf 'Created: %s (would overwrite; backup: %s)\n' "$relative_path" "$workspace_backup_root/$relative_path"
      ((workspace_created_count += 1))
      return
    fi
    backup_workspace_file "$relative_path"
    rm -f -- "$destination" || fail "cannot replace: $relative_path"
    mkdir -p -- "$(dirname -- "$destination")" || fail "cannot create parent for: $relative_path"
    cp -p -- "$source_path" "$destination" || fail "cannot install: $relative_path"
    printf 'Created: %s (overwritten; backup: %s)\n' "$relative_path" "$workspace_backup_root/$relative_path"
    ((workspace_created_count += 1))
    return
  fi

  if [[ "$dry_run" == true ]]; then
    printf 'Created: %s (dry-run)\n' "$relative_path"
  else
    mkdir -p -- "$(dirname -- "$destination")" || fail "cannot create parent for: $relative_path"
    cp -p -- "$source_path" "$destination" || fail "cannot install: $relative_path"
    printf 'Created: %s\n' "$relative_path"
  fi
  ((workspace_created_count += 1))
}

install_workspace_template() {
  local template_dir="$source_dir/workspace-template"
  local source_path template_symlink
  local template_file_count=0

  [[ -d "$template_dir" ]] || fail "downloaded archive is missing workspace-template."
  template_symlink="$(find "$template_dir" -type l -print -quit)"
  [[ -z "$template_symlink" ]] || fail "workspace-template contains unsupported symlink: $template_symlink"

  while IFS= read -r -d '' source_path; do
    copy_workspace_file "$template_dir" "$source_path"
    ((template_file_count += 1))
  done < <(find "$template_dir" -type f -print0)

  ((template_file_count > 0)) || fail "workspace-template does not contain any files."

  printf '\nSummary: Created=%d Skipped=%d Conflicts=%d\n' \
    "$workspace_created_count" "$workspace_skipped_count" "$workspace_conflict_count"
  if [[ "$workspace_backup_created" == true ]]; then
    printf 'Backups: %s\n' "$workspace_backup_root"
  fi

  if ((workspace_conflict_count > 0)); then
    return 2
  fi
  return 0
}

print_agent_prompt() {
  local status="$1"

  printf '\n=== PROMPT CHO AGENT ===\n'
  if [[ "$dry_run" == true ]]; then
    cat <<'PROMPT'
Đây mới là dry-run; chưa có file harness nào được cài hoặc ghi đè.

Hãy review danh sách `Created`, `Skipped` và `Conflicts` ở phía trên. Xử lý hoặc xác nhận các conflict cần thiết, sau đó chạy lại cùng lệnh nhưng bỏ `--dry-run`. Chỉ giao prompt takeover cho agent sau khi lần cài đặt thật hoàn tất.
PROMPT
    printf '=== HẾT PROMPT ===\n'
    return
  fi

  if ((status == 2)); then
    printf '%s\n\n' 'Cài đặt có Conflicts. Trước tiên hãy review từng conflict, giữ nguyên file thuộc dự án khi chưa có bằng chứng rằng có thể thay thế, rồi mới tiếp tục quy trình bên dưới.'
  fi

  if [[ "$install_mode" == "workspace" ]]; then
    cat <<'PROMPT'
Bạn đang hoàn tất việc thiết lập harness cho một local workspace chứa nhiều Git repository độc lập.

Hãy thực hiện đúng thứ tự sau:
1. Làm việc tại workspace root vừa được cài harness.
2. Đọc toàn bộ `docs/WORKSPACE_SETUP.md` và tuân thủ quy trình trong đó.
3. Chỉ khảo sát read-only; không reset, clean, stash, rebase, commit, format, update dependency, chạy migration hoặc sửa source code trong các repo con.
4. Lập inventory có bằng chứng cho từng Git repository local: Git root, remote, branch, revision, working tree, vai trò, dependency, entrypoint/runtime và các command bootstrap/verify/start/debug.
5. Điền `repos.yaml` và `SYSTEM_MAP.md` chỉ bằng thông tin lấy từ code, manifest, CI, deployment config hoặc tài liệu hiện hữu. Không tự phát minh dữ liệu còn thiếu.
6. Thay toàn bộ placeholder dạng `{{...}}` trong artifact workspace.
7. Chạy `./scripts/workspace-check.sh` từ workspace root.
8. Chỉ báo workspace là ready khi checker trả exit `0`; nếu bị chặn vì thiếu module, owner, contract hoặc command, hãy báo rõ bằng chứng thiếu và hành động cần người dùng cung cấp.

Không bắt đầu task sản phẩm trước khi hoàn tất các bước trên.
PROMPT
  else
    cat <<'PROMPT'
Bạn đang hoàn tất việc thiết lập harness cho một Git repository.

Hãy thực hiện đúng thứ tự sau:
1. Làm việc tại repository root vừa được cài harness.
2. Đọc toàn bộ `docs/HARNESS_SETUP.md` và tuân thủ quy trình takeover trong đó.
3. Bắt đầu bằng khảo sát read-only, ghi nhận baseline revision và không sửa source code trong giai đoạn khảo sát.
4. Xác định command bootstrap, build, test, lint, type-check, start và các guardrail cơ học từ bằng chứng trong repo.
5. Chạy các command an toàn đã chọn và cập nhật kết quả thực tế vào `docs/PROJECT_BASELINE.md`.
6. Chỉ ghi failure được chứng minh tại baseline revision vào `docs/LEGACY_ISSUES.md`; regression mới phải được sửa, không được hợp thức hóa thành legacy issue hoặc technical debt.
7. Tạo execution-plan artifact trong `docs/exec-plans/active/` khi còn công việc takeover cần theo dõi.
8. Chạy `./scripts/harness-check.sh`.
9. Chỉ báo repository là ready khi checker trả exit `0`; nếu bị chặn, hãy nêu chính xác artifact, bằng chứng hoặc quyết định còn thiếu.

Không bắt đầu task sản phẩm trước khi hoàn tất các bước trên.
PROMPT
  fi
  printf '=== HẾT PROMPT ===\n'
}

installer_status=0
if [[ "$install_mode" == "workspace" ]]; then
  printf 'Running workspace-template installer...\n'
  set +e
  install_workspace_template
  installer_status=$?
  set -e
else
  [[ -f "$source_dir/install.sh" ]] || fail "downloaded archive does not contain install.sh."
  [[ -d "$source_dir/repo-template" ]] || fail "downloaded archive is missing repo-template."
  [[ -f "$source_dir/repo-template/.harness-required-files" ]] || \
    fail "downloaded archive is missing repo-template/.harness-required-files."

  repository_args=(--target "$TARGET_DIR")
  [[ "$dry_run" == true ]] && repository_args+=(--dry-run)
  [[ "$overwrite" == true ]] && repository_args+=(--overwrite)

  printf 'Running repository installer...\n'
  set +e
  HARNESS_SOURCE="github:$HARNESS_REPOSITORY" HARNESS_REF="$HARNESS_REF" \
    bash "$source_dir/install.sh" "${repository_args[@]}"
  installer_status=$?
  set -e
fi

if ((installer_status == 0 || installer_status == 2)); then
  print_agent_prompt "$installer_status"
fi

exit "$installer_status"
