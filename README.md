# Gentle Guardian

A baby care tracker built with SwiftUI that keeps your whole family in sync -- no internet required.

## What It Does

Gentle Guardian helps parents and caregivers log and share everything about their baby's day:

- **Feeding** -- Breast, bottle, or solid food with amounts and duration
- **Diaper** -- Wet, dirty, or both with optional notes
- **Health** -- Temperature, medications, symptoms, and doctor visits
- **Activity** -- Tummy time, baths, outdoor play, and milestones
- **Sleep** -- Nap and overnight tracking

Every entry is timestamped and immediately available to every caregiver in the family circle.

## How Syncing Works

Gentle Guardian is powered by [Ditto](https://ditto.live)'s peer-to-peer synchronization platform. All data syncs directly between nearby devices over **Bluetooth Low Energy** and **local Wi-Fi** -- no cloud server is involved.

### Joining a Family Circle

When a caregiver registers a child, the app generates a unique 6-character sync code. Other family members enter that code on their own device to join the family circle. From that point on, every feeding, diaper change, health check, and activity logged by any caregiver appears on every device in real time.

### Offline-First

Because syncing happens device-to-device, Gentle Guardian works without an internet connection. Two phones in the same room will sync over Bluetooth. Devices on the same Wi-Fi network sync over LAN. When a device that was offline comes back into range, it catches up automatically -- no data is lost.

### No Cloud, No Accounts

There are no user accounts to create and no cloud service to configure. Your baby's data never leaves the mesh of devices in your family circle.

## Supported Platforms

| Platform | Minimum Version |
|----------|-----------------|
| iOS      | 26.0            |
| macOS    | 26.0            |

## Getting Started

1. Open `src/GentleGuardian.xcodeproj` in Xcode
2. Add your Ditto credentials to `src/GentleGuardian/Resources/ditto.plist` (get them from [portal.ditto.live](https://portal.ditto.live))
3. Select an iOS 26 simulator or My Mac and build with Cmd+R

For device builds, set your `DEVELOPMENT_TEAM` in the target's Signing & Capabilities tab.

---

## Privacy Notice

Gentle Guardian is a demonstration application built by Ditto to showcase peer-to-peer synchronization technology.

All data entered into this app -- including child profiles and care events -- is stored locally on your device and synced directly to other nearby devices in your family circle using Bluetooth Low Energy and local Wi-Fi.

No data is transmitted to any cloud server or third-party service. Ditto does not collect, store, or process any personal information entered into this app.

**This is a demo application and should not be used as a primary record-keeping tool for medical or health-related information.**

## Legal Information

Gentle Guardian is provided by Ditto Live, Inc. as a demonstration application for the Ditto peer-to-peer synchronization platform.

This software is provided "as is" without warranty of any kind, express or implied. Ditto Live, Inc. shall not be liable for any damages arising from the use of this application.

Ditto and the Ditto logo are trademarks of Ditto Live, Inc. Apple, iPhone, and iPad are trademarks of Apple Inc.

For more information about Ditto's technology and licensing, visit [ditto.live](https://ditto.live).

---

*This is a demo application built to showcase Ditto's peer-to-peer technology. It is not intended for production use.*

(c) 2026 Ditto Live, Inc. All rights reserved.
