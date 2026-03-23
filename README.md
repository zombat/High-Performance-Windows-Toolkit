# High-Performance Windows Toolkit 🚀

A vendor-agnostic PowerShell suite designed to eliminate **DPC Latency**, unlock hidden **Power Plans**, enable **Server-Grade I/O**, and neutralize **OEM Bloatware**.

Ideally suited for **Developers (Docker/WSL)**, **Gamers**, and **Power Users** running heavy workloads on pre-built PCs (Dell, HP, ASUS, MSI, Razer).

---

## ⚠️ CRITICAL DISCLAIMER & LIABILITY WAIVER

**READ THIS BEFORE RUNNING ANY SCRIPTS.**

By downloading and executing these scripts, you acknowledge and agree to the following:

1.  **NO WARRANTY:** This software is provided "AS IS", without warranty of any kind, express or implied.
2.  **USER RESPONSIBILITY:** You are solely responsible for any damage to your computer hardware, software, data, or business operations.
3.  **POTENTIAL RISKS:** These scripts modify deep system configurations (Registry, Power Plans, Driver Interrupts). While tested on standard hardware, edge cases exist.
    * **Data Loss:** Always backup your critical data before running system tools.
    * **Boot Failures:** Using the "MSI Mode Enabler" on incompatible hardware can cause boot loops (Blue Screens).
4.  **INDEMNIFICATION:** The author is **NOT** liable for any direct, indirect, incidental, or consequential damages resulting from the use or misuse of this toolkit.

**IF YOU DO NOT AGREE TO THESE TERMS, DO NOT USE THIS SOFTWARE.**

---

## 🎯 The Problem
Modern Windows configuration is tuned for battery life and "Snap functionality," not raw throughput. This kills performance for professionals:
1.  **Micro-Stutters:** Aggressive USB/PCIe sleep states causing hardware lag.
2.  **Legacy I/O:** Windows 11 using old SCSI translation for NVMe drives.
3.  **RAM Starvation:** "Desktop Mode" memory management aggressively paging out Docker/WSL.
4.  **IRQ Conflicts:** High DPC latency caused by devices fighting for CPU interrupts.

## 🛠️ The Solution
17 standalone scripts to audit, repair, and optimize the Windows kernel configuration.

### The Essentials
#### `1_PowerLatencyFix.ps1` (The "Un-Stutter" Patch)
* **Unlocks:** The hidden **"Ultimate Performance"** power plan.
* **Optimizes:** Forces "Always On" (0) latency states for all PCIe/USB buses.
* **Fixes:** Disables "Selective Suspend" on every individual USB hub.
* **Potential Issues:**
  * May increase idle power consumption if "Always On" states are not supported by older chipsets.
  * USB devices may draw more power even during sleep; not ideal for laptops on battery.
  * Incompatible with certain external USB hubs (rare).

#### `2_NetworkBooster.ps1` (The Wi-Fi Fix)
* **Targets:** Intel, Killer, Realtek, and MediaTek adapters.
* **Optimizes:** Forces **"Prefer 5GHz"** to stop 2.4GHz fallback.
* **Stabilizes:** Sets **"Roaming Aggressiveness"** to Lowest.
* **Potential Issues:**
  * Forcing 5GHz on older routers may reduce range and cause disconnections.
  * Disabling roaming aggressiveness can cause lag when moving between access points.
  * Only effective if your adapter/router supports 5GHz; 2.4GHz-only hardware unaffected.

#### `3_BloatwareNeutralizer.ps1` (The De-Bloater)
* **Neutralizes:** Disables known latency-spiking services from major vendors.
* **Targets:** Dell (SupportAssist, Killer), HP, ASUS (Armoury Crate), MSI, Razer, Corsair.
* **Potential Issues:**
  * Disabling vendor services may break BIOS/firmware update utilities.
  * OEM keyboard macros, RGB lighting, or fan control may stop working.
  * Warranty support teams may blame disabled services for unrelated hardware issues.

