import fs from "node:fs";
import path from "node:path";

const PROHIBITED_PATTERNS = [
  { name: "Private Key", regex: /-----BEGIN (RSA|EC|OPENSSH|PRIVATE) KEY-----/i },
  { name: "Database Credential URL", regex: /postgres:\/\/[a-zA-Z0-9_-]+:[^@]+@/i },
  { name: "Redis Password URL", regex: /redis:\/\/:[^@]+@/i },
  { name: "AWS Secret Key", regex: /aws_secret_access_key\s*=\s*['"][A-Za-z0-9\/+=]{40}['"]/i },
  { name: "Localhost Production Endpoint", regex: /https?:\/\/localhost:\d+\/api\/v1\/prod/i }
];

function scanDirectory(dir, errors = []) {
  if (!fs.existsSync(dir)) return errors;

  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      if (entry.name !== "node_modules" && entry.name !== ".git") {
        scanDirectory(fullPath, errors);
      }
    } else if (
      entry.isFile() &&
      (entry.name.endsWith(".js") || entry.name.endsWith(".json") || entry.name.endsWith(".html"))
    ) {
      const content = fs.readFileSync(fullPath, "utf-8");

      for (const pattern of PROHIBITED_PATTERNS) {
        if (pattern.regex.test(content)) {
          errors.push(
            `[SECRET SCAN VIOLATION] Found ${pattern.name} in built artifact: ${fullPath}`
          );
        }
      }
    }
  }

  return errors;
}

const buildDirs = [
  "apps/admin/.next",
  "packages/contracts/dist",
  "packages/crypto-adapter/dist",
  "services/api/dist"
];
let allErrors = [];

for (const buildDir of buildDirs) {
  allErrors = scanDirectory(path.resolve(process.cwd(), buildDir), allErrors);
}

if (allErrors.length > 0) {
  console.error("[BUILD-SECRET-SCAN-FAIL] Security violations detected in built artifacts:");
  allErrors.forEach((e) => console.error(e));
  process.exit(1);
} else {
  console.log(
    "[BUILD-SECRET-SCAN-PASS] Zero secrets or sensitive credentials detected in built artifacts."
  );
}
