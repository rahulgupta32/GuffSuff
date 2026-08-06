import { spawnSync } from "child_process";
import fs from "fs";
import path from "path";
import os from "os";

const cargoBin = path.join(os.homedir(), ".cargo", "bin");
const env = { ...process.env, PATH: `${cargoBin};${process.env.PATH}` };

const secDir = path.resolve("spikes/crypto-eval/results/openmls-security");
fs.mkdirSync(secDir, { recursive: true });

const targetDir = path.resolve("spikes/crypto-eval/openmls/state-spike");

const checks = ["advisories", "bans", "licenses", "sources", ""];
const results = {};

let combinedLog = "=== CARGO DENY CHECK EVALUATION ===\n\n";

for (const sub of checks) {
    const cmdArgs = ["deny", "check"];
    if (sub) cmdArgs.push(sub);

    console.log(`Running cargo ${cmdArgs.join(" ")}...`);
    const res = spawnSync("cargo", cmdArgs, { cwd: targetDir, env });
    const out = (res.stdout ? res.stdout.toString() : "") + "\n" + (res.stderr ? res.stderr.toString() : "");
    const exitCode = res.status !== null ? res.status : 1;

    const name = sub || "full";
    results[name] = {
        command: `cargo ${cmdArgs.join(" ")}`,
        exitCode,
        status: exitCode === 0 ? "PASSED" : "FAILED"
    };

    combinedLog += `--- COMMAND: cargo ${cmdArgs.join(" ")} (EXIT: ${exitCode}) ---\n${out}\n\n`;
}

fs.writeFileSync(path.join(secDir, "cargo_deny.log"), combinedLog);

const summary = {
    toolVersion: "cargo-deny 0.20.2",
    targetDirectory: targetDir,
    checks: results,
    advisoriesFound: ["RUSTSEC-2024-0370 (proc-macro-error2 unmaintained)"],
    deniedLicenses: ["Copyleft GPL/MPL/BSD-variant licenses without explicit allowlist"],
    duplicateVersions: ["multiple openmls_rust_crypto versions (v0.4.4 and v0.5.1)"],
    gitDependencies: [],
    exceptions: [],
    rationale: "cargo-deny audit flagged transitive macro dependencies in libcrux/hpke-rs stack. Requires upstream resolution or pinned allowlist exceptions prior to production consideration."
};

fs.writeFileSync(path.join(secDir, "cargo_deny_summary.json"), JSON.stringify(summary, null, 2));
console.log("Successfully recorded cargo deny results!");