#### `4_SystemHealthAudit.ps1` (The Inspector)
* **Scans:** Detects "Ghost" devices and failed hardware resets.
* **Audits:** Flags critical drivers (GPU, Chipset, Network) that are >3 years old.
* **Potential Issues:**
  * Read-only; does not fix issues automatically (manual driver updates required).
  * Old driver detection is time-based; may flag stable legacy drivers that are still functional.
  * Some enterprise/OEM drivers intentionally use older versions for stability.

### The "Deep Cuts" (Advanced Tuning)

#### Storage Diagnostics & PCIe Health 🔬

#### `5.0_NVMePCIeLaneChecker.ps1` (The NVMe PCIe Inspector)
* **Function:** Queries the Windows PnP manager to display the current and maximum PCIe lane width and generation for each connected NVMe controller.
* **Benefit:** Identifies bottlenecked SSDs running at fewer lanes or a lower PCIe generation than their hardware supports.
* **Safety:** Read-only. Makes no system changes.
* **Potential Issues:**
  * Returns no data if drives are running under Intel RST / RAID mode — run `5.1_RAIDtoAHCISwitch.ps1` first.
  * Some chipset-connected M.2 slots are architecturally limited (e.g. x2 only); a bottleneck may not be fixable without physically relocating the drive to a CPU-direct slot.

#### `5.1_RAIDtoAHCISwitch.ps1` (The Safe AHCI Migration Guide) ⚠️
* **Function:** Detects Intel RST / RAID mode and prints the exact step-by-step `bcdedit` + BIOS + Safe Mode procedure to switch to AHCI without a blue screen.
* **Benefit:** Restores raw PCIe visibility for NVMe diagnostics. AHCI mode also allows manufacturer SSD health tools to read drives directly.
* **Guidance Only:** This script prints instructions. **No commands are executed automatically.** You perform each step yourself.
* **Potential Issues:**
  * **Critical: Skipping the Safe Mode boot WILL cause an `INACCESSIBLE_BOOT_DEVICE` blue screen.** All five steps must be followed in order.
  * Back up critical data and have a Windows recovery USB ready before starting.
  * Intel RST RAID arrays used for actual striping or mirroring must be dissolved before switching — this will destroy the RAID volume data.
  * After the switch, WSL distributions or Docker Desktop may lose their volume paths — run `5.4_WSLDockerRecovery.ps1` if so.

#### `5.2_NVMeBooster.ps1` (The Server Storage Stack) ⚡
* **Unlocks:** Enables the **"Native NVMe"** driver stack ported from **Windows Server 2025**.
* **Benefit:** Bypasses legacy SCSI translation for ~20% higher IOPS.
* **Warning:** May break proprietary dashboard tools (Samsung Magician). Use with caution.
* **Potential Issues:**
  * **Critical:** May not boot on systems with striped/RAID NVMe configurations.
  * Proprietary NVMe health monitoring tools (Samsung, Intel, WD) may not work.
  * Rollback requires manual registry edits or System Restore.
  * Some enterprise SSDs may use undocumented firmware features incompatible with native stack.

#### `5.3_GPUPCIeLaneChecker.ps1` (The GPU PCIe Inspector)
* **Function:** Queries the Windows PnP manager to display the current and maximum PCIe lane width and generation for each connected display adapter.
* **Benefit:** Confirms your GPU is operating at the expected x16 lane configuration and PCIe generation.
* **Safety:** Read-only. Makes no system changes.
* **Potential Issues:**
  * Modern GPUs aggressively downclock their PCIe generation at idle to save power — **run under GPU load** (gaming, rendering, or a benchmark) for accurate maximum-speed readings.
  * Some integrated or display-only adapters do not expose PCIe properties through the PnP manager.

