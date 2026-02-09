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
#### `5_NVMeBooster.ps1` (The Server Storage Stack) ⚡
* **Unlocks:** Enables the **"Native NVMe"** driver stack ported from **Windows Server 2025**.
* **Benefit:** Bypasses legacy SCSI translation for ~20% higher IOPS.
* **Warning:** May break proprietary dashboard tools (Samsung Magician). Use with caution.
* **Potential Issues:**
  * **Critical:** May not boot on systems with striped/RAID NVMe configurations.
  * Proprietary NVMe health monitoring tools (Samsung, Intel, WD) may not work.
  * Rollback requires manual registry edits or System Restore.
  * Some enterprise SSDs may use undocumented firmware features incompatible with native stack.

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

### The Danger Zone
#### `7_MitigationDisable.ps1` (The "Kamikaze" Tweak) ☢️

**EDUCATIONAL PURPOSE ONLY. NOT RECOMMENDED FOR PRODUCTION SYSTEMS.**

* **Function:** Disables Spectre and Meltdown CPU mitigations.
* **Claimed Benefit:** Recovers ~5-15% CPU performance on syscall-heavy workloads.
* **Requires Confirmation:** Explicit "I AM INSANE" confirmation to run.

##### What Are Spectre and Meltdown?

In 2018, researchers discovered two families of CPU vulnerabilities that fundamentally changed how we view processor security:

- **Meltdown (CVE-2017-5754):** On Intel and some ARM processors, user-level processes can read arbitrary kernel memory by exploiting the CPU's out-of-order execution engine. An attacker can steal passwords, encryption keys, browser session tokens, and production database credentials directly from memory.

- **Spectre (CVE-2017-5753/5715):** Exploits branch prediction in modern CPUs. An attacker can trick the CPU into speculating down the wrong code path, leaving sensitive data in the CPU cache where it can be read via timing attacks. This works across process boundaries and can leak data from the kernel, other processes, or even virtualized containers.

Both attacks are **remote-exploitable** in many contexts (especially in cloud environments and containers) and have been weaponized in real-world attacks targeting production systems.

##### Why Do Mitigations Exist?

Windows, Linux, and all major OSes patch these vulnerabilities using:

1. **Kernel ASLR + KPTI (Kernel Page Table Isolation):** Separates kernel and user page tables to prevent Meltdown-style reads. Costs ~5% latency on syscall-heavy workloads.
2. **CPU microcode updates:** Disables branch prediction as needed; adds ~2-10% overhead depending on workload.
3. **Retpolines & Indirect speculation barriers:** Software-based mitigation for Spectre in the browser/JIT context; browser JavaScript is particularly vulnerable.

**These are not optional patches.** They protect:
- **Your machine:** From local privilege escalation and data theft.
- **Your credentials:** Passwords, SSH keys, API tokens in memory are protected.
- **Your code:** If you're running Docker, WSL, or any containerized workload, Spectre/Meltdown attacks can escape container isolation.
- **Production systems you access:** If your dev machine is compromised, attackers can pivot to servers you SSH/RDP into.

##### Who Should NOT Run This Script (Everyone Except the Last Group)

- ✗ **Developers running Docker/WSL:** Spectre can escape container isolation. If your container is compromised, attackers can read your host kernel and leap to other containers.
- ✗ **Anyone handling production credentials/API keys:** These live in memory. Meltdown/Spectre can exfiltrate them without privilege escalation.
- ✗ **Cloud/remote workers:** Your machine is a pivot point to production systems. Compromising it is worth more than the 5-15% performance gain.
- ✗ **Anyone sharing a machine (family computer, shared lab hardware):** Mitigations protect you from other users stealing your data.
- ✗ **Systems with any network access:** A compromised service (browser, remote tool, application bug) can trigger Meltdown/Spectre without your knowledge.

**The ONLY legitimate use case:**

- ✓ **Isolated benchmarking hardware with NO network access, NO browsers running, NO containers, and NO credential storage.** Before using a server for (e.g.) HPC compiling where you have time budget and isolation guarantees.

