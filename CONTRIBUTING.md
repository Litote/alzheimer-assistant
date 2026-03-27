# Contributing

## Prerequisites

- Flutter 3.x (stable channel)
- Dart (bundled with Flutter)
- Xcode (macOS, for iOS builds)
- Android Studio / Java 17 (for Android builds)

## Quick Reference

```bash
cd front

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

## Run locally

### Install Android Studio & all

### Local secrets setup

Secrets are injected at build/run time via `--dart-define-from-file=secrets.json`. The file is gitignored — never commit it.

```bash
cp front/secrets.json.example front/secrets.json
# then fill in the values
```

```json
{
  "ADK_BASE_URL": "https://your-cloud-run-url.run.app",
  "ELEVENLABS_API_KEY": "sk_your_api_key_here",
  "ELEVENLABS_VOICE_ID": "your_voice_id_here"
}
```


| Key | Where to get it |
|-----|----------------|
| `ADK_BASE_URL` | Cloud Run service URL (once `agent/` is deployed) |
| `ELEVENLABS_API_KEY` | [elevenlabs.io](https://elevenlabs.io) → Profile → API Keys |
| `ELEVENLABS_VOICE_ID` | ElevenLabs voice library — copy the ID of the chosen voice |

### use provided intellij runner `App` 

---

## Conventional Commits

All PR titles **must** follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Branch naming

```
<type>/<short-kebab-description>

# Examples:
feat/call-disambiguation-flow
fix/stt-locale-fallback
chore/bump-flutter-version
```

| Type | When to use |
|------|-------------|
| `feat:` | New user-facing feature |
| `fix:` | Bug fix |
| `chore:`, `docs:`, `test:`, `refactor:`, `ci:` | Internal changes |

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
| `ADK_BASE_URL` | front-ci, front-e2e, front-testflight | ADK agent base URL |
| `ELEVENLABS_API_KEY` | front-ci, front-e2e, front-testflight | ElevenLabs API key |
| `ELEVENLABS_VOICE_ID` | front-ci, front-e2e, front-testflight | ElevenLabs voice ID |
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

The workflow runs on macOS, regenerates all goldens, and commits them back to the current branch with the message `chore: update N golden screenshot(s) [skip ci]`.

**Option 2 — locally (macOS required):**

```bash
cd front
flutter test test/golden/ --update-goldens --tags golden
git add test/golden/goldens/
git commit -m "chore: update golden screenshots"
```

### Inspecting failures

When golden tests fail in CI, the workflow uploads a `golden-failures` artifact (retained 7 days) containing the diff images. Download it from the **Actions** run summary to decide whether the change is a regression or an intentional UI update.

### Golden file location

```
front/test/golden/goldens/   ← committed reference images
front/test/golden/failures/  ← generated diffs on failure (not committed)
```
