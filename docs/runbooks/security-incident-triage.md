# Security Incident Runbook: Security Incident Triage & Escalation Master Workflow

> **Target Role**: `@oncall-engineer`, `@security-lead`  
> **Trigger**: Any security alert or anomaly report.

---

## Response Steps

1. **Determine Incident Level**: Classify event as SEV-1, SEV-2, SEV-3, or SEV-4 according to `docs/INCIDENT_RESPONSE.md`.
2. **Open Incident Log**: Record incident timestamp, symptoms, and assigned Incident Commander.
3. **Execute Relevant Runbook**: Trigger specialized runbook (1 through 11).
4. **Post-Incident Review**: Conduct blameless post-mortem within 48 hours and archive findings.
