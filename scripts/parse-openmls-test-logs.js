import fs from "fs";
import path from "path";

const coreDir = path.resolve("spikes/crypto-eval/results/openmls-core");
const vectorDir = path.resolve("spikes/crypto-eval/results/openmls-vectors");

const openmlsLog = fs.readFileSync(path.join(coreDir, "pkg_openmls.log"), "utf-8");
const fullLog = fs.readFileSync(path.join(coreDir, "full_workspace_test.log"), "utf-8");

const allLogs = openmlsLog + "\n" + fullLog;

const testLines = allLogs.split("\n")
    .map(l => l.trim())
    .filter(l => l.startsWith("test ") && (l.endsWith("... ok") || l.endsWith("... FAILED") || l.endsWith("... ignored")));

console.log(`Extracted ${testLines.length} total test execution lines across logs.`);

const vectorKeywords = [
    "kat", "vector", "deserialization", "key_schedule", "message_protection", 
    "passive_client", "psk", "secret_tree", "storage_stability", "transcript_hashes", 
    "tree_math", "tree_operations", "tree_validation", "treekem", "welcome"
];

const mappedTests = testLines.filter(line => vectorKeywords.some(kw => line.toLowerCase().includes(kw)));
console.log(`Found ${mappedTests.length} vector-related test lines.`);

mappedTests.forEach(t => console.log(t));
