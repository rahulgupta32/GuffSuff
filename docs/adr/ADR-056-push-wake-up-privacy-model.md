# ADR-056: Push Wake-Up Privacy Model

## Context

Push notification providers (FCM / APNs) operate outside GuffSuff trust boundaries.

## Decision

1. Push notifications convey ONLY opaque background wake-up triggers.
2. Push payloads MUST NOT contain sender names, phone numbers, usernames, conversation IDs, message content, previews, or attachment keys.
3. Received push events signal the mobile background service to fetch encrypted envelopes via authenticated REST/WebSocket endpoints.

## Consequences

- Prevents metadata and content exposure to third-party push notification networks.
