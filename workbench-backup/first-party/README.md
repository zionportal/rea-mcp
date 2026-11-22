# Reverse engineering workspace

This folder contains David's `zionportal/rea-mcp` source checkout, a separate local REA runtime, and isolated Android analysis tools. REA's npm runtime is a published package; its bytes have not been established as identical to the Git checkout.

## Contents

- `rea-mcp/`: GitHub source checkout. Origin: https://github.com/zionportal/rea-mcp
- `runtime-packed/`: integrity-checked published `rea-agents` 6.9.0 distribution, extracted locally with its bundled dependencies.
- `runtime/`: incomplete npm installation retained after its cleanup was blocked; it is not used by the launcher.
- `jdk/`: Eclipse Temurin JDK 21, including the Java compiler.
- `jadx/`: standalone JADX 1.5.7 command-line and GUI distribution.
- `downloads/jadx-headless-mcp-0.7.1-all.jar`: REA's separately specified Android engine. Its SHA-256 was checked against the pinned digest in REA's `src/android/JadxRelease.ts`.
- `node-v24.22.3-win-x64/`: portable Node.js, required because the machine-wide Node version was below REA's declared minimum.
- `rea.cmd`: local launcher which sets `JAVA_HOME`, `REA_JADX_MCP_JAR`, and the process PATH only for that invocation.
- `httrack/` and `httrack.cmd`: portable HTTrack/WinHTTrack 3.51-0. `httrack\httrack\WinHTTrack.exe` opens its graphical interface.
- `playwright/` and `playwright.cmd`: Playwright 1.65.1 and its local Chromium browser, with the browser path scoped to the launcher or test process.
- `assetripper/AssetRipper.GUI.Free.exe`: AssetRipper 2.0.0 for Unity assets; normal launch opens its browser-based interface.
- `godot-re-tools/gdre_tools.exe`: Godot RE Tools 2.7.4 for Godot project and script recovery.
- `fmodel/FModel.exe`: FModel release `nov-2026` (executable version 4.4.4.0), an Unreal Engine archive and asset explorer. The installed Windows Desktop .NET 10 runtime satisfied its stated prerequisite at setup time.
- `x64dbg/release/x64/x64dbg.exe`: x64dbg snapshot 2026.05.27, the 64-bit Windows debugger. The 32-bit version is under `release/x32/`; the headless executable is under `release/x64/`.
- `renderdoc/RenderDoc_1.47_64/qrenderdoc.exe`: RenderDoc 1.47, a graphics debugger intended by its maintainers for debugging the developer's own programs. `renderdoccmd.exe` is its CLI.
- `uefi-tools/UEFITool.exe` and `uefi-tools/UEFIExtract.exe`: UEFITool and UEFIExtract NE A76 for UEFI firmware image inspection and extraction.
- `qemu/`: portable extraction of the publisher's Windows QEMU 11.1.0 development build. The system installer was not executed. For example, `qemu\qemu-system-arm.exe` and `qemu\qemu-system-x86_64.exe` report their versions.
- `7zip/`: local 7-Zip 26.06 used to extract the QEMU installer without system installation. `7zip-extra/` contains the verified standalone archive package used to extract 7-Zip.
- `emba-source/`: EMBA source checkout only, commit `b22a1d6a42d66d86969b6a2fdf6d1bd8e22dd1eb`. It is not installed or ready to analyze firmware: the recommended setup needs Docker and an approximately 20 GB container image. Docker was not found on Windows or the existing Ubuntu WSL distribution on 2026-11-21; review available disk and machine resources before setup.
- `sources/`: 15 separate shallow public source checkouts, with origins and commits recorded in `sources/README.md`. These are reference checkouts, not merged into REA; submodules and Git LFS objects were not fetched, and the snapshots were not verified against installed release binaries.
- `imhex/imhex-gui.exe`: ImHex 1.38.1, a visual binary and hex editor.
- `dnspyex/dnSpy.exe`: dnSpyEx 6.6.0, a .NET assembly debugger and editor; `dnSpy.Console.exe` provides command-line decompilation.
- `process-monitor/Procmon64.exe`: Microsoft Process Monitor 4.13, a live Windows file, registry, and process monitor.
- `detect-it-easy/die.exe`: Detect It Easy 4.0.0 file identification GUI; `diec.exe` is its command-line scanner.
- `resource-hacker/ResourceHacker.exe`: Resource Hacker 5.2.8, a Windows executable resource editor.
- `dependencies/DependenciesGui.exe`: Dependencies v1.11.1 release, a Windows DLL dependency viewer; `Dependencies.exe` is its command-line tool. The executable's file-version metadata reads 1.10.0.0 despite the release tag.

## Use

In PowerShell, from this folder:

```powershell
.\rea.cmd --help
.\rea.cmd doctor --provider jadx --json
.\rea.cmd mcp
.\httrack.cmd --version
.\playwright.cmd --version
```

