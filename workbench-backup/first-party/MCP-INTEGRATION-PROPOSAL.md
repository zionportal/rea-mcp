# Engineering workbench: REA integration proposal

Status: **proposal, not an implemented or approved integration**. Prepared 2026-11-21 for the public `zionportal/rea-mcp` repository. Repository default-branch head observed: `6136c6f3babd5cf2ada552341003829d41a06f71`.

## Goal

Make the locally assembled engineering tools available to an MCP client through a portable, documented interface, while retaining REA's existing evidence conventions and preserving the standalone tools' own interfaces. David selected extending the existing REA MCP server on 2026-11-21.

## Current verified state

- REA 6.9.0 has a functioning local MCP server. The workspace test initialized it and found 255 tools. It has not been registered with this Codex client.
- The added desktop, game, website and firmware programs are standalone, not REA MCP providers. Their individual readiness and prior tests are recorded in `README.md` in this directory.
- Fifteen additional public source repositories were subsequently checked out under `sources/` as shallow default-branch snapshots. See `sources/README.md` for origins and commits. They are separate from REA; submodules/LFS objects were not fetched, and versions are not verified to match the installed binaries.
- EMBA is a source checkout only; Docker and the container image are not installed. Its analysis is not available from the staged source alone.
- The GitHub repository is public. Its own `CONTRIBUTING.md` forbids integration of certain bypass/attack features and requires an explicit maintainer scope decision for new providers and capabilities involving execution, injection, mutation or protection recovery.

## Proposed distribution

Commit first-party integration code, contracts, tests, documentation and non-sensitive fixtures. Do **not** commit the downloaded third-party applications, JDK, local runtime, camera data, results, keys or locally generated captures. Discover user-supplied installations by explicit paths and report version and availability; leave each tool's licensing and installation process with its publisher. This is necessary for portability and because the locally supplied Process Monitor license prohibits publishing the software for others to copy, and Resource Hacker's license restricts redistribution.

## Suggested first provider: static file identification

Use the existing local Detect It Easy command-line tool as an optional provider for a caller-selected local file. Provide one bounded MCP operation that validates the target and executable, launches only the specifically configured scanner, returns structured findings with engine identity, source path, limits and explicit errors, and does not modify the target. Do not expose arbitrary command execution, updater operations or implicit target discovery. Keep raw detector output bounded and retain/identify any incomplete coverage.

Evidence required before proposing integration: a known PE fixture, an unrecognized input, missing/wrong engine path, malformed engine output, output limit, timeout, cancellation and child cleanup; compare source bytes before/after. Exercise the same contract through the CLI and MCP if the repository's architecture requires both. A provider-specific `doctor` check must distinguish installation/configuration from actual target analysis.

This is a proposal for a maintainer scope decision, not a completed implementation or approval. REA's existing generic format inspection must be compared with this provider's concrete extra findings before code is added.

## Subsequent work requiring separate behavior decisions

| Area | Possible capabilities | Scope and validation needed |
| --- | --- | --- |
| Godot and Unity | Recover selected scripts or assets into a caller-selected output directory. | May create or overwrite files; format/version coverage, archive paths, limits and source preservation need review. |
| Unreal | Inspect or export supported assets. | The installed FModel is a GUI; do not promise MCP automation without a documented, testable interface. |
| Websites | Mirror user-selected sites or inspect pages in a browser. | Network access, authentication, external domains, output and duration must be explicitly controlled. |
| Native and managed code | Read metadata or decompile; optionally debug or edit with separately authorized workflows. | Static examination differs materially from launching, attaching, injecting or modifying a process. |
| Firmware and emulation | Inspect/extract images, optionally start controlled virtual machines. | Firmware parsing differs from executing images or writing physical devices; emulation, device writes and recovery require their own decisions. |
| Live system observation | Monitor file/process/registry activity for a selected process. | Driver, privilege, consent, filtering and cleanup requirements must be established; no background monitoring by default. |
| GUI-first tools | Document capabilities and verified manual workflows. | No invented headless API or automatic desktop control; investigate each tool's actual interfaces. |

## Decision requested

1. David selected extending REA's existing MCP server.
2. Approve or revise the precise first provider and its limits above. Treat later write, browser/network, debugger, emulation and device actions as separate scoped decisions.
3. Record the required maintainer scope decision in a linked issue or design discussion before integration, per the repository's `AGENTS.md` and `CONTRIBUTING.md`.

Do not publish a package or describe all installed tools as MCP-enabled until individual adapters are implemented, checked, and actually exposed by the connected server.
