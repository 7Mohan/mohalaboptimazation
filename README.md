# ⚡ Moha Lab Optimization

<div align="center">

![Moha Lab Optimization Banner](https://img.shields.io/badge/MOHA%20LAB-OPTIMIZATION%20v1.2-00DC82?style=for-the-badge&logo=android&logoColor=white)

**High-Performance Android Gaming & System Tuning Framework**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-10%20to%2015-3DDC84?style=flat-square&logo=android&logoColor=white)](https://android.com)
[![Shizuku](https://img.shields.io/badge/Shizuku-Privilege%20API-FF6F00?style=flat-square)](https://shizuku.rikka.app/)
[![License](https://img.shields.io/badge/License-Proprietary-gray?style=flat-square)](#license)

[Features](#-key-features) • [Architecture](#-architecture) • [Security & Privacy](#-security--privacy) • [Getting Started](#-getting-started) • [Community](#-community--links)

</div>

---

## 📖 Overview

**Moha Lab Optimization** is an Android gaming utility that applies **real, verifiable system tweaks** — documented Android settings and `cmd` services — with live telemetry, per-game Game Mode tuning and gaming network diagnostics.

Built with **Flutter** and a performant **glassmorphism** design language, it works rootless through the **Shizuku API** (or a one-time ADB permission grant for settings-based tweaks).

---

## ✨ Key Features

### ⚙️ 1. Verified System Tweaks
- Lock max refresh rate, faster animations, disable window blurs, fixed performance mode, gaming Do Not Disturb, block pop-up banners, private DNS, background scan control, faster touch & hold.
- Every tweak is **read back from the device** after applying — toggles reflect real state and survive app restarts.
- Original values are saved on-device before the first change and restored exactly when switched off.
- Tweaks Android resets on reboot are re-applied automatically when Shizuku reconnects.

### ⚡ 2. Rootless Privilege Paths
- **Shizuku**: full access to settings and `cmd` services (power, game, package, notification).
- **ADB grant** (`pm grant … WRITE_SECURE_SETTINGS`): unlocks every settings-based tweak without Shizuku.
- No arbitrary shell endpoint — commands are built natively from fixed templates and validated arguments.

### 🔓 Root Mode (Magisk / KernelSU / APatch)
- Tweaks are split into **Non-root** and **Root** tabs.
- Detects Magisk, KernelSU (and Next), APatch and Kitsune; "Grant root" triggers the manager's standard `su` prompt. One persistent root shell is reused (no per-command toasts); the grant is resumed silently on next launch.
- Root-only kernel tweaks: CPU performance governor, GPU (Adreno / Mali) performance governor, TCP BBR, reduced swappiness, Wi-Fi low-latency / high-perf locks. Root actions: drop kernel caches, storage TRIM.
- Every kernel node's original value is saved and restored; values reset on reboot and active tweaks are re-applied when the root session resumes. Shizuku started as root is also treated as root.

### 🎮 3. Per-Game Tuning (Android 13/14+ Game Mode)
- Game Mode (standard / performance / battery), render-resolution downscale and FPS override per game.
- Settings are per-app and only active while the game runs.
- ART `speed` compilation per game; Turbo Launch applies the profile before launching.

### 🧹 4. Measured Maintenance
- RAM Boost, app-cache cleanup and ART background dexopt — results are measured (MB freed), never estimated.

### 🌐 5. Gaming Network Diagnostics
- Latency, jitter and packet-loss probing with connection quality scoring.

### 📊 6. Live Telemetry
- Per-core CPU clocks, battery temperature with PowerManager thermal status and throttling-headroom forecast, RAM, battery and storage.

---

## 🏗️ Architecture

The codebase adheres to **Clean Architecture** with strict feature separation and modular domain boundaries:

```
lib/
├── core/
│   ├── constants/             # App-wide configurations and presets
│   ├── theme/                 # Glass design tokens, colors & typography
│   └── utils/                 # Security, platform checks, and formatting
├── features/
│   ├── diagnostics/           # Hardware telemetry & thermal sensors
│   ├── games/                 # Game library, detection, and per-game Game Mode tuning
│   ├── home/                  # Dashboard, live telemetry & quick actions
│   ├── network/               # Ping latency, packet loss, & network tests
│   ├── onboarding/            # First-run guided setup & permissions tour
│   ├── optimization/          # Tweak catalog, presets & TweakEngine bridge
│   ├── settings/              # App preferences, data backup, & cache management
│   └── shizuku/               # Shizuku IPC bridge & permission flow
├── shared/
│   └── widgets/               # Glass cards, sheets, navigation shell & components
└── main.dart                  # Application entry point & Riverpod provider scope
```

Native side (`android/app/src/main/kotlin/.../`): `TweakEngine.kt` owns every privileged command, snapshots and state read-back; `ShizukuBridge.kt` executes them with exit-code checking.

---

## 🛡️ Security & Privacy

Security and device integrity are core design priorities:
- **No Insecure Exploits:** Uses official Android platform APIs and standardized Shizuku binder IPC.
- **Audited Commands:** All ADB and shell commands are pre-registered and validated against an explicit whitelist.
- **Zero Telemetry Leaks:** No personal identity data, IMEI, or sensitive hardware identifiers are collected or transmitted.
- For complete audits, refer to [SECURITY_AUDIT.md](SECURITY_AUDIT.md) and [PERMISSIONS_AND_PRIVACY.md](PERMISSIONS_AND_PRIVACY.md).

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.24.0` or higher
- **Android SDK**: API Level 26 (Android 8.0) to API Level 35 (Android 15)
- **Java**: JDK 17
- Optional: [Shizuku](https://shizuku.rikka.app/) installed on device for privileged system-level optimizations.

### Build and Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/7Mohan/mohalaboptimazation.git
   cd mohalaboptimazation
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Build Release APK:**
   ```bash
   flutter build apk --release
   ```

4. **Install to connected Android device:**
   ```bash
   adb install -r -d build/app/outputs/flutter-apk/app-release.apk
   ```

5. **Run Web Version:**
   ```bash
   flutter build web --release
   ```

---

## 🌐 Community & Links

- 🌐 **Official Website:** [mohagaminglab.vercel.app](https://mohagaminglab.vercel.app/)
- ✈️ **Telegram Channel:** [@Mohagaminglab](https://t.me/Mohagaminglab)
- 🎵 **TikTok:** [@professor0011110](https://www.tiktok.com/@professor0011110?_r=1&_t=ZS-99v0tA6CxRS)
- 🐙 **Developer GitHub:** [@7Mohan](https://github.com/7Mohan)

---

## 📄 License

Copyright © 2026 Mohamed Bashir Ali ([@7Mohan](https://github.com/7Mohan)). All rights reserved.
