# SafetyRing iOS (Windows-friendly build via CI) + BLE Simulator

This repository contains:
- iOS app (SwiftUI + CoreBluetooth) that connects to a BLE peripheral named "SafetyRing" and subscribes to Alert Notification (0x2A46). On receiving an "ALERT" payload, it triggers an alert workflow with SMS prefill and location.
- Python BLE simulator (for Linux/macOS) to emulate the SafetyRing peripheral and send "ALERT" notifications. On Windows, use an Android app alternative.
- GitHub Actions workflow to build an unsigned IPA on macOS runners, so you can sideload on Windows with Sideloadly. No local Xcode required.

## Features
- Scan/connect to BLE device named `SafetyRing`.
- Subscribe to GATT New Alert characteristic (0x2A46) under Alert Notification Service (0x1811).
- When an alert is received:
  - Local visual notification + sound.
  - Prefilled SMS via Messages app: "Alerte : j’ai besoin d’aide ! Localisation : …" to configured contacts.
  - Includes GPS location link when available.
- Offline handling (no network):
  - Show local alert (visual + sound + vibration/haptic).
  - Log event with timestamp to local storage.
  - When connectivity returns, re-offer to send the alert SMS.

## Limitations (important)
- iOS does not allow sending SMS automatically without user interaction. The app will open the Messages composer with recipients and body prefilled; you must tap Send.
- Building iOS apps requires macOS. This repo uses GitHub Actions (macOS runners) to build an unsigned IPA. You can then sideload the IPA on Windows with Sideloadly.
- Simulating a BLE peripheral from Windows using Python isn’t supported with `bleak` at this time. Use:
  - Linux/macOS + Python simulator (provided), or
  - Android phone with the free "nRF Connect" app to emulate a peripheral advertising the required service/characteristic and sending the `ALERT` payload.

## Quick start (Windows)

1) Clone this repo to your Windows machine.

2) Push it to your own GitHub repository (required for CI):
- Create a new empty repository on GitHub.
- Add it as a remote and push:
```
git init
git add .
git commit -m "Initial SafetyRing iOS"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

3) Wait for GitHub Actions to build an unsigned IPA:
- Go to GitHub → Actions tab → workflow "Build iOS (unsigned IPA)".
- When it finishes, download the artifact `SafetyRingApp-unsigned.ipa`.

4) Sideload the IPA on Windows:
- Install Sideloadly (`https://sideloadly.io`).
- Connect your iPhone via USB.
- Open Sideloadly, select `SafetyRingApp-unsigned.ipa`, enter your Apple ID if asked (for signing), and install.

5) Grant permissions on first app launch on iPhone:
- Bluetooth, Location (While Using the App), Notifications.

6) Configure recipients:
- In the app, add one or more phone numbers in international format (e.g., `+33612345678`).

7) Test BLE alert:
- Option A (recommended on Windows): Use an Android phone with "nRF Connect".
  - Create a peripheral with the Alert Notification Service (UUID 0x1811) and characteristic "New Alert" (UUID 0x2A46, Notify).
  - Advertise name `SafetyRing`.
  - Send a notification with ASCII payload `ALERT`.
- Option B (Linux/macOS): Run the Python simulator:
```
python3 -m venv .venv
. .venv/bin/activate   # Windows PowerShell: .venv\Scripts\Activate.ps1
pip install -r sim_requirements.txt
python sim_ring.py
```
  - Press Enter to emit an `ALERT` notification.

8) Offline scenario:
- Disable data/Wi‑Fi.
- Trigger an alert.
- The app logs the event and notifies you locally.
- Re-enable network; the app will propose sending the SMS.

## Notes on BLE characteristic 0x2A46
The official New Alert (0x2A46) characteristic is structured data. For this prototype, the app treats any notification payload containing ASCII `ALERT` as a trigger.

## Project structure
- `ios/` — iOS app sources, XcodeGen project spec, Info.plist
- `.github/workflows/ios_build.yml` — CI building unsigned IPA
- `sim_ring.py` — BLE peripheral simulator (Linux/macOS)
- `sim_requirements.txt` — Python requirements for the simulator

## Troubleshooting
- If the app doesn’t see your simulator, ensure it advertises the name `SafetyRing` and includes the Alert Notification Service (0x1811). Ensure the characteristic 0x2A46 has Notify enabled.
- If IPA fails to install, ensure you’re using a recent iOS version and Sideloadly, and that your Apple ID can be used for sideloading.
- Location might take a few seconds to acquire; the SMS will still be prefilled even if no coordinates are available yet.

## Security
This app is a prototype. Phone numbers are stored locally on-device using `UserDefaults`. Do not rely on it as a life-critical system.
