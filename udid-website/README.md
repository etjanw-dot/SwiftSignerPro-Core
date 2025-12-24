# EthSign UDID Website

A beautiful, modern website for retrieving iOS device UDIDs using Apple's configuration profile mechanism.

## 🚀 Features

- **Secure UDID Retrieval**: Uses Apple's official Profile Service mechanism
- **Modern UI**: Dark mode design with gradients and animations
- **Automatic Redirect**: Returns the UDID directly to the EthSign app
- **Privacy Focused**: No data is stored on servers

## 📋 How It Works

1. User taps "Get My Device UDID" in the app or website
2. A temporary configuration profile is downloaded
3. User installs the profile in Settings → General → VPN & Device Management
4. iOS sends the device info (including UDID) to our callback
5. The callback redirects back to the app with the UDID via `ksign://udid?value=XXXX`

## 🛠 Deployment

### Deploy to Netlify

1. **Install dependencies:**
   ```bash
   cd udid-website
   npm install
   ```

2. **Deploy via Netlify CLI:**
   ```bash
   npm install -g netlify-cli
   netlify login
   netlify init
   netlify deploy --prod
   ```

3. **Or deploy via GitHub:**
   - Push this folder to a GitHub repository
   - Connect the repo to Netlify
   - Netlify will auto-deploy on push

### Environment Variables

The following environment variables are automatically set by Netlify:
- `URL`: Your deployed site URL (used for callback generation)

## 📁 File Structure

```
udid-website/
├── index.html              # Main landing page
├── netlify.toml            # Netlify configuration
├── package.json            # Node.js dependencies
└── netlify/
    └── functions/
        ├── enroll.js       # Generates the mobileconfig profile
        └── callback.js     # Handles the UDID callback from iOS
```

## 🔧 Local Development

```bash
# Install dependencies
npm install

# Run local dev server with Netlify Functions
npm run dev
```

This will start a local server at `http://localhost:8888` with full function support.

## 📱 iOS App Integration

The app should:

1. **Handle the URL scheme** `ksign://udid?value=XXXX`:
   ```swift
   // In FeatherApp.swift or AppDelegate
   .onOpenURL { url in
       if url.scheme == "ksign" && url.host == "udid" {
           if let udid = URLComponents(url: url, resolvingAgainstBaseURL: false)?
               .queryItems?.first(where: { $0.name == "value" })?.value {
               UDIDService.shared.saveUDID(udid)
           }
       }
   }
   ```

2. **Update the website URL** in `UDIDService.swift`:
   ```swift
   static let udidWebsiteURL = "https://your-site.netlify.app"
   ```

## 🔒 Security Notes

- The configuration profile is temporary and removable
- No device data is stored on our servers
- The UDID is only passed to the app via URL scheme
- HTTPS is required for the callback

## 📄 License

MIT License - For personal use only.
