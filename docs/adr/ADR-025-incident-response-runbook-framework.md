# ADR-025: Operational Incident Response Runbook Framework

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Security Operations Lead
- **Decision Status**: Proposed

## Context

Unstructured incident response during security breaches increases downtime and risk of procedural errors.

## Decision

Maintain 12 dedicated markdown runbooks in `docs/runbooks/` mapped to SEV1-4 severity tiers. Public runbooks use role aliases rather than personal contact information.