The MCP command communicates over standard input/output and is intended to be started by an MCP client. The launcher does not by itself register REA with Codex or any other client. Registration and agent restart are separate; consult REA's setup documentation and review its changes before applying them.

The added game and desktop tools are standalone applications in this workspace. They have not been registered as REA tools or integrated into its MCP server.

`MCP-INTEGRATION-PROPOSAL.md` records the 2026-11-21 plan to extend REA's MCP, the proposed first provider and its boundaries, and the outstanding maintainer scope decision. It is a proposal, not an implemented integration.

## Verification — 2026-11-21

- `rea.cmd --version` returned 6.9.0; `doctor --provider jadx --json` reported the selected Android provider healthy.
- `verify-mcp.mjs` initialized the local MCP server, listed 255 tools, and found `inspect_android_package`.
- A read-only inspection of the existing Ava Mobile debug APK completed with the JADX headless provider and detected its expected package name. This is a technical test only, not a security-camera app.
- Standalone JADX reported 1.5.7, the JDK reported 21.0.13.1 and exposed `jdk.compiler`, and Node reported 24.22.3.
- An initial npm installation was stopped after a prolonged unpack; the successful runtime came from the npm registry tarball after its SHA-512 integrity check. An attempt to remove the incomplete `runtime/` directory was rejected by the execution policy, so it was left in place.
- HTTrack's executable had a valid Authenticode signature and reported 3.51-0; `verify-web-tools.cjs` verified that it mirrored two linked pages served from localhost.
- Playwright 1.65.1 launched its locally installed Chromium headless and rendered JavaScript on the local fixture. Both tools can be retested using `node-v24.22.3-win-x64\node.exe verify-web-tools.cjs`; the test leaves a small `web-tool-check-*` fixture directory.
- The AssetRipper, Godot RE Tools, FModel and x64dbg release ZIPs came from their official GitHub releases and matched the SHA-256 digests reported by GitHub. RenderDoc came from its official Windows portable download, and its GUI executable had a valid Windows signature.
- AssetRipper returned its version/help; Godot RE Tools compiled and decompiled a small local GDScript fixture (`verify-godot.cjs`); x64dbg's headless debugger initialized and returned help; RenderDoc's CLI returned version 1.47. FModel started with a main window using the already installed .NET 10 Windows Desktop runtime. No game, CAD application or customer asset was inspected; application-specific behavior and full interactive workflows remain untested.
- UEFITool and UEFIExtract were downloaded from the official GitHub A76 release and matched its published SHA-256 digests; UEFIExtract returned its help and version successfully. No firmware image has been analyzed with them.
- The Windows QEMU archive was extracted from a publisher-checksummed installer without running the installer. Its x86-64 and ARM binaries both reported version 11.1.0; `qemu-img` created and read a tiny local QCOW2 fixture. Booting firmware is untested. Official 7-Zip release packages matched their published digests.
- ImHex, dnSpyEx and Detect It Easy were downloaded from official GitHub releases and matched the publisher-provided SHA-256 digests. Dependencies, Process Monitor and Resource Hacker were obtained from their publishers; the Dependencies release did not provide a digest, and no publisher digest was available for the two direct ZIPs. The Process Monitor executable had a valid Microsoft signature. Resource Hacker and Dependencies executables were unsigned; their locally calculated archive hashes are recorded in the operation catalog, not represented as independently verified publisher hashes.
- ImHex started and presented a main window. `verify-new-tools.cjs` verified that Dependencies identified imports from the local 7-Zip executable and dnSpyEx decompiled a local managed assembly into C# files. Detect It Easy identified the local 7-Zip executable as PE64. Process Monitor has not been started: its driver, elevation, or first-use agreement may require user interaction. Resource Hacker was downloaded and inspected but has not been started or tested interactively. No user application was monitored or changed.

## Candidates for later

Tool-selection rule: compare candidates with REA's actual catalog and provider integrations first. David wants additions that expand its capabilities; do not present an REA-supported tool or provider as a new capability. A supported provider may still require separate installation or configuration.

REA already documents Unity IL2CPP metadata, Godot PCK inspection/extraction, .NET inspection and FreeCAD-specific document handling; compare concrete workflows before adding more tools. The standalone tools above were selected to cover additional workflows and are not yet integrated with REA.

HTTrack is for offline mirrors and does not recover a server's application code or guarantee a working copy of JavaScript-heavy sites. Playwright assists browser inspection and testing; it does not automatically recreate a site's backend.

To start standalone JADX with the included JDK in the current PowerShell session:

```powershell
$env:JAVA_HOME = Join-Path (Get-Location) 'jdk'
& '.\jadx\bin\jadx-gui.bat'
```

These tools analyze supplied files; installation does not establish access to a camera, phone, APK, account, or service.
