# Permissions and Privacy Disclosure — Moha Lab Optimization

**Moha Lab Optimization** is committed to transparency, minimal data footprint, and user safety. The application operates entirely locally; no account is required, and your profiles, diagnostics sessions, and settings never leave your device.

---

## 1. Android Permissions Matrix

| Permission | Protection Level | Purpose / Why Needed | When Requested | What Happens If Denied |
| :--- | :--- | :--- | :--- | :--- |
| `android.permission.INTERNET` | Normal | 1. Network gaming latency pings and packet loss tests.<br>2. AdMob banner, interstitial, and rewarded ad serving.<br>3. Opening official community/support links in browser. | Granted automatically at install time. | App cannot run network latency diagnostics, display community links, or serve ads. |
| `android.permission.ACCESS_NETWORK_STATE` | Normal | Detects whether device is offline, on Wi-Fi, cellular, or VPN before running gaming diagnostics. | Granted automatically at install time. | Diagnostics engine assumes network state is unknown and cannot provide network-type-specific recommendations. |
| `android.permission.ACCESS_WIFI_STATE` | Normal | Checks Wi-Fi frequency band (2.4 GHz vs 5 GHz) and link speed (Mbps) to advise gamer on jitter reduction. | Granted automatically at install time. | Diagnostics engine omits Wi-Fi frequency recommendations and link speed telemetry. |
| `android.permission.READ_EXTERNAL_STORAGE`<br>*(maxSdkVersion=32)* | Dangerous | Computes total and free storage space for device diagnostics on Android 12 and below. | Requested at runtime if user views Hardware Diagnostics on legacy devices. | Storage card displays "Storage telemetry unavailable". No crash occurs. |
| `android.permission.QUERY_ALL_PACKAGES` | High-Scrutiny / Special | Enumerates installed games and applications so users can configure gaming profiles and launch games directly. | Declared in manifest for Android 11+ (API 30+). | App cannot auto-discover installed games; user cannot select existing games for optimization profiles. |

---

## 2. Google Play Store Compliance — `QUERY_ALL_PACKAGES`

Google Play Store maintains strict policy requirements for the `QUERY_ALL_PACKAGES` permission.
- **Permitted Core Functionality**: Moha Lab Optimization qualifies under the **Game Launcher / Device Optimization Management** category because its primary purpose is discovering user-installed games to apply per-game performance profiles and launch them directly.
- **Play Console Declaration**:
  - When submitting to Google Play Console, select **Device Management / Game Launcher utility** as the justification.
  - Explain: *"Moha Lab Optimization requires package visibility to detect installed games, display them in the user's game library, apply custom graphics/refresh rate profiles, and launch games directly with optimized system parameters."*

---

## 3. Privileged Operations (Shizuku & Root)

- **Shizuku is 100% Optional**: The app does not require root or Shizuku to function. Safe optimizations and network diagnostics run entirely within standard user permissions.
- **Explicit Consent**: Privileged operations (e.g. refresh rate override, system animation duration adjustment) require explicit permission granted via the external Shizuku manager application.
- **Zero Arbitrary Execution**: The app does **not** expose a generic shell execution pipeline. All Shizuku commands are strictly typed and sealed in `CommandRegistry`.

---

## 4. Local Data & Telemetry Guarantee

1. **No Account Required**: The application has no user accounts, login screens, or cloud synchronization servers.
2. **Local Storage**: Game profiles, optimization history, and preferences are stored exclusively on-device in private application sandbox storage (`SharedPreferences`).
3. **Safe Export & Import**:
   - Export produces a standardized JSON bundle.
   - Import rigorously validates file size (maximum 5 MB), JSON schema, and known keys.
   - **No code, scripts, or native commands are ever executed from imported files.**
4. **Crash Reporting & Analytics**:
   - Advertising identifiers are handled strictly by the official Google Mobile Ads SDK in accordance with Google Play Developer Program Policies.
   - Debug logging is completely stripped from release builds via ProGuard/R8.
