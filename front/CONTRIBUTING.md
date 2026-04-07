# Contributing — Flutter (`front/`)

> Flutter-specific contributing guide. Global rules (commit signing, branch naming): see [`../CONTRIBUTING.md`](../CONTRIBUTING.md).

All commands below are run from `front/` unless stated otherwise.

---

## Prerequisites

- Flutter SDK — exact version in `front/.flutter-version` at repo root
- Xcode (macOS, for iOS builds)
- Android Studio / Java 17 (for Android builds)

---

## Upgrading Flutter

The required Flutter version is defined in a single place: **`.flutter-version`** (in `front/`).
All CI workflows read from this file via `flutter-version-file: front/.flutter-version`.

To upgrade:
1. Update `.flutter-version` with the new version (e.g. `3.42.0`)
2. Run `flutter upgrade` locally and verify `flutter --version` matches
3. Regenerate golden screenshots (rendering may change between Flutter versions):
   - either locally: `flutter test test/golden/ --update-goldens --tags golden`
   - or via the "Update Golden Screenshots" GitHub Actions workflow
4. Open a PR — CI will use the new version automatically

---

## Quick Reference

```bash
# Install dependencies
flutter pub get

# Analyze
flutter analyze --fatal-infos

# Unit + widget tests (excludes golden tests)
flutter test test/ --exclude-tags golden

# Golden tests (macOS only)
flutter test test/golden/ --tags golden

# Regenerate code (Freezed, etc.) after model changes
dart run build_runner build --delete-conflicting-outputs

# Run with secrets
flutter run --dart-define-from-file=secrets.json
```

---

## Local secrets setup

Secrets are injected at build/run time via `--dart-define-from-file=secrets.json`. The file is gitignored — never commit it.

```bash
cp secrets.json.example secrets.json
# then fill in the values
```

```json
{
  "ADK_BASE_URL": "https://your-cloud-run-url.run.app"
}
```

| Key | Where to get it |
|-----|----------------|
| `ADK_BASE_URL` | Cloud Run service URL (once `agent/` is deployed) |

---

## Run locally

Use the provided IntelliJ/Android Studio run configuration **`App`** (in `front/.run/`), or run directly:

```bash
flutter run --dart-define-from-file=secrets.json
```

### iOS device signing setup (local only)

The CI signs with the org Apple Developer account. To run on a physical device locally you need your own Apple Developer account connected to Xcode.

**One-time setup:**
```bash
cp dev.env.example dev.env
# Fill in your Apple Team ID (developer.apple.com/account → Membership → Team ID)
```

```bash
make dev-setup
```

This will:
1. Patch `project.pbxproj` with your personal team ID and bundle ID (`com.<your-username>.alzheimerAssistant`)
2. Mark `project.pbxproj` and `Podfile.lock` as `skip-worktree` so git ignores your local changes

#### Updating `project.pbxproj` or `Podfile.lock`

When you need to make a legitimate change to either file (new dependency, Xcode setting, etc.):

```bash
make dev-reset   # removes skip-worktree and restores committed versions
# ... make your changes ...
git add ios/... && git commit
make dev-setup   # re-applies local dev signing
```

---

## E2E Tests (local)

E2E tests live in `integration_test/app_e2e_test.dart`. All platform-specific services (STT, TTS, phone) are replaced by in-memory fakes, so no real device permissions or network access are required.

### Prerequisites (all platforms)

```bash
cp secrets.json.example secrets.json
# Fill in ADK_BASE_URL (and ElevenLabs keys if needed) — dummy values work for E2E
```

### iOS Simulator

**Requirements:** macOS + Xcode

```bash
# 1. List available simulators and pick one
xcrun simctl list devices available

# 2. Boot the simulator (replace <UDID> with the value from step 1)
xcrun simctl boot <UDID>
open -a Simulator --args -CurrentDeviceUDID <UDID>
xcrun simctl bootstatus <UDID> -b

# 3. Disable auto-lock (prevents VM service connection failure during build)
xcrun simctl spawn <UDID> defaults write com.apple.springboard SBAutoLockTime -1

# 4. Run E2E tests
flutter test integration_test/app_e2e_test.dart \
  -d <UDID> \
  --dart-define-from-file=secrets.json
```

> **Tip:** `flutter devices` shows all booted simulators with their UDIDs.

### Android Emulator

**Requirements:** Android Studio + an AVD (API 34, x86_64 recommended)

```bash
# 1. Start the emulator from Android Studio, or via CLI:
$ANDROID_HOME/emulator/emulator -avd <avd-name> -no-snapshot &

# 2. Wait for it to be ready
adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done'

# 3. Run E2E tests (emulator always appears as emulator-5554)
flutter test integration_test/app_e2e_test.dart \
  -d emulator-5554 \
  --dart-define-from-file=secrets.json
```

> **Tip:** `flutter devices` confirms the emulator is detected. `adb devices` lists connected emulators.

### Web (Chrome)

**Requirements:** Google Chrome + ChromeDriver (same major version as Chrome)

```bash
# 1. Check Chrome version
google-chrome --version   # Linux
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version  # macOS

# 2. Download the matching ChromeDriver from https://googlechromelabs.github.io/chrome-for-testing/
#    and place it on your PATH, or use the system-installed one (ubuntu ships one)

# 3. Start ChromeDriver on port 4444
chromedriver --port=4444 &

# 4. Run E2E tests via flutter drive (flutter test -d chrome is not supported for integration tests)
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_e2e_test.dart \
  -d web-server \
  --dart-define-from-file=secrets.json
```

