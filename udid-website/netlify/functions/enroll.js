/**
 * UDID Enrollment Function
 * 
 * This function generates and serves a configuration profile that:
 * 1. Gets installed on the iOS device
 * 2. Triggers iOS to send the device's UDID to our callback URL
 * 3. The callback then redirects the user back to the app with the UDID
 * 
 * Note: iOS 17+ may require signed profiles for Profile Service type.
 * This implementation uses a compatibility approach.
 */

const CALLBACK_URL = process.env.URL
    ? `${process.env.URL}/.netlify/functions/callback`
    : 'https://udid-ethsign.netlify.app/.netlify/functions/callback';

const APP_SCHEME = 'ksign';

/**
 * Generate a UUID v4
 */
function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16).toUpperCase();
    });
}

/**
 * Generate the enrollment mobileconfig profile
 * This profile uses OTA enrollment to retrieve the device UDID
 * 
 * For iOS 17+, Profile Service type needs proper signing.
 * This version uses a simpler format for better compatibility.
 */
function generateEnrollmentProfile() {
    const configUUID = generateUUID();

    // Use Configuration Profile format with Challenge for UDID retrieval
    // This is the OTA enrollment pattern that iOS supports
    const profileContent = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <dict>
        <key>Challenge</key>
        <string>EthSignUDIDChallenge</string>
        <key>DeviceAttributes</key>
        <array>
            <string>UDID</string>
            <string>IMEI</string>
            <string>ICCID</string>
            <string>VERSION</string>
            <string>PRODUCT</string>
            <string>DEVICE_NAME</string>
            <string>SERIAL</string>
        </array>
        <key>URL</key>
        <string>${CALLBACK_URL}</string>
    </dict>
    <key>PayloadDescription</key>
    <string>This temporary profile retrieves your device UDID for EthSign app. It will be automatically removed.</string>
    <key>PayloadDisplayName</key>
    <string>EthSign UDID</string>
    <key>PayloadIdentifier</key>
    <string>com.ethsign.udid</string>
    <key>PayloadOrganization</key>
    <string>EthSign</string>
    <key>PayloadRemovalDisallowed</key>
    <false/>
    <key>PayloadType</key>
    <string>Profile Service</string>
    <key>PayloadUUID</key>
    <string>${configUUID}</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
</dict>
</plist>`;

    return profileContent;
}

exports.handler = async (event, context) => {
    // Generate the enrollment profile
    const profile = generateEnrollmentProfile();

    // Return the profile as a downloadable mobileconfig file
    // Using proper MIME type for iOS to recognize it
    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/x-apple-aspen-config; charset=utf-8',
            'Content-Disposition': 'attachment; filename="EthSign-UDID.mobileconfig"',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0'
        },
        body: profile,
        isBase64Encoded: false
    };
};

