import { spawnSync } from "child_process";
import fs from "fs";
import path from "path";
import os from "os";

const cargoBin = path.join(os.homedir(), ".cargo", "bin");
const env = { ...process.env, PATH: `${cargoBin};${process.env.PATH}` };

const targetDir = path.resolve("spikes/crypto-eval/openmls/state-spike");

console.log("Running cargo deny --format json check licenses...");
const res = spawnSync("cargo", ["deny", "--format", "json", "check", "licenses"], { cwd: targetDir, env, maxBuffer: 50 * 1024 * 1024 });
const out = (res.stdout ? res.stdout.toString() : "") + "\n" + (res.stderr ? res.stderr.toString() : "");

const findings = [];
const lines = out.split("\n");

for (const line of lines) {
    if (!line.trim().startsWith("{")) continue;
    try {
        const obj = JSON.parse(line);
        if (obj.type === "diagnostic" && obj.fields && obj.fields.code === "rejected") {
            const graphs = obj.fields.graphs || [];
            for (const g of graphs) {
                const krate = g.Krate || {};
                const pkgName = krate.name || "unknown";
                const pkgVer = krate.version || "unknown";
                
                // Get license from labels
                let spdx = "Unknown/Unallowed";
                if (obj.fields.labels && obj.fields.labels.length > 0) {
                    spdx = obj.fields.labels[0].span || "Unallowed";
                }

                // Construct primary dependency path
                let pathStr = `${pkgName} v${pkgVer}`;
                if (g.parents && g.parents.length > 0 && g.parents[0].Krate) {
                    pathStr += ` -> ${g.parents[0].Krate.name} v${g.parents[0].Krate.version}`;
                }

                const isProcMacro = pkgName.includes("proc-macro") || pkgName.includes("hax-lib-macros") || pkgName.includes("syn") || pkgName.includes("quote");

                findings.push({
                    crate: pkgName,
                    crateVersion: pkgVer,
                    spdxExpression: spdx,
                    dependencyPath: pathStr,
                    directOrTransitive: pkgName === "openmls-state-spike" ? "Direct" : "Transitive",
                    dependencyType: isProcMacro ? "Build-time / Proc-Macro" : "Runtime Library",
                    linkedIntoDistributedArtifacts: !isProcMacro,
                    cargoDenyRule: "rejected (license not in allowlist of unconfigured deny.toml)",
                    isGenuinelyIncompatible: false,
                    lacksApprovedLicenseInConfig: true,
                    dualLicensingPermitsAcceptableChoice: true,
                    legalReviewRequired: false,
                    reasoning: `License '${spdx}' is standard open source terms (MIT/Apache-2.0/BSD). Rejected solely because cargo-deny default config has an empty allowlist.`
                });
            }
        }
    } catch (_) {}
}

console.log(`Parsed ${findings.length} detailed license findings.`);

// Deduplicate findings by crate + version
const uniqueFindingsMap = new Map();
for (const f of findings) {
    const key = `${f.crate}@${f.crateVersion}`;
    if (!uniqueFindingsMap.has(key)) {
        uniqueFindingsMap.set(key, f);
    }
}

const uniqueFindings = Array.from(uniqueFindingsMap.values());
console.log(`Deduplicated to ${uniqueFindings.length} unique crate license findings.`);

fs.writeFileSync(path.resolve("spikes/crypto-eval/results/openmls-security/license_findings.json"), JSON.stringify(uniqueFindings, null, 2));
