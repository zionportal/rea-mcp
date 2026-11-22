# Engineering workbench recovery kit

This is a **recovery recipe and backup of first-party setup files**, not an archive of the installed third-party applications. It records 22 package checksums, 15 source checkout revisions, an EMBA source revision, launcher scripts and the Playwright lockfile from the 2026-11-21 Windows x64 workbench.

The repository does not contain the third-party downloads, Playwright browser, source checkouts, personal files, workbench runtime outputs, or the complete local backup. Some vendors do not permit republishing their binaries. A separate, appropriately authorized local cache is required for those files to be restored without downloading them again. The pinned source snapshots are not verified to match the installed release binaries; submodules and Git LFS objects were not included in those checkouts.

## Restore to a new Windows x64 folder

Open PowerShell in this directory. The destination must not already exist and its parent must exist. This command downloads the pinned packages from their listed publishers, checks size and SHA-256, and extracts them into that new folder:

```powershell
.\Restore-Workbench.ps1 -Destination 'D:\EngineeringWorkbench' -AllowDownload -IncludeSources -InstallPlaywright
```

This also requires Git in PATH. `-IncludeSources` fetches the recorded source commits as shallow detached checkouts without submodules or Git LFS objects; `-InstallPlaywright` installs the pinned npm packages and matching Chromium locally. Both switches require network access and `-AllowDownload`. Neither EMBA's Docker environment nor MCP client registration is installed by this script. FModel may require the .NET Windows Desktop runtime already on the new machine.

To use a local cache for archives, add `-CacheDirectory 'E:\workbench-archive-cache'`; missing archives are downloaded only with `-AllowDownload`. Remove `-IncludeSources -InstallPlaywright` for an archive-only restore without those components. The script never downloads unless `-AllowDownload` is supplied. An incomplete operation leaves its new destination in place for inspection and refuses to overwrite it on rerun.

`-Only` permits a limited cache/restore test by artifact filename. For example:

```powershell
.\Restore-Workbench.ps1 -Destination 'D:\RestoreTest' -CacheDirectory 'E:\workbench-archive-cache' -Only 'UEFIExtract_NE_A76_win64.zip'
```

The script writes `restore-receipt.json`. A successful artifact restore does not by itself verify every GUI, install EMBA, configure Codex, integrate the standalone tools with REA, or establish that a new device or image can be analyzed. See `first-party/README.md` for the original machine's dated checks, and run relevant tests on the new machine.

## Integrity and limitations

The manifest labels checksum provenance. For packages without a publisher-supplied checksum, the saved SHA-256 identifies the previously obtained archive but is not an independent publisher authenticity check. Publisher URLs can change or disappear; mismatched or missing downloads fail rather than silently changing versions. The current source list covers the source checkouts present when captured, not necessarily the matching source for every installed binary.

This recovery script restored all 22 saved archives from the existing local cache into a separate test directory. Restored REA reported version 6.9.0 and a healthy JADX provider; restored Godot RE Tools compiled and decompiled a test script. UEFI and 7-Zip extraction, a corrupt-cache rejection, and a source-checkout test covering three repositories also passed. A full clean-machine restore, all source checkouts, and the Playwright-download option have not yet been verified. A complete local workbench backup is separate and is not stored in this public repository.
