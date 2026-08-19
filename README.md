# Mama Brain

A Flutter family health tracking app for logging medications, symptoms and medical
history. Data lives in Firebase Firestore (with an offline cache), sign-in is via
Google, and families share data through invite-code-based groups.

---

## Building a release APK and installing it on a phone

This is the flow for getting a new build onto a family member's phone.

### 1. Bump the version

In [`pubspec.yaml`](pubspec.yaml):

```yaml
version: 1.0.0+1    # -> 1.0.1+2
```

The number **after the `+`** (the versionCode) **must be higher** than the one
already installed, or Android refuses the install. The part before the `+` is the
human-readable version name.

### 2. Build the signed APK

```bash
flutter build apk --release
```

The APK is written to:

```
build/app/outputs/flutter-apk/app-release.apk
```

Expect it to take a few minutes and come out around 55 MB. It is a "fat" APK
containing every CPU architecture, which is what you want for sideloading.

### 3. Upload it to Google Drive

Drag `app-release.apk` into [drive.google.com](https://drive.google.com), then
**right-click the file -> Share -> Copy link** and send that link. Make sure link
access is set so the recipient can actually open it.

### 4. Install it on the phone

1. Open the link (or the Drive app) on the phone and tap the APK to **download** it.
2. Tap the downloaded file. Android will ask to **allow installs from this source** —
   enable it for Drive/Files. This is a one-time prompt per app.
3. Tap **Install**.

Because the APK is signed with the same release key and has a higher versionCode,
it installs **over** the previous version as an update, so all app data is kept.

### Signing notes

Release signing is already configured: [`android/app/build.gradle.kts`](android/app/build.gradle.kts)
reads `android/key.properties`, which points at the keystore.

> **`key.properties` and `*.jks` / `*.keystore` are gitignored and exist only on
> this machine.** Never commit or upload them. If they are lost, you can no longer
> ship updates that install over the existing app — a new key means a different
> app signature, forcing an uninstall/reinstall and wiping local data. Back them up
> somewhere safe and private.

---

## Development

```bash
flutter pub get          # install dependencies
flutter run              # run on the default device
flutter devices          # list connected devices
flutter emulators --launch Pixel_8   # start the Android emulator
```

**Run on Android, not Chrome.** Google Sign-In needs an OAuth client ID that is
only configured for Android (via `android/app/google-services.json`). On web you
will hit a `ClientID not set` error unless a web client ID is added to
`web/index.html`.

### Quality checks

```bash
flutter analyze          # static analysis
flutter test             # run all tests
flutter test test/features/history/logic/history_grouping_test.dart   # a single file
```

Both should be clean before committing.

### Other useful commands

```bash
dart format lib test                 # format code
dart run flutter_launcher_icons      # regenerate launcher icons
dart run flutter_native_splash:create # regenerate the splash screen
firebase deploy --only firestore:rules  # deploy Firestore security rules
```

---

## Project layout

Source lives under `lib/src/`, organised by feature, each with `logic/` (Riverpod
providers) and `ui/` (widgets):

| Path | Purpose |
| --- | --- |
| `core/models/` | Data models with Firestore serialization |
| `core/theme/` | Material 3 theme |
| `core/prefs/` | Small on-device preferences (e.g. last visited tab) |
| `features/auth/` | Google Sign-In and the app user |
| `features/group/` | Family groups and invite codes |
| `features/family/` | Family members (add, edit, reorder, delete) |
| `features/medications/` | Medication tracking |
| `features/symptoms/` | Symptom logging |
| `features/history/` | Calendar history view |
| `features/home/` | Medications tab |
| `features/settings/` | Settings sheet (shows the invite code) |

Tests mirror this structure under `test/`.

See [`CLAUDE.md`](CLAUDE.md) for the fuller architecture notes, Firestore data
model and conventions.

---

## Recovering access to a family

All medications, symptoms and family members belong to the **family group**, not to
your account, so signing in again never loses them.

If the app shows the Family Setup screen instead of your data:

1. Check the account shown at the top of that screen — signing in with a different
   Google account is the most common cause. Use **Use a different account** to switch.
2. Get the invite code from a family member who is already in the group
   (**Settings ⚙ -> Invite code**, with a copy button).
3. Enter it under **Join your family**. Your shared history reappears.

## Git workflow

Branch off `main` for any change:

```bash
git checkout -b feature/short-description   # or fix/short-description
```

Run `flutter analyze` and `flutter test`, commit, push, and open a pull request.
