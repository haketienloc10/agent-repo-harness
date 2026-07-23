# Known debt

## DEBT-009: Refresh tokens appear in debug logs

- Evidence: `src/auth/session.sh` writes refresh tokens to debug logs.
- Risk: credentials can leak through retained logs.
- Review trigger: close after the log-redaction test passes.
- Status: Open
