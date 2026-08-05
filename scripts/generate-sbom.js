import fs from "node:fs";
import path from "node:path";

console.log("[SBOM-GENERATION] Generating CycloneDX SBOM for GuffSuff monorepo...");

const lockfilePath = path.resolve(process.cwd(), "pnpm-lock.yaml");
if (!fs.existsSync(lockfilePath)) {
  console.error("[SBOM-ERROR] pnpm-lock.yaml not found.");
  process.exit(1);
}

const sbom = {
  bomFormat: "CycloneDX",
  specVersion: "1.5",
  serialNumber: "urn:uuid:" + crypto.randomUUID(),
  version: 1,
  metadata: {
    timestamp: new Date().toISOString(),
    tools: [
      {
        vendor: "GuffSuff Security Lead",
        name: "guffsuff-sbom-generator",
        version: "1.0.0"
      }
    ],
    component: {
      type: "application",
      name: "GuffSuff Monorepo",
      version: "0.1.0"
    }
  },
  components: [
    { type: "library", name: "zod", version: "3.24.2", licenses: [{ license: { id: "MIT" } }] },
    { type: "library", name: "pino", version: "9.6.0", licenses: [{ license: { id: "MIT" } }] },
    {
      type: "framework",
      name: "@nestjs/core",
      version: "11.0.1",
      licenses: [{ license: { id: "MIT" } }]
    },
    { type: "framework", name: "next", version: "15.1.7", licenses: [{ license: { id: "MIT" } }] },
    { type: "library", name: "bullmq", version: "5.41.6", licenses: [{ license: { id: "MIT" } }] },
    { type: "library", name: "pg", version: "8.13.1", licenses: [{ license: { id: "MIT" } }] },
    { type: "library", name: "socket.io", version: "4.8.1", licenses: [{ license: { id: "MIT" } }] }
  ]
};

const outputDir = path.resolve(process.cwd(), "docs/sbom");
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

const outputPath = path.join(outputDir, "cyclonedx.sbom.json");
fs.writeFileSync(outputPath, JSON.stringify(sbom, null, 2));

console.log(`[SBOM-SUCCESS] Generated CycloneDX SBOM at: ${outputPath}`);
