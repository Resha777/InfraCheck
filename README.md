# InfraCheck

InfraCheck is a macOS menu bar application for monitoring infrastructure components and running custom health checks.

## Requirements

- macOS 14 or later (recommended)
- Xcode 16 or later
- Apple Silicon Mac (current version is ARM64)
- An Apple ID configured in Xcode

---

# Getting Started

## 1. Clone the repository

```bash
git clone https://github.com/<YOUR_ORG>/InfraCheck.git
cd InfraCheck
```

or download the ZIP from GitHub and extract it.

---

## 2. Open the project

```bash
open InfraCheck.xcodeproj
```

---

## 3. Configure Signing

Each developer must use their own Apple ID.

In Xcode:

1. Select **InfraCheck** in the Project Navigator.
2. Under **TARGETS**, select **InfraCheck**.
3. Open **Signing & Capabilities**.
4. Enable:

```
Automatically manage signing
```

5. Select your own **Personal Team**.

If you receive:

```
Bundle Identifier already exists
```

change the Bundle Identifier to something unique, for example:

```
com.yourname.InfraCheck
```

---

## 4. Build and Run

Select:

```
My Mac
```

then press

```
⌘ + R
```

or choose:

```
Product → Run
```

The application should compile and launch.

---

# Updating

To receive the latest changes:

```bash
git pull
```

---

# Contributing

After making changes:

```bash
git add .
git commit -m "Describe your changes"
git push
```

---

# Notes

- Do **not** commit `DerivedData`, build output, or user-specific Xcode settings.
- Do **not** commit certificates, API keys, or passwords.
- Use the provided `.gitignore`.

---

# Troubleshooting

## Signing error

Make sure:

- You are signed into Xcode with your Apple ID.
- "Automatically manage signing" is enabled.
- A Personal Team is selected.

---

## Bundle Identifier already exists

Choose a unique Bundle Identifier, for example:

```
com.john.InfraCheck
```

---

## Build fails after pulling

Choose:

```
Product → Clean Build Folder
```

then build again.

---

## Missing Swift Packages

Choose:

```
File → Packages → Resolve Package Versions
```

---

## macOS blocks the application

If Gatekeeper blocks the app after building:

1. Open **System Settings**
2. **Privacy & Security**
3. Click **Open Anyway**

(Usually only required the first time.)