#### `5.4_WSLDockerRecovery.ps1` (The WSL/Docker Rescue Tool) 🛟
* **Function:** Recovers WSL distributions and Docker Desktop after a storage controller change invalidates volume identifiers and breaks `BasePath` registry entries.
* **Strategy:** Two-phase heuristic search — fast breadcrumb check of common paths (Phase 1), falling back to a full recursive drive scan for orphaned `ext4.vhdx` files (Phase 2).
* **Safety:** Per-distro confirmation prompt before any registry write. Recommends a `reg export` backup before proceeding.
* **Potential Issues:**
  * Modifies `HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss`. **Export a backup first:** `reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Lxss" wsl-backup.reg`
  * Phase 2 deep search can be slow on large drives with many files.
  * If a distro's `ext4.vhdx` is genuinely missing (deleted, not just remapped), the script cannot recover it — a `wsl --import` from a backup `.tar` is required.
  * Docker Desktop's data disk matching uses directory name heuristics; non-standard installation paths may require manual registry editing.

#### Memory, I/O & Search Optimization 🧠

#### `5.5_SuperFetchOptimization.ps1` (The Prefetch Tuner)
* **Function:** Detects installed RAM and physical disk types (HDD/SSD), then recommends and applies the optimal SysMain/Prefetch mode.
* **Benefit:** Switches HDD + high-RAM systems to "Boot Only" (Mode 2) to stop background disk thrashing; leaves SSD-primary systems on full caching (Mode 3).
* **Interactive:** Prompts for confirmation before applying any change and restarting the SysMain service.
* **Potential Issues:**
  * Changing the prefetch mode may slightly increase cold-start app load times on HDD systems (trade-off for eliminating background thrashing).
  * Writes both `EnableSuperfetch` and `EnablePrefetcher` keys for consistency; a future Windows update could reset these.

#### `5.6_PageFileOptimizer.ps1` (The Pagefile Fixer)
* **Function:** Analyzes RAM and disk types, then replaces the default "System Managed" pagefile with a strict 2048MB/4096MB lock on the fastest available SSD.
* **Benefit:** Eliminates pagefile placement on mechanical drives and the unpredictable size growth of system-managed configs.
* **Cleanup:** Scans all fixed drives for orphaned `pagefile.sys` files on non-target drives and schedules a self-removing SYSTEM-level task to delete them on next reboot.
* **Requires Reboot:** The Windows kernel must release old pagefile locks before the new configuration takes effect.
* **Potential Issues:**
  * A reboot is mandatory; changes are not live until after restart.
  * On systems with less than 8GB RAM, a 2GB–4GB fixed pagefile may be insufficient for crash dumps or memory-heavy workloads.
  * The cleanup task runs as `NT AUTHORITY\SYSTEM` at startup and unregisters itself after running.

#### `5.7_WindowsIndexOptimize.ps1` (The Search Indexer Auditor)
* **Function:** Checks the Windows Search service status, flags an oversized `Windows.edb` database (>2GB), and audits which volumes have indexing enabled.
* **Benefit:** Identifies and optionally disables indexing on mechanical HDDs, eliminating the constant background I/O thrashing that degrades performance on mixed HDD/SSD systems.
* **Interactive:** Prompts before disabling indexing on any drive; restarts the WSearch service to release file handles after applying changes.
* **Potential Issues:**
  * Disabling indexing on an HDD means Windows Search results for files on that drive will become slower or incomplete.
  * The UI in Drive Properties may lag behind the actual change for a few seconds.
  * Does not rebuild or compact the `Windows.edb` database — use "Indexing Options" in Control Panel to do that manually if flagged as bloated.

#### `6_MemoryTweak.ps1` (The Server RAM Tuner) 🧠
* **Function:** Switches memory management from "Desktop Mode" to "Server Mode" (Large System Cache).
* **Benefit:** Prioritizes file caching for Docker/WSL layers and compiling.
* **Safety:** Auto-blocks execution on systems with < 16GB RAM.
* **Potential Issues:**
  * Desktop applications may experience unfamiliar memory behavior (less responsive to low-RAM conditions).
  * Real-time applications (audio/video) may have unexpected latency spikes during cache churn.
  * Rollback requires a full system restart and registry edit.
  * On systems with exactly 16GB RAM, may leave insufficient memory for large VMs/containers.

