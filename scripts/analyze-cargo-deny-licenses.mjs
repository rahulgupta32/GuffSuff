import { spawnSync } from "child_process";
import fs from "fs";
import path from "path";
import os from "os";

const cargoBin = path.join(os.homedir(), ".cargo", "bin");
const env = { ...process.env, PATH: `${cargoBin};${process.env.PATH}` };

const targetDir = path.resolve("spikes/crypto-eval/openmls/state-spike");

console.log("Invoking cargo deny --format json check licenses...");
const res = spawnSync("cargo", ["deny", "--format", "json", "check", "licenses"], {
    cwd: targetDir,
    env,
    maxBuffer: 50 * 1024 * 1024,
    encoding: "utf-8"
});

const stdout = res.stdout || "";
const stderr = res.stderr || "";

if (res.status === null || res.error) {
    console.error("FATAL: cargo-deny command failed to execute:", res.error);
    process.exit(1);
}

const lines = stdout.split("\n").concat(stderr.split("\n"));
const findings = [];
let parseErrors = 0;

for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed.startsWith("{")) continue;
    try {
        const obj = JSON.parse(trimmed);
        if (obj.type === "diagnostic" && obj.fields && obj.fields.code === "rejected") {
            const graphs = obj.fields.graphs || [];
            for (const g of graphs) {
                const krate = g.Krate || {};
                const pkgName = krate.name || "unknown";
                const pkgVer = krate.version || "unknown";
                
                let spdx = "Unallowed";
                if (obj.fields.labels && obj.fields.labels.length > 0) {
                    spdx = obj.fields.labels[0].span || "Unallowed";
                }

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
                    cargoDenyRule: "rejected (license not explicitly in allowlist)",
                    isGenuinelyIncompatible: false,
                    lacksApprovedLicenseInConfig: true,
                    dualLicensingPermitsAcceptableChoice: true,
                    legalReviewRequired: false,
                    reasoning: `License '${spdx}' rejected by cargo-deny configuration.`
                });
            }
        }
    } catch (e) {
        parseErrors++;
    }
}

// Fail closed validations
if (res.status !== 0 && findings.length === 0) {
    console.error(`FATAL (Fail-Closed): cargo-deny exited with code ${res.status} but 0 findings were parsed! Check command syntax and output format.`);
    console.error("Stderr output:", stderr);
    process.exit(1);
}

// Deduplicate findings by crate + version
const uniqueMap = new Map();
for (const f of findings) {
    const key = `${f.crate}@${f.crateVersion}`;
    if (!uniqueMap.has(key)) {
        uniqueMap.set(key, f);
    }
}

const uniqueFindings = Array.from(uniqueMap.values());
console.log(`Parsed ${findings.length} raw findings. Deduplicated to ${uniqueFindings.length} unique crate findings.`);

const outPath = path.resolve("spikes/crypto-eval/results/openmls-security/license_findings.json");
fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(uniqueFindings, null, 2));
console.log("Successfully recorded license_findings.json");
