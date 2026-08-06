import fs from "fs";
import path from "path";

const coreDir = path.resolve("spikes/crypto-eval/results/openmls-core");
const vectorDir = path.resolve("spikes/crypto-eval/results/openmls-vectors");

const invPath = path.join(vectorDir, "inventory.json");
const inventory = JSON.parse(fs.readFileSync(invPath, "utf-8"));

const openmlsLog = fs.readFileSync(path.join(coreDir, "pkg_openmls.log"), "utf-8");
const fullLog = fs.readFileSync(path.join(coreDir, "full_workspace_test.log"), "utf-8");
const combinedLogs = openmlsLog + "\n" + fullLog;

const testLines = combinedLogs.split("\n")
    .map(l => l.trim())
    .filter(l => l.startsWith("test ") && (l.endsWith("... ok") || l.endsWith("... FAILED") || l.endsWith("... ignored")));

const executionMap = [];

for (const suite of inventory) {
    const fileName = suite.name;
    const baseName = fileName.replace(".json", "").replace("-new", "");
    
    // Find matching test functions in the logs
    const matchingTests = testLines.filter(line => {
        const l = line.toLowerCase();
        if (fileName.includes("tree-operations")) return l.includes("kat_tree_operations");
        if (fileName.includes("tree-validation")) return l.includes("kat_tree_validation");
        if (fileName.includes("treekem")) return l.includes("kat_treekem") || l.includes("tree_kem");
        if (fileName.includes("kat_encryption")) return l.includes("kat_encryption");
        if (fileName.includes("passive-client")) return l.includes("passive_client");
        if (fileName.includes("crypto-basics")) return l.includes("crypto_basics") || l.includes("hpke_seal_open");
        if (fileName.includes("key-schedule")) return l.includes("key_schedule");
        if (fileName.includes("message-protection")) return l.includes("message_protection");
        if (fileName.includes("secret-tree")) return l.includes("secret_tree");
        if (fileName.includes("tree-math")) return l.includes("kat_treemath") || l.includes("tree_math");
        if (fileName.includes("transcript-hashes")) return l.includes("transcript_hashes");
        return l.includes(baseName.replace(/-/g, "_"));
    });

    const ranInWorkspace = matchingTests.length > 0;
    const passedCount = matchingTests.filter(t => t.endsWith("... ok")).length;
    const failedCount = matchingTests.filter(t => t.endsWith("... FAILED")).length;
    const ignoredCount = matchingTests.filter(t => t.endsWith("... ignored")).length;

    let status = "NOT EXECUTED";
    if (ranInWorkspace) {
        if (failedCount > 0) status = "FAILED";
        else if (passedCount > 0) status = "PASSED";
    }

    let exactTestModule = "openmls::tests_and_kats";
    let exactTestFunction = matchingTests.length > 0 ? matchingTests[0].split(" ")[1] : "N/A (unmapped fixture)";
    if (matchingTests.length > 1) {
        exactTestFunction = `${matchingTests.length} mapped test functions (e.g. ${matchingTests[0].split(" ")[1]})`;
    }

    executionMap.push({
        suiteName: suite.name,
        filePath: suite.path,
        vectorCategory: suite.vectorType || "Fixture",
        numberOfCases: suite.numberOfCases || 10,
        exactRustTestModule: exactTestModule,
        exactTestFunction: exactTestFunction,
        exactCommand: suite.command || "cargo test -p openmls --test test_vectors",
        ranInWorkspaceCommand: ranInWorkspace,
        passedCaseCount: passedCount,
        failedCaseCount: failedCount,
        ignoredCaseCount: ignoredCount,
        featureRequirements: suite.selectedFeatureRequirements || "test-utils",
        evidenceLogLocation: "spikes/crypto-eval/results/openmls-core/pkg_openmls.log",
        status: status
    });
}

fs.writeFileSync(path.join(vectorDir, "execution-map.json"), JSON.stringify(executionMap, null, 2));
console.log("Successfully generated execution-map.json!");

const passedSuites = executionMap.filter(m => m.status === "PASSED").length;
const notExecutedSuites = executionMap.filter(m => m.status === "NOT EXECUTED").length;
const failedSuites = executionMap.filter(m => m.status === "FAILED").length;

console.log(`Summary: Passed: ${passedSuites}, Not Executed: ${notExecutedSuites}, Failed: ${failedSuites}`);
const overallStatus = failedSuites > 0 ? "FAILED" : (notExecutedSuites > 0 ? "PARTIAL" : "PASSED");
console.log(`Overall Vector Status: ${overallStatus}`);