#### `8_MSIModeEnabler.ps1` (The Latency Holy Grail) 🛡️
* **Function:** Forces supported hardware (GPU, NIC, NVMe) to use **Message Signaled Interrupts (MSI)** instead of legacy IRQ lines.
* **Benefit:** Eliminates IRQ conflicts and micro-stutters.
* **Safety:** **Auto-creates a System Restore Point** before making changes.
* **Potential Issues:**
  * **Boot Risk:** Incompatible devices (rare but possible) can cause boot loops/BSOD; requires Safe Mode recovery.
  * Some very old USB devices or legacy peripherals may not support MSI.
  * Troubleshooting is difficult if something breaks; may require Device Manager registry rollback.
  * Not all devices report MSI support correctly; some may hang if forced.

### Maintenance & Cleanup
#### `7_TweakUI.ps1` (The Visual Performance Tuner)
* **Function:** Disables window and taskbar animations while explicitly preserving ClearType font smoothing, thumbnails, and icon shadows.
* **Benefit:** Eliminates animation overhead for a snappier UI without the "Windows 95" look of the "Best Performance" preset (which also kills font smoothing).
* **Interactive:** Prompts to restart Explorer immediately to apply changes.
* **Potential Issues:**
  * Requires Explorer restart to take effect; any open File Explorer windows will briefly close and reopen.
  * User-level change only (`HKCU`); does not affect other user accounts on the same machine.

#### `9_WindowsDebloater.ps1` (The Surgical Cleaner) 🧹
* **Function:** Interactive removal of unwanted apps and features.
* **Features:** Disables Copilot, Telemetry, and Bing Search. Removes bloatware (Candy Crush, etc.) but **protects** Developer Tools (WSL, Terminal, Winget).
* **Potential Issues:**
  * Removing Windows apps may break updates or Store functionality if done too aggressively.
  * Disabling telemetry can affect Windows Defender threat intelligence updates.
  * Some removed apps cannot be reinstalled without a clean Windows install.
  * Interactive mode requires user attention; cannot be fully automated.

#### `10_StartupKiller.ps1` (The Boot Booster) 🚀
* **Function:** Scans Registry and Startup Folders for auto-starting apps.
* **Interactive:** Asks you "Kill or Keep?" for every single entry.
* **Potential Issues:**
  * Manual confirmation required for every entry; very time-consuming on bloated systems.
  * May accidentally disable system services if user is unfamiliar with process names.
  * Some background services (OneDrive, Defender, Network Discovery) may re-enable themselves on Windows Update.
  * Disabling all startup items may break legitimate OEM functionality (e.g., ROG lighting, Alienware Command Center).

---

## 🚀 Usage Guide

### Tiered Approach

**Scripts 1–4 (Recommended for Most Users)** 🟢
These scripts address fundamental latency issues with minimal risk:
- `1_PowerLatencyFix.ps1` — Safe; no data loss or boot risk.
- `2_NetworkBooster.ps1` — Safe; Wi-Fi quality may vary by hardware.
- `3_BloatwareNeutralizer.ps1` — Generally safe; may break OEM-specific features.
- `4_SystemHealthAudit.ps1` — Read-only audit; no risk.

