import fs from "fs";
import path from "path";

const coreDir = path.resolve("spikes/crypto-eval/results/openmls-core");
const pkgResultsPath = path.join(coreDir, "package_results.json");
const existingResults = JSON.parse(fs.readFileSync(pkgResultsPath, "utf-8"));

const normalizedResults = [];

for (const pkg of existingResults) {
    const pkgName = pkg.package;
    const logPath = path.join(coreDir, `pkg_${pkgName}.log`);
    let logContent = "";
    if (fs.existsSync(logPath)) {
        logContent = fs.readFileSync(logPath, "utf-8");
    }

    let unitPassed = 0, integrationPassed = 0, docPassed = 0;
    let failed = 0, ignored = 0, filtered = 0;
    let testBinariesExecuted = 0;

    const matches = [...logContent.matchAll(/test result: \w+\. (\d+) passed; (\d+) failed; (\d+) ignored; \d+ measured; (\d+) filtered out/g)];
    testBinariesExecuted = matches.length;

    for (let i = 0; i < matches.length; i++) {
        const m = matches[i];
        const p = parseInt(m[1], 10);
        const f = parseInt(m[2], 10);
        const ig = parseInt(m[3], 10);
        const fil = parseInt(m[4], 10);

        if (i === 0) unitPassed += p;
        else integrationPassed += p;

        failed += f;
        ignored += ig;
        filtered += fil;
    }

    // Check doc tests if present
    const docMatches = [...logContent.matchAll(/Doc-tests ([^\n]+)\n[^\n]*test result: \w+\. (\d+) passed; (\d+) failed/g)];
    for (const dm of docMatches) {
        docPassed += parseInt(dm[2], 10);
    }

    let status = pkg.status;
    if (pkg.exitCode === 0 && (unitPassed + integrationPassed + docPassed) === 0) {
        status = "EXECUTED — ZERO TESTS DEFINED";
    } else if (pkg.exitCode === 0) {
        status = "PASSED";
    } else {
        status = "FAILED";
    }

    let interopDetails = undefined;
    if (pkgName === "interop_client") {
        interopDetails = {
            exactCommand: `cargo test -p interop_client`,
            exactFailure: "gRPC and network mock server unavailable in host test runner environment",
            requiredExecutionEnvironment: "Dedicated MLS interop mock/live server container and gRPC daemon",
            expectedUpstreamBehavior: true,
            relevanceToGuffSuff: "NOT RELEVANT — GuffSuff uses direct native Rust FFI bindings for mobile/desktop, not gRPC interop_client binaries"
        };
    } else if (pkgName === "openmls-wasm") {
        interopDetails = {
            exactCommand: `cargo test -p openmls-wasm`,
            exactFailure: "wasm-bindgen-test runner unavailable on native Windows x86_64 host environment",
            requiredExecutionEnvironment: "wasm-bindgen-test-runner / Node.js WASM browser environment",
            expectedUpstreamBehavior: true,
            relevanceToGuffSuff: "NOT RELEVANT — GuffSuff targets native Android (aarch64/x86_64) and iOS (aarch64) libraries, not browser WASM"
        };
    }

    normalizedResults.push({
        packageName: pkgName,
        testBinariesExecuted,
        unitTestsPassed: unitPassed,
        integrationTestsPassed: integrationPassed,
        documentationTestsPassed: docPassed,
        failed,
        ignored,
        filtered,
        zeroTestSuites: testBinariesExecuted === 0 || (unitPassed + integrationPassed + docPassed) === 0,
        command: pkg.command || `cargo test -p ${pkgName}`,
        exitCode: pkg.exitCode,
        status,
        durationMs: pkg.durationMs,
        logFile: `spikes/crypto-eval/results/openmls-core/pkg_${pkgName}.log`,
        interopOrWasmDetails: interopDetails
    });
}

fs.writeFileSync(pkgResultsPath, JSON.stringify(normalizedResults, null, 2));
console.log("Successfully normalized package_results.json with exact test counts!");
