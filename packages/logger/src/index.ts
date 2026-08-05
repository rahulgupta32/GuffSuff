import pino, { LoggerOptions } from "pino";

const redactPaths = [
  "authorization",
  "headers.authorization",
  "cookie",
  "token",
  "password",
  "otp",
  "secret",
  "phoneNumber",
  "phone",
  "e164PhoneNumber",
  "messageText",
  "ciphertext"
];

export function createSafeLogger(serviceName: string): pino.Logger {
  const options: LoggerOptions = {
    name: serviceName,
    level: process.env.LOG_LEVEL || "info",
    redact: {
      paths: redactPaths,
      censor: "[REDACTED]"
    },
    base: {
      service: serviceName,
      env: process.env.NODE_ENV || "development"
    }
  };

  return pino(options);
}