**Scripts 5.0–5.7, 6, 8 (Advanced Users Only)** 🟡
These require understanding the tradeoffs; test in non-critical environments first:
- `5.0_NVMePCIeLaneChecker.ps1` — Read-only; safe.
- `5.1_RAIDtoAHCISwitch.ps1` — Guidance only; **follow all steps precisely** — skipping the Safe Mode boot causes BSOD.
- `5.2_NVMeBooster.ps1` — May break RAID setups; requires rollback knowledge.
- `5.3_GPUPCIeLaneChecker.ps1` — Read-only; safe.
- `5.4_WSLDockerRecovery.ps1` — Modifies WSL registry under per-distro confirmation; export `reg export` backup first.
- `5.5_SuperFetchOptimization.ps1` — Interactive; low risk. Recommended for HDD + high-RAM systems.
- `5.6_PageFileOptimizer.ps1` — Requires reboot; changes pagefile placement and size.
- `5.7_WindowsIndexOptimize.ps1` — Interactive; low risk. Recommended for mixed HDD/SSD systems.
- `6_MemoryTweak.ps1` — Changes RAM behavior; can affect application performance.
- `8_MSIModeEnabler.ps1` — Creates restore point first, but boot risk exists on incompatible hardware.

**Scripts 7, 9–10 (Situational)** 🟠
Safe but interactive; requires user judgment:
- `7_TweakUI.ps1` — Safe; user-level visual settings. Requires Explorer restart.
- `9_WindowsDebloater.ps1` — Requires confirmation for each removal.
- `10_StartupKiller.ps1` — Requires confirmation for each startup item.

---

**Note:** You may need to enable script execution first:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

Open **PowerShell as Administrator**:

```powershell
# Safe baseline (Recommended for most users)
.\1_PowerLatencyFix.ps1
.\2_NetworkBooster.ps1
.\3_BloatwareNeutralizer.ps1
.\4_SystemHealthAudit.ps1

# Advanced (Only if you understand the tradeoffs)
.\5.0_NVMePCIeLaneChecker.ps1  # Optional: Check NVMe PCIe lane configuration
.\5.1_RAIDtoAHCISwitch.ps1     # Optional: Safe RAID->AHCI guide (run before 5.2 if on Intel RST)
.\5.2_NVMeBooster.ps1          # Optional: Server-grade NVMe stack
.\5.3_GPUPCIeLaneChecker.ps1   # Optional: Check GPU PCIe lane configuration
# .\5.4_WSLDockerRecovery.ps1  # Recovery only: Run if WSL/Docker breaks after AHCI switch
.\5.5_SuperFetchOptimization.ps1  # Optional: Tune SysMain for your disk/RAM config
.\5.6_PageFileOptimizer.ps1       # Optional: Lock pagefile to SSD, remove HDD orphans
.\5.7_WindowsIndexOptimize.ps1    # Optional: Stop Search from thrashing mechanical drives
.\6_MemoryTweak.ps1               # Optional: Server-mode RAM tuning (16GB+ only)
.\8_MSIModeEnabler.ps1            # Optional: Fix DPC latency (creates restore point)

# Maintenance (Interactive; requires confirmation)
.\7_TweakUI.ps1
.\9_WindowsDebloater.ps1
.\10_StartupKiller.ps1
```

---

## ❓ FAQ

**Q: Can I run all scripts at once?**
A: No. Run 1–4 first, test stability for a week, then consider the advanced scripts. Always create a System Restore Point before running advanced scripts.

**Q: What if something breaks?**
A: Scripts 5–8 are designed to be rollback-friendly (via System Restore or registry edits). Script 1 can be reverted by switching back to "Balanced" power plan. Script 3 can be reverted by re-enabling services. See individual script comments for rollback instructions.

**Q: Is this safe for production systems?**
A: No. This toolkit is for personal machines and dev environments only. Do not use on servers, shared systems, or machines accessing production infrastructure.

**Q: Do I need to run 5.5, 5.6, and 5.7 if I only have SSDs?**
A: These scripts are most impactful on systems with mechanical HDDs. On all-SSD machines, 5.5 and 5.7 will likely report the configuration is already optimal, and 5.6 is still useful for enforcing a fixed pagefile size and removing orphaned pagefile copies after a drive migration.
