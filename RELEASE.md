# Release Guide

## Building the APK Locally

### Prerequisites

- Flutter SDK (stable channel) — [install guide](https://docs.flutter.dev/get-started/install)
- Java 17 LTS (Java 25+ causes Kotlin compiler incompatibilities)
- Android SDK with build-tools

```bash
# Verify setup
flutter doctor -v
java -version  # must be 17 or 21
```

### Local Debug Build

```bash
flutter pub get
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Local Release Build (requires signing config)

```bash
flutter pub get
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

> The repository currently builds a **debug-signed APK** in CI (signed with the Android debug key).
> Debug APKs can be sideloaded on any Android device with "Install unknown apps" enabled.

---

## Cutting a Release

### Via GitHub Actions (recommended)

1. Ensure all changes are merged to `main`.
2. Create and push a version tag:

   ```bash
   git tag v1.2.3
   git push origin v1.2.3
   ```

3. The **Build Release APK** workflow triggers automatically on `v*` tags.
4. It builds a debug APK, creates a GitHub Release, and attaches the APK.
5. The release appears at: `https://github.com/donniebrasc/zero_touch_car_diagnostics_vs2/releases`

You can also trigger a build manually from the **Actions** tab → **Build Release APK** → **Run workflow**.

---

## CI/CD Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `dart.yml` | push/PR to `main` | Flutter analysis + tests |
| `build-release.yml` | tag `v*` or manual dispatch | Build APK + create GitHub Release |
| `debug-ci.yml` | push to `main` | Environment debug info |

---

## Release Signing (Optional)

The current CI builds use the Android **debug key**, which is sufficient for sideloading.
To produce a release-signed APK for Google Play, add these GitHub Secrets and update `android/app/build.gradle.kts`:

| Secret | Description |
|--------|-------------|
| `KEYSTORE_BASE64` | Base64-encoded `.jks` keystore file |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias within the keystore |
| `KEY_PASSWORD` | Key password |

Then in CI, decode the keystore and pass signing flags to `flutter build apk --release`.

---

## Configuring the App

After installing the APK:

1. Open **Settings** (gear icon in the top-right).
2. Enter your **Gemini API key** (get one free at [Google AI Studio](https://aistudio.google.com/)).
3. Select the Gemini model (default: `gemini-2.5-pro`).
4. Return to the dashboard and connect to your OBD-II adapter.
