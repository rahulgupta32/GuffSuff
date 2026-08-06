import { spawnSync } from "child_process";
import fs from "fs";
import path from "path";
import os from "os";

const outDir = path.resolve("spikes/crypto-eval/results/mobile-readiness");
fs.mkdirSync(outDir, { recursive: true });

const cargoBin = path.join(os.homedir(), ".cargo", "bin");
const env = { ...process.env, PATH: `${cargoBin};${process.env.PATH}` };

function checkCommand(cmd, args) {
    const res = spawnSync(cmd, args, { env, encoding: "utf-8" });
    if (res.status === 0) {
        return {
            status: "PASSED",
            version: (res.stdout || res.stderr || "").trim().split("\n")[0],
            path: cmd
        };
    }
    return {
        status: "NOT INSTALLED",
        version: null,
        path: null,
        blockingReason: `Command '${cmd}' not found in PATH or returned non-zero exit code`
    };
}

const toolchains = [
    { component: "Rust compiler (stable)", target: "x86_64-pc-windows-msvc", host: "Windows x86_64", ...checkCommand("rustc", ["--version"]) },
    { component: "Cargo package manager", target: "x86_64-pc-windows-msvc", host: "Windows x86_64", ...checkCommand("cargo", ["--version"]) },
    { component: "Rustup toolchain manager", target: "x86_64-pc-windows-msvc", host: "Windows x86_64", ...checkCommand("rustup", ["--version"]) },
    { component: "Cargo Deny security auditor", target: "x86_64-pc-windows-msvc", host: "Windows x86_64", ...checkCommand("cargo-deny", ["--version"]) },
    { component: "Miri memory interpreter", target: "x86_64-pc-windows-msvc (nightly)", host: "Windows x86_64", ...checkCommand("cargo", ["+nightly", "miri", "--version"]) },
    { component: "JDK / Java compiler", target: "JVM / Android Host", host: "Windows x86_64", ...checkCommand("javac", ["-version"]) },
    { component: "Android SDK", target: "aarch64-linux-android, x86_64-linux-android", host: "Windows x86_64", ...checkCommand("sdkmanager", ["--version"]) },
    { component: "Android NDK", target: "aarch64-linux-android", host: "Windows x86_64", ...checkCommand("ndk-build", ["--version"]) },
    { component: "Android ADB", target: "Android Device / Emulator", host: "Windows x86_64", ...checkCommand("adb", ["version"]) },
    { component: "Android Emulator", target: "Android Virtual Device", host: "Windows x86_64", ...checkCommand("emulator", ["-version"]) },
    { component: "Flutter SDK", target: "Android / iOS / Windows", host: "Windows x86_64", ...checkCommand("flutter", ["--version"]) },
    { component: "Dart SDK", target: "Dart VM", host: "Windows x86_64", ...checkCommand("dart", ["--version"]) },
    { component: "iOS Cross-compilation (Xcode)", target: "aarch64-apple-ios", host: "macOS required (Host: Windows)", status: "BLOCKED", version: null, path: null, blockingReason: "Apple Xcode toolchain unavailable on Windows host" },
    { component: "CMake / Native Build", target: "C/C++ Native Libraries", host: "Windows x86_64", ...checkCommand("cmake", ["--version"]) },
    { component: "Ninja Build System", target: "C/C++ Native Build", host: "Windows x86_64", ...checkCommand("ninja", ["--version"]) }
];

fs.writeFileSync(path.join(outDir, "toolchain-status.json"), JSON.stringify(toolchains, null, 2));
console.log("Successfully generated toolchain-status.json!");
