# GuffSuff Offline Delivery Specification

> **Document Status**: Phase 5 Offline Delivery Standard

---

## 1. Resilience & Retry Guarantees

1. **At-Least-Once Delivery**: Undelivered envelopes are retained in PostgreSQL and retried until delivered or expired.
2. **Exponential Backoff with Jitter**: Retries use initial 5s delay doubled per attempt up to 5 max retries with random jitter (+/- 20%).
3. **Database Single System of Record**: If API nodes, Realtime WebSocket gateways, or Redis instances crash or restart, pending envelope delivery state is fully preserved in PostgreSQL.
4. **Reconnect Querying**: Mobile devices executing WSS reconnect or app resume automatically query `GET /api/v1/conversations/:id/envelopes/pending` to catch up on undelivered envelopes.
5. **Duplicate Suppression**: Mobile client maintains local `envelope_id` set indexing to ignore duplicate envelope deliveries.
