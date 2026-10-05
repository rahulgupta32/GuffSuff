/** Production and staging must never use public development secrets. */
export function identitySecret(name: string, developmentFallback: string): string {
  const configured = process.env[name];
  const protectedEnvironment = ["production", "staging"].includes(process.env.NODE_ENV || "");
  if (
    protectedEnvironment &&
    (!configured || configured.length < 32 || configured === developmentFallback)
  ) {
    throw new Error(`Required identity secret ${name} is missing or unsafe`);
  }
  return configured || developmentFallback;
}
