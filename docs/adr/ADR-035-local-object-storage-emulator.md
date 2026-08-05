# ADR-035: Local S3 Object Storage Development Emulator

- **Status**: Proposed Architecture Baseline
- **Date**: 2026-08-05
- **Deciders**: Lead Infrastructure Engineer
- **Decision Status**: Proposed

## Context

Local development requires an S3-compatible object storage emulator for testing encrypted media attachment uploads without cloud provider dependencies or real AWS credentials.

## Decision

We adopt **MinIO** in Docker Compose as the local S3-compatible object storage emulator. MinIO buckets are configured private by default with fake development credentials.
