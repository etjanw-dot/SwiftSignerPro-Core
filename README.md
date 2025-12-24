
<div align="center">

<img src="https://github.com/user-attachments/assets/986892f9-c32f-448d-a24e-ba8659203fbf" width="180" alt="EthSign Logo" style="border-radius: 40px; box-shadow: 0 10px 30px rgba(0,0,0,0.1);">

# EthSign

### ✨ Redefining the iOS Signing Experience ✨

[![Latest Release](https://img.shields.io/github/v/release/master726/EthSign?style=for-the-badge&color=7C3AED&logo=apple&logoColor=white&label=Release)](https://github.com/master726/EthSign/releases/latest)
[![Total Downloads](https://img.shields.io/github/downloads/master726/EthSign/total?style=for-the-badge&color=3B82F6&logo=github&logoColor=white&label=Downloads)](https://github.com/master726/EthSign/releases)
[![License](https://img.shields.io/badge/License-GPLv3-22C55E?style=for-the-badge&logo=gnu&logoColor=white)](LICENSE)
[![iOS](https://img.shields.io/badge/iOS-15.0+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/ios)
[![Discord](https://img.shields.io/badge/Discord-Join%20Us-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/sfbZfQzVdQ)

<br>

<p align="center">
  <b>EthSign</b> merges the powerful engine of <i>Feather</i> with a stunning, modern interface.<br>
  It's not just a signing tool—it's a complete app management suite designed for power users who appreciate beauty.
</p>

<br>

[**📥 Download IPA**](https://github.com/master726/EthSign/releases/latest) &nbsp;•&nbsp; [**💬 Discord**](https://discord.gg/sfbZfQzVdQ) &nbsp;•&nbsp; [**🐛 Report Bug**](https://github.com/master726/EthSign/issues) &nbsp;•&nbsp; [**✨ Request Feature**](https://github.com/master726/EthSign/issues/new)

</div>

<br>

---

<br>

## 📱 Screenshots

<div align="center">
<table>
<tr>
<td align="center"><b>🏠 Home</b></td>
<td align="center"><b>📦 Library</b></td>
<td align="center"><b>⚙️ Settings</b></td>
<td align="center"><b>🎨 Themes</b></td>
</tr>
<tr>
<td><img src="https://via.placeholder.com/200x400/1a1a2e/ffffff?text=Home" width="200"/></td>
<td><img src="https://via.placeholder.com/200x400/1a1a2e/ffffff?text=Library" width="200"/></td>
<td><img src="https://via.placeholder.com/200x400/1a1a2e/ffffff?text=Settings" width="200"/></td>
<td><img src="https://via.placeholder.com/200x400/1a1a2e/ffffff?text=Themes" width="200"/></td>
</tr>
</table>
</div>

<br>

---

<br>

## ⚡ Key Features

<table>
<tr>
<td width="50%">

### 🎨 Visual Excellence
- **Dynamic Theming** — Preset themes or full custom control
- **Rainbow Typography** — Signature gradient text effects
- **Liquid Glass UI** — Seamless iOS integration
- **13+ Accent Colors** — Match your personal style
- **Smooth Animations** — 60fps micro-interactions

</td>
<td width="50%">

### ⚡ Powerful Signing Engine
- **Bulk Processing** — Sign multiple apps at once
- **Tweak Injection** — `.dylib`, `.deb`, frameworks
- **Smart Metadata** — Edit names, versions, bundle IDs
- **Icon Customization** — Replace icons from library
- **Real UDID Fetch** — Get device UDID via web profile

</td>
</tr>
<tr>
<td width="50%">

### 📚 Seamless Management
- **Universal Library** — Downloaded, Signed, Installed
- **Repo Browser** — Add & browse third-party sources
- **Certificate Vault** — Secure `.p12` & `.mobileprovision`
- **Expiration Tracking** — Never miss a cert renewal
- **Auto-Password Detection** — Smart import handling

</td>
<td width="50%">

### 🛠 Pro Tools
- **UDID Whitelisting** — Restrict to authorized devices
- **URL/ZIP Import** — Direct file imports
- **Live Logging** — Real-time signing console
- **Repo Maker** — Create your own app repos
- **Bulk Certificate Import** — Import multiple certs

</td>
</tr>
</table>

<br>

---

<br>

## 📥 Installation

<details open>
<summary><b>Method 1: TrollStore (Recommended)</b></summary>
<br>

> Best for jailbroken or TrollStore-compatible devices

1. Download the `.ipa` from [Releases](https://github.com/master726/EthSign/releases/latest)
2. Open in TrollStore
3. Tap **Install**
4. Done! Permanent installation with no revokes.

</details>

<details>
<summary><b>Method 2: AltStore / SideStore</b></summary>
<br>

1. Download the `.ipa` file
2. Open AltStore → My Apps → `+` button
3. Select the `.ipa` file
4. Wait for installation

> ⚠️ Requires refresh every 7 days

</details>

<details>
<summary><b>Method 3: Sideloadly / 3uTools</b></summary>
<br>

1. Connect device to computer
2. Open Sideloadly
3. Drag & drop the `.ipa`
4. Enter Apple ID and install

</details>

<br>

---

<br>

## 🔧 Quick Setup

```
1️⃣  Launch EthSign
2️⃣  Go to Settings → Certificates  
3️⃣  Import your .p12 + .mobileprovision
4️⃣  (Optional) Tap "Get UDID" for real device UDID
5️⃣  Start signing apps!
```

<br>

---

<br>

## 🏗 Project Structure

<details>
<summary><b>📁 View Directory Layout</b></summary>
<br>

```
EthSign/
├── Ksign/
│   ├── Views/
│   │   ├── Home/           # Dashboard & Quick Actions
│   │   ├── Sources/        # Repositories & App Browser
│   │   ├── Apps/           # App Library
│   │   ├── Settings/       # Configuration & Theming
│   │   ├── Signing/        # Core Signing Logic
│   │   └── Library/        # Downloaded & Signed Apps
│   ├── Backend/
│   │   ├── Storage/        # Persistence Layer (CoreData)
│   │   ├── UDIDService/    # UDID Retrieval Service
│   │   └── Handlers/       # File Processing & Injection
│   └── Resources/          # Assets, Plists, Localization
├── NimbleKit/              # UI Components Library
├── AltSourceKit/           # Repo Format Parser
├── Zsign/                  # Code Signing Engine
├── udid-website/           # UDID Retrieval Web Service
│   ├── netlify/functions/  # Serverless API
│   └── index.html          # Landing Page
└── ssh_build_tool/         # Remote Build Utilities
```

</details>

<br>

---

<br>

## 🌐 UDID Website

EthSign includes a **dedicated UDID retrieval website** for fetching your device's real UDID:

**🔗 Live:** [https://udid-ethsign.netlify.app](https://udid-ethsign.netlify.app)

| Feature | Description |
|---------|-------------|
| **Profile-based** | Uses Apple's mobileconfig for true UDID |
| **Secure** | No data stored on servers |
| **Auto-return** | Redirects back to app with UDID |
| **Beautiful UI** | Dark mode with glassmorphism |

<br>

---

<br>

## 📜 Licenses & Acknowledgments

<div align="center">

### 📋 This Project License

[![GPLv3 License](https://img.shields.io/badge/License-GPL%20v3-blue.svg?style=for-the-badge&logo=gnu)](LICENSE)

EthSign is released under the **GNU General Public License v3.0**.  
You are free to use, modify, and distribute this software under the same license.

</div>

<br>

### 🏛️ Third-Party Open Source Libraries

We stand on the shoulders of giants. EthSign uses these amazing open-source projects:

<table>
<tr>
<th width="25%">Library</th>
<th width="20%">License</th>
<th width="55%">Description</th>
</tr>
<tr>
<td>
  <a href="https://github.com/niceflag/zsign"><b>🔐 zsign</b></a>
</td>
<td>
  <img src="https://img.shields.io/badge/LGPL--3.0-orange?style=flat-square" />
</td>
<td>Core code signing engine for iOS apps. Powers the entire signing functionality.</td>
</tr>
<tr>
<td>
  <a href="https://github.com/altstoreio/AltStore"><b>📦 AltStore</b></a>
</td>
<td>
  <img src="https://img.shields.io/badge/AGPL--3.0-green?style=flat-square" />
</td>
<td>Repository JSON format compatibility for app sources and distribution.</td>
</tr>
<tr>
<td>
  <a href="https://github.com/kean/Nuke"><b>🖼️ Nuke</b></a>
</td>
<td>
  <img src="https://img.shields.io/badge/MIT-blue?style=flat-square" />
</td>
<td>High-performance image loading and caching library for Swift.</td>
</tr>
<tr>
<td>
  <a href="https://github.com/nicklockwood/SwiftFormat"><b>🔧 SwiftFormat</b></a>
</td>
<td>
  <img src="https://img.shields.io/badge/MIT-blue?style=flat-square" />
</td>
<td>Code formatting and style consistency.</td>
</tr>
<tr>
<td>
  <a href="https://github.com/rsms/inter"><b>🔤 Inter Font</b></a>
</td>
<td>
  <img src="https://img.shields.io/badge/OFL--1.1-purple?style=flat-square" />
</td>
<td>Beautiful, highly readable typeface designed for UI.</td>
</tr>
</table>

<br>

<details>
<summary><b>📄 View Full License Texts</b></summary>
<br>

Full license texts are available in:
- [`LICENSE`](LICENSE) — Main project license (GPLv3)
- [`LICENSES.md`](LICENSES.md) — All third-party license acknowledgments
- [`LICENSE_ELLEKIT`](LICENSE_ELLEKIT) — ElleKit license

</details>

<br>

---

<br>

## 🌟 Star History

<div align="center">
<a href="https://www.star-history.com/#master726/EthSign&Timeline">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=master726/EthSign&type=Timeline&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=master726/EthSign&type=Timeline" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=master726/EthSign&type=Timeline" width="100%" />
  </picture>
</a>
</div>

<br>

---

<br>

## 💖 Credits & Contributors

<div align="center">

| Role | Contributor |
|------|-------------|
| **Core Engine** | kwchrysalis (Feather Backend) |
| **Product Design** | Khoindvn |
| **Core Development** | Nyasami |
| **Maintainer** | EthFR |

<br>

<sub>Built with ❤️ by the <b>EthSign Team</b></sub>

<br>

[![GitHub Sponsors](https://img.shields.io/badge/Sponsor-EA4AAA?style=for-the-badge&logo=githubsponsors&logoColor=white)](https://github.com/sponsors/master726)

</div>

<br>

---
*offical* licenses # Third-Party Licenses

This project uses or may incorporate code from the following open-source projects:

---

## 1. zsign (Code Signing Library)
**License:** GNU Lesser General Public License v3.0 (LGPL-3.0)
**Repository:** https://github.com/niceflag/zsign

```
GNU LESSER GENERAL PUBLIC LICENSE
Version 3, 29 June 2007

Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
Everyone is permitted to copy and distribute verbatim copies
of this license document, but changing it is not allowed.

This version of the GNU Lesser General Public License incorporates
the terms and conditions of version 3 of the GNU General Public
License, supplemented by the additional permissions listed below.
```

---

## 2. AltStore/AltSource (Repository Format)
**License:** GNU Affero General Public License v3.0 (AGPL-3.0)
**Repository:** https://github.com/altstoreio/AltStore

The AltStore repository JSON format is used for app distribution compatibility.

```
GNU AFFERO GENERAL PUBLIC LICENSE
Version 3, 19 November 2007

Copyright (C) 2007 Free Software Foundation, Inc.
```

---

## 3. Nuke (Image Loading)
**License:** MIT License
**Repository:** https://github.com/kean/Nuke

```
MIT License

Copyright (c) 2015-2024 Alexander Grebenyuk

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 4. SwiftUI & UIKit (Apple Frameworks)
**License:** Apple SDK License Agreement
**Provider:** Apple Inc.

These are proprietary Apple frameworks included as part of the iOS SDK.
Usage is governed by the Apple Developer Program License Agreement.

---

## 5. Inter Font (Typography)
**License:** SIL Open Font License 1.1
**Repository:** https://github.com/rsms/inter

```
Copyright 2020 The Inter Project Authors (https://github.com/rsms/inter)

This Font Software is licensed under the SIL Open Font License, Version 1.1.
This license is available with a FAQ at: http://scripts.sil.org/OFL
```

---

## Acknowledgments

This project also builds upon concepts and patterns from the iOS development
community. We thank all contributors to the open-source ecosystem that makes
projects like this possible.

<div align="center">

<sub>© 2024 EthSign. Released under the GPLv3 License.</sub>

</div>
