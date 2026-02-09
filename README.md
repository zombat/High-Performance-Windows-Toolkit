# High-Performance Windows Toolkit 🚀

A vendor-agnostic PowerShell suite designed to eliminate **DPC Latency**, unlock hidden **Power Plans**, enable **Server-Grade I/O**, and neutralize **OEM Bloatware**.

Ideally suited for **Developers (Docker/WSL)**, **Gamers**, and **Power Users** running heavy workloads on pre-built PCs (Dell, HP, ASUS, MSI, Razer).

---

## ⚠️ CRITICAL DISCLAIMER & LIABILITY WAIVER

**READ THIS BEFORE RUNNING ANY SCRIPTS.**

By downloading and executing these scripts, you acknowledge and agree to the following:

1.  **NO WARRANTY:** This software is provided "AS IS", without warranty of any kind, express or implied.
2.  **USER RESPONSIBILITY:** You are solely responsible for any damage to your computer hardware, software, data, or business operations.
3.  **POTENTIAL RISKS:** These scripts modify deep system configurations (Registry, Power Plans, Driver Interrupts). While tested on standard hardware, edge cases exists.
    * **Data Loss:** Always backup your critical data before running system tools.
    * **Boot Failures:** Using the "MSI Mode Enabler" on incompatible hardware can cause boot loops (Blue Screens).
    * **Security:** Disabling CPU Mitigations (`7_MitigationDisable.ps1`) significantly lowers your system's security posture.
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
10 standalone scripts to audit, repair, and optimize the Windows kernel configuration.

### The Essentials
#### `1_PowerLatencyFix.ps1` (The "Un-Stutter" Patch)
* **Unlocks:** The hidden **"Ultimate Performance"** power plan.
* **Optimizes:** Forces "Always On" (0) latency states for all PCIe/USB buses.
* **Fixes:** Disables "Selective Suspend" on every individual USB hub.

#### `2_NetworkBooster.ps1` (The Wi-Fi Fix)
* **Targets:** Intel, Killer, Realtek, and MediaTek adapters.
* **Optimizes:** Forces **"Prefer 5GHz"** to stop 2.4GHz fallback.
* **Stabilizes:** Sets **"Roaming Aggressiveness"** to Lowest.

#### `3_BloatwareNeutralizer.ps1` (The De-Bloater)
* **Neutralizes:** Disables known latency-spiking services from major vendors.
* **Targets:** Dell (SupportAssist, Killer), HP, ASUS (Armoury Crate), MSI, Razer, Corsair.

#### `4_SystemHealthAudit.ps1` (The Inspector)
* **Scans:** Detects "Ghost" devices and failed hardware resets.
* **Audits:** Flags critical drivers (GPU, Chipset, Network) that are >3 years old.

### The "Deep Cuts" (Advanced Tuning)
#### `5_NVMeBooster.ps1` (The Server Storage Stack) ⚡
* **Unlocks:** Enables the **"Native NVMe"** driver stack ported from **Windows Server 2025**.
* **Benefit:** Bypasses legacy SCSI translation for ~20% higher IOPS.
* **Warning:** May break proprietary dashboard tools (Samsung Magician). Use with caution.

#### `6_MemoryTweak.ps1` (The Server RAM Tuner) 🧠
* **Function:** Switches memory management from "Desktop Mode" to "Server Mode" (Large System Cache).
* **Benefit:** Prioritizes file caching for Docker/WSL layers and compiling.
* **Safety:** Auto-blocks execution on systems with < 16GB RAM.

#### `8_MSIModeEnabler.ps1` (The Latency Holy Grail) 🛡️
* **Function:** Forces supported hardware (GPU, NIC, NVMe) to use **Message Signaled Interrupts (MSI)** instead of legacy IRQ lines.
* **Benefit:** Eliminates IRQ conflicts and micro-stutters.
* **Safety:** **Auto-creates a System Restore Point** before making changes.

### Maintenance & Cleanup
#### `9_WindowsDebloater.ps1` (The Surgical Cleaner) 🧹
* **Function:** Interactive removal of unwanted apps and features.
* **Features:** Disables Copilot, Telemetry, and Bing Search. Removes bloatware (Candy Crush, etc.) but **protects** Developer Tools (WSL, Terminal, Winget).

#### `10_StartupKiller.ps1` (The Boot Booster) 🚀
* **Function:** Scans Registry and Startup Folders for auto-starting apps.
* **Interactive:** Asks you "Kill or Keep?" for every single entry.

### The Danger Zone
#### `7_MitigationDisable.ps1` (The "Kamikaze" Tweak) ☢️
* **Function:** Disables Spectre/Meltdown CPU mitigations.
* **Benefit:** Recovers ~5-15% CPU performance on syscall-heavy workloads.
* **Warning:** **You would have to be insane to run this.** It removes critical security patches. Included for benchmarking only. Requires explicit "I AM INSANE" confirmation to run.

---

## 🚀 Usage Guide

**Note:** You may need to enable script execution first:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

Open **PowerShell as Administrator**:

```powershell
# 1. Unlock Performance Plan & Fix Latency
.\1_PowerLatencyFix.ps1

# 2. Optimize Wi-Fi for Speed
.\2_NetworkBooster.ps1

# ... Run other scripts as needed ...

# 8. Fix DPC Latency (Safe Mode: Creates Restore Point first)
.\8_MSIModeEnabler.ps1
```
