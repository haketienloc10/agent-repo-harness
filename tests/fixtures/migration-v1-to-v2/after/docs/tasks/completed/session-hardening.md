# Session hardening

## Final outcome

Refresh cookies are now `HttpOnly` and `SameSite=Strict`.

## Decision

The gateway owns cookie policy so downstream handlers cannot weaken it.

## Verification evidence

`./project-checks/test.sh session-security` exited 0.

## Durable extraction

The cookie contract was extracted to the authentication security contract.
