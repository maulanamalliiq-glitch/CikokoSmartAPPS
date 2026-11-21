# Cikoko SmartApp 2.5.57 / build 2557 — PJLP

Status: development branch; NOT production enabled. No server API, Flutter screens, camera/GPS capture, monthly PDF, or signed build verified yet.

## Access
- PJLP: clock in/out, GPS and live selfie, work evidence at 0/50/100%.
- ASN: read-only monitoring and monthly reports.
- Admin Utama: office coordinates/radius, field assignments, monthly scoring weights, final approval.
- Approval must be enforced by PHP API, not merely by hiding Flutter buttons.

## Attendance
- Mon/Tue/Thu/Fri: office geofence with live selfie and GPS for BOTH check-in and check-out.
- Wednesday: no office geofence, but GPS and live selfie required for both events.
- Weekend: only when scheduled by admin; location rule must be configured explicitly.
- Office coordinates and geofence radius must be configured and verified by Admin, never guessed.
- Use server timestamps, GPS accuracy thresholds, anti-replay uploads, audit logs, explicit permission prompts.

## Work evidence
- Admin assigns each job to PJLP/team and records its authorized GPS location.
- 0%, 50%, 100% are three separate timestamped, geo-tagged photos for the SAME job.
- Upload to authenticated private storage; restrict access; never publicly expose selfies.
- Require 0 -> 50 -> 100 ordering; prevent duplicate stage submissions without audited corrections.

## Monthly recap
- Per-person and per-team monthly PDF; no PDF marked official until Admin Utama approves.
- Score: attendance 30%, completed assignments 50%, complete evidence 20% (PROPOSED weights; admin approval required).
- Count only server-verified attendance and validated job evidence.
- Snapshot approved monthly results, sign off with approver ID and server time, lock and audit amendments.
- PJLP can download own PDF; ASN can view assigned scope; Admin can export team PDFs.
- Privacy: limit location and selfie access, define retention policy, and use role-based server access.

## Development checklist
- [x] Release number bumped to 2.5.57+2557.
- [x] Pure Dart preliminary score/geofence rules added.
- [ ] PHP database migrations, permission middleware and authenticated APIs.
- [ ] Flutter attendance GPS/selfie and job-photo screens.
- [ ] ASN read-only dashboard and Admin approval screen.
- [ ] PDF rendering and secure downloads.
- [ ] Unit/integration tests and release build validation.