Even then, re-enable mitigations afterward.

* **Potential Issues (Security):**
  * **Meltdown risk:** Any process can read kernel memory, including passwords, encryption keys, and session tokens.
  * **Spectre risk:** Attackers can use timing attacks to extract sensitive data from the CPU cache across process/container boundaries.
  * **Container escape:** Docker/WSL containers can read the host kernel and other containers' memory.
  * **No protection from local attacks:** Privilege escalation exploits become much more dangerous.
  * **Supply-chain risk:** If your dev machine is compromised, attackers gain access to your SSH keys and can pivot to production systems.

* **Potential Issues (System):**
  * Cannot be undone without a reboot and another script run (or registry manual edit).
  * If the system is ever compromised, there is no memory protection layer.
  * Security scanning tools may flag the machine as non-compliant or vulnerable.
  * May void hardware warranty or violate enterprise security policies.

**BOTTOM LINE:** Do not run this on any system that:
1. Connects to the internet.
2. Stores or accesses production credentials.
3. Runs Docker, WSL, VMs, or any containerized workload.
4. Is shared with other users.
5. Is used for development or accessing remote systems.

If you are still considering this, **you are not in the target audience for this toolkit.** The performance improvement is not worth the security risk for 99.99% of use cases.

---

## 🚀 Usage Guide

### Tiered Approach

**Scripts 1–4 (Recommended for Most Users)** 🟢
These scripts address fundamental latency issues with minimal risk:
- `1_PowerLatencyFix.ps1` — Safe; no data loss or boot risk.
- `2_NetworkBooster.ps1` — Safe; Wi-Fi quality may vary by hardware.
- `3_BloatwareNeutralizer.ps1` — Generally safe; may break OEM-specific features.
- `4_SystemHealthAudit.ps1` — Read-only audit; no risk.

**Scripts 5–8 (Advanced Users Only)** 🟡
These require understanding the tradeoffs; test in non-critical environments first:
- `5_NVMeBooster.ps1` — May break RAID setups; requires rollback knowledge.
- `6_MemoryTweak.ps1` — Changes RAM behavior; can affect application performance.
- `8_MSIModeEnabler.ps1` — Creates restore point first, but boot risk exists on incompatible hardware.

**Scripts 9–10 (Situational)** 🟠
Safe but interactive; requires user judgment:
- `9_WindowsDebloater.ps1` — Requires confirmation for each removal.
- `10_StartupKiller.ps1` — Requires confirmation for each startup item.

**Script 7 (DO NOT RUN - Educational Only)** 🔴
- `7_MitigationDisable.ps1` — Security-disabling; only for isolated benchmarking. See "The Danger Zone" section for details. **If you work with Docker, WSL, or production systems, do not use this.**

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
.\5_NVMeBooster.ps1        # Optional: Server-grade NVMe stack
.\8_MSIModeEnabler.ps1     # Optional: Fix DPC latency (creates restore point)

# Maintenance (Interactive; requires confirmation)
.\9_WindowsDebloater.ps1
.\10_StartupKiller.ps1

# DO NOT RUN (unless you are benchmarking on isolated hardware)
# .\7_MitigationDisable.ps1
```

---

## ❓ FAQ

**Q: Can I run all scripts at once?**
A: No. Run 1–4 first, test stability for a week, then consider 5–8. Always create a System Restore Point before running advanced scripts. Never run script 7 unless you understand the security implications.

**Q: What if something breaks?**
A: Scripts 5–8 are designed to be rollback-friendly (via System Restore or registry edits). Script 1 can be reverted by switching back to "Balanced" power plan. Script 3 can be reverted by re-enabling services. See individual script comments for rollback instructions.

**Q: Is this safe for production systems?**
A: No. This toolkit is for personal machines and dev environments only. Do not use on servers, shared systems, or machines accessing production infrastructure.

**Q: Can I disable mitigations (script 7) on my dev machine?**
A: No. This is explicitly not recommended. Your dev machine is a pivot point to production. Compromising it exposes all your credentials and SSH keys. The performance gain is not worth the security risk.
