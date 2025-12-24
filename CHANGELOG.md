# ⚡ EthSign v0.25 - The "Device & Discovery" Release

## 🏠 Home Page Enhancements
*   **Enhanced Device Info Card**:
    *   Now shows device **Model** (e.g., "iPhone 15 Pro") with proper device name mapping.
    *   Displays **iOS Version** with Apple logo icon.
    *   **Green themed** icons and badge.
    *   **Verification badge** showing verified/not verified status.
    *   **Copy UDID button** with animated "Copied!" feedback.

*   **New Certificate Status Card**:
    *   Shows certificate count with orange badge.
    *   Displays first certificate with **validity status** (green=Valid, red=Expired).
    *   Shows **expiration date** with calendar icon.
    *   "+X more certificates" link when multiple certs exist.
    *   "Add" button when no certificates are configured.

## ⚙️ Settings Redesign
*   **Bigger App Header** (like KravaSigner style):
    *   App icon increased to **100x100** pixels.
    *   Larger app name with **bold title** font.
    *   Clean version display.
    *   Tagline now uses accent color.
    *   Card background with subtle glow effect.

*   **New "Color" Link**:
    *   Added rainbow gradient icon at top of General section.
    *   Quick access to theme customization.

*   **New Device Info Screen**:
    *   Full device information (model, iOS version, system name).
    *   **UDID Configuration** with edit capability.
    *   Verification status with verify/reset options.
    *   Battery state and locale info.
    *   All with green-themed icons.

## ✍️ Bulk Signing Improvements
*   **Horizontal IPA Layout**:
    *   Multiple IPAs now displayed **side-by-side** (swipeable).
    *   Scrollable app icon selector at top.
    *   Full menu visible for each app.
*   **Icon Buttons**:
    *   Reset button changed to icon (arrow.counterclockwise).
    *   Enhanced Start Signing button with gradient and icon.

---

## Full Commit History
*   `v0.25: Device info & certificate cards on Home`
*   `Settings: Bigger header, Color link, Device Info view`
*   `BulkSigning: Horizontal IPA layout with icon buttons`
*   `Home: Enhanced device info with model, iOS version`
*   `Home: Certificate status card with validity check`
*   `Settings: New DeviceInfoView with UDID config`

---

# Previous Release Notes

## ⚡ EthSign - The "Rainbow" Release

### 🎨 Visual & UI Overhaul
*   **New "Apple-Style" Design**: Completely redesigned the README and major UI components.
*   **Rainbow Typography**: The "EthSign" header and version info in Settings now feature a stunning animated rainbow gradient.
*   **Dynamic App Header**: The Settings header now displays your actual App Icon instead of a generic placeholder.
*   **Repo View Polish**:
    *   Removed the misplaced "All Repositories" card.
    *   **Smart Edit Mode**: Selection circles are now hidden by default and only appear when "Edit" is tapped.
    *   Added a proper Toolbar with **Add (+)**, **Edit (Pencil)**, and **Done** buttons.

### ✍️ Advanced Signing Features
*   **Bulk Signing 2.0**:
    *   **Selection Mode**: Added checkbox selection for bulk operations in "All Apps".
    *   **New Options**: Choose between "Sign All Selected" or "Sign One by One" (with swipe navigation).
    *   **Quick Access**: Added a new **Bulk Sign** button (signature icon) directly in the Library toolbar.
*   **Certificate Freedom**:
    *   **Constraint Removed**: Removed the hardcoded restriction requiring certificates to have the password "kravasign". You can now use **any** valid certificate.
    *   **Smart ZIP Import**: Improved ZIP import logic to auto-detect `.p12` and `.mobileprovision` files.
    *   **Auto-Fill Magic**: If your ZIP contains a `password.txt` with "kravasign", it auto-fills the password field; otherwise, it lets you enter it manually.

### 🛠️ Functionality & Build Improvements
*   **Tab Customization**: Added a new **"Optional Tabs"** section in Settings.
    *   You can now toggle **Files** and **Certificates** tabs on/off.
    *   Files tab is hidden by default for a cleaner look.
*   **UDID Verification**: Fixed the UDID check to correctly look for the `EthSign.verifiedUDID` key.
*   **Build System**:
    *   Optimized GitHub Actions workflow to force clean builds (removed caching).
    *   Configured build process to ignore non-critical warnings, ensuring successful IPA generation.

### 🐛 Bug Fixes
*   Fixed `UUID` type mismatch in AllAppsView.
*   Fixed optional string unwrapping issues in Settings.
*   Fixed `TabEnum` error by correcting the reference from `sources` to `repos`.
*   Reverted Bundle ID to `nya.asami.ksign` to ensure code signing consistency.
