const fs = require("fs");
const path = require("path");

console.log("[SECURITY-SCAN] Scanning repository for prohibited mock crypto symbols...");

const forbiddenSymbols = ["MockCryptoProvider", "DummyCryptoAdapter", "ReversibleTestCipher"];

let foundViolations = 0;

function scanDir(dir) {
  if (!fs.existsSync(dir)) return;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (["node_modules", ".git", "dist", ".next"].includes(entry.name)) continue;
      scanDir(fullPath);
    } else if (entry.isFile() && (entry.name.endsWith(".ts") || entry.name.endsWith(".js"))) {
      const content = fs.readFileSync(fullPath, "utf8");
      for (const sym of forbiddenSymbols) {
        if (content.includes(sym)) {
          console.error(
            `[SECURITY-VIOLATION] Found forbidden mock crypto symbol "${sym}" in ${fullPath}`
          );
          foundViolations++;
        }
      }
    }
  }
}

scanDir(path.join(__dirname, "..", "packages"));
scanDir(path.join(__dirname, "..", "services"));
scanDir(path.join(__dirname, "..", "apps"));

if (foundViolations > 0) {
  console.error(`[SECURITY-FAILURE] ${foundViolations} mock crypto violations detected.`);
  process.exit(1);
}

console.log("[SECURITY-PASS] Zero mock crypto symbols detected in production package boundaries.");
process.exit(0);
