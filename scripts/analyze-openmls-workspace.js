import { execSync, spawnSync } from "child_process";
import fs from "fs";
import path from "path";
import os from "os";

const cargoBin = path.join(os.homedir(), ".cargo", "bin");
const env = { ...process.env, PATH: `${cargoBin};${process.env.PATH}` };

const checkoutDir = path.join(os.tmpdir(), "openmls-full-analysis-" + Date.now());
console.log(`Cloning OpenMLS v0.8.1 into isolated directory: ${checkoutDir}`);

fs.mkdirSync(path.resolve("spikes/crypto-eval/results/openmls-core"), { recursive: true });
fs.mkdirSync(path.resolve("spikes/crypto-eval/results/openmls-vectors"), { recursive: true });

try {
  execSync(`git clone --depth 1 --branch openmls-v0.8.1 https://github.com/openmls/openmls.git "${checkoutDir}"`, { stdio: "inherit", env });

  const headSha = execSync(`git rev-parse HEAD`, { cwd: checkoutDir, env }).toString().trim();
  const tagExact = execSync(`git describe --tags --exact-match`, { cwd: checkoutDir, env }).toString().trim();
  console.log(`Head SHA: ${headSha}, Exact Tag: ${tagExact}`);

  execSync(`cargo generate-lockfile`, { cwd: checkoutDir, stdio: "inherit", env });

  const metadataJson = execSync(`cargo metadata --locked --format-version 1`, { cwd: checkoutDir, maxBuffer: 50 * 1024 * 1024, env }).toString();
  fs.writeFileSync(path.resolve("spikes/crypto-eval/results/openmls-core/cargo_metadata.json"), metadataJson);

  const parsedMeta = JSON.parse(metadataJson);
  const workspaceMembers = parsedMeta.workspace_members.map(id => {
    const pkg = parsedMeta.packages.find(p => p.id === id);
    return pkg ? pkg.name : id;
  });
  console.log("Workspace Members:", workspaceMembers);

  console.log(`Running cargo test --workspace --locked --no-fail-fast...`);
  const fullRes = spawnSync("cargo", ["test", "--workspace", "--locked", "--no-fail-fast"], { cwd: checkoutDir, env, maxBuffer: 100 * 1024 * 1024 });
  const fullTestLog = (fullRes.stdout ? fullRes.stdout.toString() : "") + "\n" + (fullRes.stderr ? fullRes.stderr.toString() : "");
  const fullExitCode = fullRes.status !== null ? fullRes.status : 1;

  fs.writeFileSync(path.resolve("spikes/crypto-eval/results/openmls-core/full_workspace_test.log"), `EXIT_CODE: ${fullExitCode}\n\n` + fullTestLog);
  console.log(`Full workspace test finished with exit code ${fullExitCode}`);

  console.log(`Evaluating individual supported workspace packages...`);
  const packageResults = [];
  for (const pkgName of workspaceMembers) {
    console.log(`Testing package: ${pkgName}...`);
    let startTime = Date.now();
    const pRes = spawnSync("cargo", ["test", "-p", pkgName], { cwd: checkoutDir, env, maxBuffer: 50 * 1024 * 1024 });
    const pOut = (pRes.stdout ? pRes.stdout.toString() : "") + "\n" + (pRes.stderr ? pRes.stderr.toString() : "");
    const pExit = pRes.status !== null ? pRes.status : 1;
    let durationMs = Date.now() - startTime;

    fs.writeFileSync(path.resolve(`spikes/crypto-eval/results/openmls-core/pkg_${pkgName}.log`), pOut);

    let passed = 0, failed = 0, ignored = 0, filtered = 0;
    const matches = [...pOut.matchAll(/test result: \w+\. (\d+) passed; (\d+) failed; (\d+) ignored; \d+ measured; (\d+) filtered out/g)];
    for (const m of matches) {
      passed += parseInt(m[1], 10);
      failed += parseInt(m[2], 10);
      ignored += parseInt(m[3], 10);
      filtered += parseInt(m[4], 10);
    }

    packageResults.push({
      package: pkgName,
      command: `cargo test -p ${pkgName}`,
      exitCode: pExit,
      status: pExit === 0 ? (passed === 0 ? "EXECUTED — ZERO TESTS DEFINED" : "PASSED ON WINDOWS") : "FAILED ON WINDOWS",
      passed,
      failed,
      ignored,
      filtered,
      durationMs
    });
  }
  fs.writeFileSync(path.resolve("spikes/crypto-eval/results/openmls-core/package_results.json"), JSON.stringify(packageResults, null, 2));

  console.log(`Discovering vector suites in OpenMLS repo...`);
  const vectorInventory = [];
  function scanForVectors(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const e of entries) {
      const fullPath = path.join(dir, e.name);
      if (e.isDirectory() && !e.name.startsWith(".")) {
        scanForVectors(fullPath);
      } else if (e.isFile() && (e.name.includes("vector") || e.name.includes("fixture") || e.name.endsWith(".json"))) {
        const relPath = path.relative(checkoutDir, fullPath);
        vectorInventory.push({
          name: e.name,
          path: relPath,
          upstreamOrigin: "OpenMLS v0.8.1 Official Repository",
          vectorType: e.name.includes("vector") ? "Test Vector" : "Fixture",
          numberOfCases: 0,
          command: "cargo test --test test_vectors",
          selectedFeatureRequirements: "test-utils",
          executionStatus: "NOT EXECUTED",
          evidenceLog: `spikes/crypto-eval/results/openmls-vectors/${e.name}.log`
        });
      }
    }
  }
  scanForVectors(checkoutDir);
  fs.writeFileSync(path.resolve("spikes/crypto-eval/results/openmls-vectors/inventory.json"), JSON.stringify(vectorInventory, null, 2));

  console.log("=== ANALYSIS COMPLETE ===");
} catch (err) {
  console.error("Analysis Error:", err.message);
} finally {
  if (fs.existsSync(checkoutDir)) {
    try {
      fs.rmSync(checkoutDir, { recursive: true, force: true });
    } catch (_) {}
  }
}
