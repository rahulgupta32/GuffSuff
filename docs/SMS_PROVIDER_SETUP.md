# SMS delivery configuration

The Twilio Programmable Messaging adapter is optional and disabled unless explicitly configured. No tester numbers, credentials or live sends are included in this repository.

Set these in the private server secret manager:

- `SMS_PROVIDER=twilio`
- `TWILIO_ACCOUNT_SID`: the configured account SID.
- `TWILIO_AUTH_TOKEN`: its auth token.
- `TWILIO_MESSAGING_SERVICE_SID`: the approved messaging service SID.
- `REGISTRATION_LOCK_PEPPER`: private secret of at least 32 characters, stable across deployments.

Apply migrations through 005 before enabling the adapter. OTP submission receives the normalized Nepal destination transiently; it is not added to OTP challenge records. Unknown SMS prices are stored as null, not an invented zero cost. API acceptance is recorded as ACCEPTED, not DELIVERED. Failed submissions invalidate the challenge and cannot silently fall back to the development simulator.

The adapter follows [Twilio's Messages resource](https://www.twilio.com/docs/messaging/api/message-resource). It sends form-encoded To, MessagingServiceSid and Body to the fixed HTTPS messages endpoint, with Basic authentication, a timeout and redirect rejection. HTTP errors and malformed responses are sanitized.

Before any beta SMS campaign, the operator must confirm provider account/sender approval, Nepal destination permissions, carrier delivery and spend controls. API unit tests use an injected fake request and do not establish any of those conditions. Delivery receipts, billing reconciliation, global/IP rate limits and operational alerts remain launch requirements. An alternative Nepal SMS provider can be added through the same interface after its API and operational terms are evaluated.

Returning-user login requires a verified, unexpired, unconsumed challenge for the same phone. A configured registration PIN remains mandatory. Five failed PIN attempts in 30 minutes block further attempts. Forgotten-PIN reset is not implemented and must not be replaced by an OTP-only bypass.
