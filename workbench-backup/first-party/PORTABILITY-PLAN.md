# Workbench portability plan

Status: proposed 2026-11-21; no portable installer or repository package has been built or published.

## Objective

Create one maintainable setup that recreates the engineering workbench on a new Windows x64 machine, preserves exact versions and verification evidence, and makes offline recovery possible to the extent permitted by the relevant licenses and available backups.

## What belongs in the repository

- A machine-readable manifest: tool, version, upstream origin, download URL, size, expected digest, digest provenance, license, architecture, dependencies, install location and verification command. If a publisher provides no checksum, label our recorded digest as a local identity, not independent authenticity verification.
- First-party Windows bootstrap and verification scripts; launcher and MCP configuration templates; clear commands and troubleshooting. Use relative paths and process-scoped settings where possible.
- Exact source repository URLs and commit IDs, and explicit submodule/LFS requirements when a checkout is needed. Do not imply a source snapshot matches an installed release until verified.
- License notices and attribution needed for our own code and any materials we are permitted to distribute. Treat individual third-party licenses separately; do not commit their binaries by default.
- A restore receipt describing what succeeded, failed, needs a user action, and was verified. Exclude secrets, user/device identifiers, private captures, targets and credentials.

## What a fresh-machine setup would do

1. Check Windows architecture, free disk, required capabilities, pre-existing installations and whether the user selected online or offline setup. Report changes and missing prerequisites.
2. Restore pinned tools from an explicitly selected permitted local cache where available, or download from each publisher. Validate checksums or signatures where publishers provide them; fail visibly on mismatch.
3. Unpack into a user-selected workbench folder without overwriting unrelated files. Install no system-wide drivers, trust certificates, services, runtime registrations or clients without a separate explicit choice.
4. Configure local launchers and optional MCP client registration, then verify versions, imports, actual limited functionality and MCP availability. A REA client restart may be required.
5. Leave a clear, machine-local receipt with sources, versions and any omitted or unverified tools. Reruns should verify existing installations and resume partial work safely.

## Constraints and open work

- REA's existing server and downloaded standalone applications are currently separate; a portable installer would not itself provide MCP adapters. REA provider integration remains a separate implementation governed by its contribution-scope rules.
- The downloaded archives currently total about 1,031 MiB across 22 files. Individual JDK and QEMU downloads exceed GitHub's ordinary 100 MiB per-object limit. Extracted tools and source repositories require additional space; no full workspace-size measurement has been made.
- Process Monitor's included license prohibits publishing the software for others to copy. Resource Hacker's publisher says redistribution requires prior permission. Download from the publisher or use a permitted personal backup; do not commit these executables to the public REA repository.
- Check the license and redistribution conditions of every other component before including its binaries, source, modified code or notices in a distribution. A private repository does not automatically resolve these terms.
- Publisher URLs, APIs and releases can disappear or change. A manifest alone is not an offline backup; use separate durable storage for copies that can lawfully be retained and restored.
- Playwright's browser package, npm dependencies, REA's Android headless engine, Java/Node runtimes and .NET desktop prerequisites need explicit versioned handling. EMBA is source-only and needs a separately reviewed Linux/container environment.
- Test on a truly clean Windows machine or VM, without inheriting this computer's PATH, runtimes, caches or browser profiles. Verify real restore behavior and document what remains manual before calling the setup portable.
- Scope decisions are still needed for any MCP tools that execute targets, write files, access networks, attach to processes, or control devices.

## Decision still open

Confirm whether online restore from pinned publisher downloads is sufficient, or whether David also wants an offline recovery cache in separate private storage for components whose licenses permit it. The repository can index and drive either approach; it cannot itself safely redistribute every current binary.
