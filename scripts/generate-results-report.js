import fs from "fs";
import path from "path";

const resultsPath = path.resolve("spikes/crypto-eval/results/results.json");

if (!fs.existsSync(resultsPath)) {
  console.error("results.json not found!");
  process.exit(1);
}

const data = JSON.parse(fs.readFileSync(resultsPath, "utf-8"));

console.log(`=== CRYPTO SPIKE EXECUTION REPORT ===`);
console.log(`Branch Commit: ${data.branchCommit}`);
console.log(`Timestamp: ${data.timestamp}\n`);

console.log(`| Candidate | Environment | Status | Command | Exit Code | Evidence Path |`);
console.log(`| :--- | :--- | :--- | :--- | :--- | :--- |`);

for (const r of data.results) {
  console.log(`| ${r.candidate} (${r.candidateTag}) | ${r.environment} | \`${r.status}\` | \`${r.command}\` | ${r.exitCode} | [${path.basename(r.evidencePath)}](${r.evidencePath}) |`);
}
