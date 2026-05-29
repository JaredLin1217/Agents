# Controller Lease

- Controller id:
- Lease id:
- Acquired at:
- Last heartbeat:
- Expires at:
- Current task:
- Snapshot version reviewed:
- Released at:
- Takeover reason:

## Rules

- Only active lease holder writes the shared status snapshot or marks events processed.
- Renew before expiry while coordinating employees.
- Take over only after expiry, explicit release, or explicit user authorization.
- If lease state is ambiguous, choose an active controller before writing shared status.
