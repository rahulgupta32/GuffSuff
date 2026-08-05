import { trace, Tracer } from "@opentelemetry/api";

export function initTracer(serviceName: string): Tracer {
  return trace.getTracer(serviceName, "0.1.0");
}