> Pass `--headless` to run without opening a browser window.

---

## SonarCloud (local)

To run only the front checks and sonar upload:

```bash
./gradlew :front:frontSonar
```

---

## CI/CD

Five GitHub Actions workflows are defined under `.github/workflows/`:

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `front-ci` | push/PR on `front/**` | Analyze, unit+widget tests, golden tests (macOS), build Android APK + iOS (no codesign) |
| `front-e2e` | push/PR on `front/**` | E2E tests on iOS simulator, Android emulator, Chrome |
| `front-update-goldens` | Manual | Regenerates golden screenshots and commits them |
| `sonar` | push/PR on `front/**` or `.github/**` | SonarCloud analysis (Dart coverage + GitHub Actions IaC) |
| `front-testflight` | push on `v*.*` tags or manual | Build signed iOS IPA and upload to TestFlight |

### GitHub Secrets required

| Secret | Used by | Description |
|--------|---------|-------------|
| `ADK_BASE_URL` | front-ci, front-e2e, front-testflight | ADK agent WebSocket base URL |
| `SONAR_TOKEN` | sonar | SonarCloud authentication |
| `GRADLE_ENCRYPTION_KEY` | sonar | Gradle cache encryption |
| `APPLE_CERTIFICATE_BASE64` | front-testflight | Distribution certificate (.p12, base64-encoded) |
| `APPLE_CERTIFICATE_PASSWORD` | front-testflight | Password for the .p12 certificate |
| `APP_STORE_CONNECT_API_KEY_ID` | front-testflight | App Store Connect API key ID |
| `APP_STORE_CONNECT_API_KEY_BASE64` | front-testflight | App Store Connect API key (.p8, base64-encoded) |
| `APP_STORE_CONNECT_ISSUER_ID` | front-testflight | App Store Connect issuer ID |
| `APPLE_TEAM_ID` | front-testflight | Apple Developer Team ID |

---

## TestFlight releases

### Automated (recommended)

Push a tag matching `v*.*` to trigger the `front-testflight` workflow automatically:

```bash
git tag v1.2
git push origin v1.2
```

The workflow will:
1. Import the distribution certificate into a temporary keychain
2. Build the Flutter app (release, no codesign)
3. Archive and export the IPA via `xcodebuild` with automatic signing (`-allowProvisioningUpdates`)
4. Upload the IPA to TestFlight via `xcrun altool`
5. Delete the temporary keychain (always, even on failure)

### Manual

Go to **Actions → Front — TestFlight Distribution → Run workflow**.

### Signing setup

The workflow uses **automatic signing** (`CODE_SIGN_STYLE=Automatic`) with an App Store Connect API key. Xcode fetches and manages provisioning profiles automatically at archive time — no manual profile management needed.

To set up signing for a new environment:
1. Export your Apple Distribution certificate as `.p12` from Keychain Access
2. Base64-encode it: `base64 -i cert.p12 | pbcopy`
3. Add `APPLE_CERTIFICATE_BASE64` and `APPLE_CERTIFICATE_PASSWORD` as GitHub secrets
4. Create an App Store Connect API key (Admin role) at [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → Users and Access → Keys
5. Base64-encode the `.p8` key file and add `APP_STORE_CONNECT_API_KEY_BASE64`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID` as secrets

---

## Golden screenshot tests

Golden tests are screenshot regression tests for the Flutter UI. They run on **macOS only** (text rendering differs between Linux and macOS).

### When goldens need to be updated

- After UI changes (layout, colors, fonts, widget structure)
- After upgrading Flutter or any rendering-related package
- The `front-ci` workflow will fail with a diff artifact showing what changed

### How to update goldens

**Option 1 — via GitHub Actions (recommended):**

Go to **Actions → Front — Update Golden Screenshots → Run workflow**.

Select the branch to target (e.g. `main` or your feature branch) in the **Branch** dropdown, then click **Run workflow**.

The workflow runs on macOS, regenerates all goldens, then creates a verified commit via the GitHub API (required because direct pushes must be signed and the repo enforces branch protection). The commit lands on a new `chore/update-goldens-<origin-branch>-<timestamp>` branch, and a PR is opened targeting the branch you selected. Review and merge the PR normally.

> **Required secret:** The workflow uses `GH_PAT` (a Personal Access Token with `repo` + `workflow` scopes) instead of `GITHUB_TOKEN`. This is necessary because PRs created with `GITHUB_TOKEN` do not trigger other workflows — so CI would never run on the golden update PR. Add the PAT under **Settings → Secrets and variables → Actions → New repository secret**, name it `GH_PAT`.

**Option 2 — locally (macOS required):**

```bash
flutter test test/golden/ --update-goldens --tags golden
git add test/golden/goldens/
git commit -m "chore: update golden screenshots"
```

### Inspecting failures

When golden tests fail in CI, the workflow uploads a `golden-failures` artifact (retained 7 days) containing the diff images. Download it from the **Actions** run summary to decide whether the change is a regression or an intentional UI update.

### Golden file location

```
test/golden/goldens/   ← committed reference images
test/golden/failures/  ← generated diffs on failure (not committed)
```
