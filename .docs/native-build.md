# Building Native Apps (iOS / Android)

Bra! is a PWA wrapped with [Capacitor](https://capacitorjs.com/). The Capacitor
scaffolding (config + `cap:sync` script) is already in the repo. Adding and
building the native platforms requires SDK tooling **not available in CI or
headless environments** — follow the steps below on a local machine.

> **Note:** `@capacitor/android` and `@capacitor/ios` are NOT committed to the
> repo. The `cap add` commands below install them on demand alongside their
> native project scaffolding.

---

## Prerequisites

| Target  | Tooling required |
|---------|-----------------|
| Android | [Android Studio](https://developer.android.com/studio) + Android SDK (API level 22+); `ANDROID_HOME` env var set |
| iOS     | [Xcode](https://developer.apple.com/xcode/) 15+ (macOS only); Xcode Command Line Tools installed |

---

## One-time platform setup (per machine)

Run these commands once to create the native project scaffolding. After that,
only `bun run cap:sync` is needed for subsequent web builds.

```bash
# 1. Build the web app (produces dist/)
bun run build

# 2. Install platform packages
bun add -d @capacitor/android @capacitor/ios

# 3. Scaffold the native projects (creates android/ and ios/ directories)
npx cap add android
npx cap add ios

# 4. Copy dist/ + plugins into the native projects
bun run cap:sync
```

---

## Iterative development (after initial setup)

Each time you change web code, rebuild and sync:

```bash
bun run build
bun run cap:sync
```

---

## Opening in the IDE

```bash
# Open in Android Studio (build + run from there)
npx cap open android

# Open in Xcode (build + run from there, macOS only)
npx cap open ios
```

From Android Studio: select a device/emulator and click **Run**.
From Xcode: select a scheme/device and click **Run** (requires a signing
certificate for physical devices).

---

## Notes

- The `android/` and `ios/` directories produced by `cap add` are **gitignored**
  until you are ready to commit them. Add them to version control once the
  native layer is stable.
- `capacitor.config.ts` (at the repo root) is the single source of truth for
  `appId`, `appName`, and `webDir`. Do not edit these in the native project
  files directly.
- `cap:sync` is safe to run repeatedly; it is idempotent.
- iOS builds require macOS. Android builds can be done on macOS, Linux, or
  Windows (with Android Studio installed).
