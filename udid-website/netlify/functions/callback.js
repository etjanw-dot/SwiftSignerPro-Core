/**
 * UDID Callback Function
 * 
 * This function receives the device information from iOS after
 * the enrollment profile is installed. It then:
 * 1. Parses the UDID from the request
 * 2. Redirects the user back to the website with the UDID
 * 3. The website then redirects to the app via custom URL scheme
 */

const WEBSITE_URL = process.env.URL || 'https://udid-ethsign.netlify.app';
const APP_SCHEME = 'ksign';

/**
 * Parse the plist XML data from iOS device enrollment callback
 * Uses simple regex parsing - no external dependencies needed
 */
function parseDeviceInfo(body) {
    if (!body) return null;

    try {
        // The body may come as base64 encoded or raw
        let plistData = body;

        // Try to decode if base64
        if (!body.includes('<?xml') && !body.includes('<plist')) {
            try {
                plistData = Buffer.from(body, 'base64').toString('utf8');
            } catch (e) {
                // Not base64, use as-is
            }
        }

        // Extract key-value pairs from the plist XML using regex
        const result = {};

        // Match patterns like <key>UDID</key><string>value</string>
        const keyValueRegex = /<key>([^<]+)<\/key>\s*<string>([^<]*)<\/string>/gi;
        let match;

        while ((match = keyValueRegex.exec(plistData)) !== null) {
            result[match[1]] = match[2];
        }

        return result;
    } catch (error) {
        console.error('Failed to parse plist:', error);
        return null;
    }
}

/**
 * Generate a success response page that redirects to the app
 */
function generateSuccessPage(udid) {
    const appUrl = `${APP_SCHEME}://udid?value=${encodeURIComponent(udid)}`;
    const webUrl = `${WEBSITE_URL}?udid=${encodeURIComponent(udid)}`;

    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="refresh" content="0;url=${webUrl}">
    <title>UDID Retrieved - EthSign</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
            background: #0a0a0f;
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            text-align: center;
        }
        .container {
            padding: 40px 20px;
        }
        .checkmark {
            width: 64px;
            height: 64px;
            background: #22c55e;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
        }
        .checkmark svg {
            width: 32px;
            height: 32px;
            fill: white;
        }
        h1 {
            font-size: 24px;
            margin-bottom: 12px;
        }
        p {
            color: #a0a0b0;
            margin-bottom: 24px;
        }
        .udid {
            background: #1a1a24;
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 12px;
            padding: 16px;
            font-family: monospace;
            font-size: 14px;
            color: #3b82f6;
            word-break: break-all;
            margin-bottom: 24px;
        }
        .btn {
            display: inline-block;
            padding: 14px 28px;
            background: linear-gradient(135deg, #3b82f6, #8b5cf6);
            color: white;
            text-decoration: none;
            border-radius: 12px;
            font-weight: 600;
        }
        .loading {
            margin-top: 20px;
            color: #a0a0b0;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="checkmark">
            <svg viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z"/></svg>
        </div>
        <h1>UDID Retrieved!</h1>
        <p>Your device UDID has been successfully retrieved.</p>
        <div class="udid">${udid.toUpperCase()}</div>
        <a href="${appUrl}" class="btn">Return to EthSign</a>
        <p class="loading">Redirecting automatically...</p>
    </div>
    <script>
        // Try to redirect to the app immediately
        setTimeout(function() {
            window.location.href = "${appUrl}";
        }, 500);
    </script>
</body>
</html>`;
}

/**
 * Generate an error page
 */
function generateErrorPage(message) {
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error - EthSign</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
            background: #0a0a0f;
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            text-align: center;
        }
        .container { padding: 40px 20px; }
        .error-icon {
            width: 64px;
            height: 64px;
            background: #ef4444;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
        }
        .error-icon svg {
            width: 32px;
            height: 32px;
            fill: white;
        }
        h1 { font-size: 24px; margin-bottom: 12px; }
        p { color: #a0a0b0; margin-bottom: 24px; }
        .btn {
            display: inline-block;
            padding: 14px 28px;
            background: #3b82f6;
            color: white;
            text-decoration: none;
            border-radius: 12px;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="error-icon">
            <svg viewBox="0 0 24 24"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/></svg>
        </div>
        <h1>Something went wrong</h1>
        <p>${message}</p>
        <a href="${WEBSITE_URL}" class="btn">Try Again</a>
    </div>
</body>
</html>`;
}

exports.handler = async (event, context) => {
    console.log('Callback received:', {
        method: event.httpMethod,
        headers: event.headers,
        bodyLength: event.body ? event.body.length : 0
    });

    // Handle POST request from iOS device
    if (event.httpMethod === 'POST') {
        try {
            const deviceInfo = parseDeviceInfo(event.body);
            console.log('Parsed device info:', deviceInfo);

            if (deviceInfo && deviceInfo.UDID) {
                const udid = deviceInfo.UDID;
                console.log(`UDID retrieved: ${udid}`);

                return {
                    statusCode: 200,
                    headers: {
                        'Content-Type': 'text/html; charset=utf-8'
                    },
                    body: generateSuccessPage(udid)
                };
            } else {
                // Try to extract UDID from raw body if parsing failed
                const bodyStr = event.body || '';

                // Try base64 decode first
                let decodedBody = bodyStr;
                if (!bodyStr.includes('<?xml')) {
                    try {
                        decodedBody = Buffer.from(bodyStr, 'base64').toString('utf8');
                    } catch (e) {
                        // Use original
                    }
                }

                const udidMatch = decodedBody.match(/<key>UDID<\/key>\s*<string>([^<]+)<\/string>/i);

                if (udidMatch && udidMatch[1]) {
                    const udid = udidMatch[1];
                    console.log(`UDID extracted from raw body: ${udid}`);

                    return {
                        statusCode: 200,
                        headers: {
                            'Content-Type': 'text/html; charset=utf-8'
                        },
                        body: generateSuccessPage(udid)
                    };
                }

                console.error('Could not find UDID in device info. Body preview:', decodedBody.substring(0, 500));
                return {
                    statusCode: 200,
                    headers: {
                        'Content-Type': 'text/html; charset=utf-8'
                    },
                    body: generateErrorPage('Could not retrieve device UDID. Please try again.')
                };
            }
        } catch (error) {
            console.error('Error processing callback:', error);
            return {
                statusCode: 200,
                headers: {
                    'Content-Type': 'text/html; charset=utf-8'
                },
                body: generateErrorPage(`Error: ${error.message}`)
            };
        }
    }

    // Handle GET request (shouldn't happen normally, but provide feedback)
    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'text/html; charset=utf-8'
        },
        body: generateErrorPage('Invalid request. Please start from the EthSign app.')
    };
};
