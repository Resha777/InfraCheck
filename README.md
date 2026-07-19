# InfraCheck

**A lightweight macOS menu bar app for monitoring your infrastructure at a glance.**

InfraCheck lives in your menu bar and continuously watches your servers, endpoints, and certificates. One look at the icon tells you whether everything is healthy - green check for all-clear, warning triangle when something needs attention, red octagon when something is down.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Features

- **HTTP/HTTPS uptime monitoring** - periodic GET requests with status code and response-time reporting. Supports basic-auth credentials, stored securely in the macOS Keychain.
- **TCP port checks** - verify that a host and port are reachable (databases, SSH, custom services).
- **SSL certificate expiry** - get a warning when a certificate has fewer than 21 days left, and an alert when it has expired.
- **Menu bar dashboard** - a clean status panel showing every check with live status, last result, and response time.
- **Configurable schedule** - run checks every 1 to 60 minutes, plus on-demand refresh.
- **Launch at login** - one toggle and InfraCheck starts with your Mac.
- **Native and lightweight** - pure SwiftUI, no Electron, no background daemons, under 1 MB.

## Installation

### Option 1 - Download the app

1. Grab the latest `InfraCheck.app.zip` from the [Releases](../../releases) page.
2. Unzip it and drag `InfraCheck.app` into your **Applications** folder.
3. First launch: **right-click the app > Open > Open**. This is required once because the app is not notarized by Apple.

### Option 2 - Build from source

Requirements: **macOS 14+** and **Xcode 16+**.

```bash
git clone https://github.com/Resha777/InfraCheck.git
cd InfraCheck
open InfraCheck.xcodeproj
```

Press **Cmd+R** to build and run, or **Product > Archive** to export a standalone app.

## Usage

1. Launch InfraCheck - the icon appears in your menu bar (there is no Dock icon).
2. Click the icon > **Manage Checks** > **Add Check**.
3. Choose a check type and enter the target:

| Type | Target example | What it verifies |
|------|----------------|------------------|
| HTTP/HTTPS | `https://api.example.com/health` | Endpoint responds with 2xx/3xx |
| TCP Port | `db.example.com` + port `5432` | Port accepts connections |
| SSL Certificate | `https://example.com` | Certificate validity and days remaining |

4. Set the check interval and enable **Launch at login** in the footer of the Manage Checks window.

### Menu bar icon states

| Icon | Meaning |
|------|---------|
| Check mark | All checks passing |
| Warning triangle | At least one warning (e.g. certificate expiring soon, auth required) |
| Red octagon | At least one check failing |
| Dashed circle | No checks configured / first run pending |

## Security & privacy

- Credentials are stored **only in the macOS Keychain**, never in files or preferences.
- Check definitions are stored in the app's local preferences.
- InfraCheck talks only to the endpoints you configure. No analytics, no telemetry, no third-party services.

## Contributing

Issues and pull requests are welcome. For larger changes, please open an issue first to discuss the approach.

## License

[MIT](LICENSE)
