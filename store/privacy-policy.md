# Privacy Policy — Moha Lab Optimization

_Last updated: October 31, 2026_

Moha Lab Optimization ("the app") is developed by Mohamed Bashir Ali ("we").
This policy explains what data the app handles.

## 1. Data that stays on your device
- **Tweak and game settings**: your chosen tweaks, saved original system values,
  per-game profiles and network test history are stored only on your device.
- **Device information**: RAM, CPU, display, battery, storage, temperature and
  network type are read to show live statistics and personal recommendations.
  This information is processed on the device and is **not sent to us**.
- **Installed apps**: the app reads your list of installed apps
  (`QUERY_ALL_PACKAGES`) only to detect games for per-game tuning. The list is
  never uploaded.
- **MohaLab Net Flash**: this feature uses Android's VPN permission to cut the
  internet of the apps you choose. Their data is dropped on your phone. It is not
  read, stored or sent anywhere, and no VPN server is involved.

We do not require an account and we do not collect your name, email, contacts,
photos, location or messages.

## 2. Anonymous usage statistics (Firebase Analytics)
To understand how many people use the app and which features are useful, the
app uses **Google Firebase Analytics**. It collects:
- anonymous app-instance identifiers, app version, device model, Android
  version, country (from IP) and session information,
- which screens are opened and which features are used (for example "tweak
  switched on", "preset applied"), without any personal content.

Analytics follows the same consent choice as ads: EEA/UK users are asked first,
and can change their choice in **Settings → Ad privacy options**.
See https://firebase.google.com/support/privacy

## 3. Advertising (Google AdMob)
The app shows ads provided by **Google AdMob**. To serve and measure ads, AdMob
may collect and process:
- your device's **advertising ID**,
- IP address and approximate location derived from it,
- device and app information and ad interaction data.

Users in the European Economic Area and the UK are asked for consent through
Google's consent form before personalised ads are shown, and can change their
choice at any time in **Settings → Ad privacy options**. You can also reset or
delete your advertising ID in your Android settings (Google → Ads).

Learn how Google uses this data:
https://policies.google.com/technologies/partner-sites

## 4. System permissions
Optional features use Shizuku, a one-time ADB permission, or root
(Magisk / KernelSU / APatch) to change documented Android settings you choose.
These changes happen only on your device, only when you turn them on, and your
original values are restored when you turn them off.

MohaLab Boost, if you turn it on, uses "Display over other apps" to show its
panel over your games and "Usage access" to notice when one of your games is
open. Which apps you open is checked on your device only; it is not stored or
sent anywhere. Smart trigger reads the part of the screen you chose, on your
phone only, to know when to tap; no picture leaves your phone.

## 5. Network
The network test contacts public servers to measure latency. No personal data is
sent as part of these tests.

When the app opens, it downloads a small settings file from our server
(hosted by Cloudflare) with announcements, the latest
version number and switches that can turn a feature off. With it the app sends
its version number, an anonymous user ID, your phone's maker and model, and its
Android version. The ID is a one-way hash of Android's ID for this app, so
reinstalling the app is not counted as a new user. It can't be turned back into
the original and has no name, account or phone number attached; a factory reset
changes it. About every six hours the app also sends the names of the Moha Lab
tweaks and features you have switched on, and while it is open it sends a small
"online" signal once a minute. We store your country from Cloudflare, not your IP
address; Cloudflare keeps the IP only in short-lived request logs. Records not seen
for a year are deleted. Which apps you have installed is never sent.
We use this information to improve the app: to see which phones, Android versions
and countries use it, find problems and decide what to work on.

If you allow notifications, the app subscribes to two Firebase Cloud Messaging
topics ("all" and its version number) so we can send news about updates and
fixes. Google delivers these messages; we do not receive or store any device
token.

## 6. Children
The app is not directed at children under 13.

## 7. Changes
We may update this policy; the date above shows the latest version.

## 8. Contact
- Telegram: https://t.me/Mohagaminglab
- Website: https://mohagaminglab.vercel.app
- GitHub: https://github.com/7Mohan
