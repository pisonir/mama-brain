# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mama Brain is a Flutter family health tracking app for logging medications, symptoms, and medical history. It uses Firebase Firestore for cloud persistence (with offline cache), Google Sign-In for authentication, invite-code-based family groups for multi-device sharing, and Riverpod for state management.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/features/medications/logic/date_provider_test.dart

# Static analysis
flutter analyze

# Generate launcher icons / splash screen
dart run flutter_launcher_icons
dart run flutter_native_splash:create

# Firebase: deploy security rules
firebase deploy --only firestore:rules
```

## Git Workflow

**IMPORTANT:** When implementing user feature requests or fixing issues, ALWAYS create a new branch before modifying code.

```bash
# Create and switch to a new feature branch
git checkout -b feature/description-of-feature

# Create and switch to a new bugfix branch
git checkout -b fix/description-of-bug
```

Branch naming conventions:
- `feature/` prefix for new features (e.g., `feature/add-temperature-tracking`)
- `fix/` prefix for bug fixes (e.g., `fix/medication-toggle-crash`)
- Use lowercase with hyphens for readability

After completing changes:
1. Run `flutter analyze` and `flutter test` to verify code quality
2. Commit changes with descriptive messages
3. Push the branch and create a pull request for review
4. Only merge to `main` after review and approval

## Architecture

**Pattern:** Feature-based organization with Riverpod state management and Firebase Firestore.

### Firestore Data Structure

```
/familyGroups/{groupId}
    createdBy, inviteCode, createdAt
    /members/{memberId}       -- name, colorValue
    /medications/{medId}      -- name, familyMemberId, type, startDate, durationInDays, takenLogs
    /symptoms/{symptomId}     -- familyMemberId, timestamp, type, data, note

/users/{uid}                  -- email, displayName, groupId
/inviteCodes/{code}           -- groupId (fast lookup for join flow)
```

### Source Layout (`lib/src/`)

- **`core/models/`** — Data models (`FamilyMember`, `Medication`, `Symptom`, `FamilyGroup`, `AppUser`). Each model has `toMap()` and `fromDoc(DocumentSnapshot)` for Firestore serialization.
- **`core/firebase/`** — `FirestoreRefs` helper providing typed collection references scoped to the current family group.
- **`core/theme/`** — `AppTheme` class defining Material 3 theme with Nunito font and pastel color palette.
- **`features/`** — Each feature has `logic/` (Riverpod providers) and `ui/` (widgets) subdirectories:
  - **`auth/`** — Google Sign-In, `authStateProvider` (StreamProvider), `appUserProvider` (FutureProvider)
  - **`group/`** — Family group creation/joining with invite codes, `groupIdProvider`
  - **`family/`** — Family member CRUD, avatar row with colored circles
  - **`medications/`** — Medication tracking with date strip, daily filtering, duration logic (one-off / temporary / permanent)
  - **`symptoms/`** — Symptom logging (fever, cough, vomit, pain, rash, other) with flexible `Map<String, dynamic>` data
  - **`history/`** — Calendar view aggregating medications and symptoms via `HistoryEvent`
  - **`home/`** — Main medications tab composing date strip + family row + medication list
  - **`settings/`** — Settings sheet showing user info, invite code, sign out button

### State Management

- **`StateNotifierProvider`** for mutable collections (family members, medications, symptoms) — these subscribe to Firestore snapshot streams and write to Firestore docs. State updates arrive automatically from the snapshot listener.
- **`StreamProvider`** for auth state (`authStateProvider` watching `FirebaseAuth.authStateChanges()`).
- **`FutureProvider`** for user data (`appUserProvider` reading `/users/{uid}` doc).
- **`Provider`** for derived/computed state (e.g., `dailyMedicationsProvider`, `groupIdProvider`).
- **`StateProvider`** for simple UI state (e.g., selected date).
- Widgets extend `ConsumerWidget` or use `ConsumerState` for Riverpod access.

### Database (Firebase Firestore)

Firebase is initialized in `main.dart` via `Firebase.initializeApp()`. Notifiers accept a `groupId` from `groupIdProvider` and an optional `FirebaseFirestore` parameter (for testability with `FakeFirebaseFirestore`). Each notifier subscribes to its collection's snapshots and writes directly to Firestore docs.

### Auth Flow

`app.dart` uses auth-aware routing: signed out → `LoginPage`, signed in but no group → `GroupSetupPage`, has group → `MainScreen`.

### Navigation

Bottom navigation bar in `MainScreen` with three tabs: Medications, Symptoms, History. New-item flows use modal bottom sheets; family member creation uses a dialog. Settings accessible via gear icon in HomePage AppBar.

## Key Conventions

- Dates are normalized to midnight (year/month/day only) for grouping and comparison.
- Every entity gets a UUID string as its ID via the `uuid` package.
- Family member colors are stored as `int` values and converted to `Color` objects in the UI.
- Medication duration types: `oneOff` (single day), `temporary` (start + duration days), `permanent` (start date onward indefinitely).
- Firestore serialization: `DateTime` ↔ `Timestamp`, enums stored as `.name` strings.

## Testing

Unit tests live in `test/features/`, mirroring the source layout. Run all with `flutter test`.

### Test Layout

- **`test/helpers/fake_notifiers.dart`** — `FakeFamilyNotifier`, `FakeMedicationNotifier`, `FakeSymptomNotifier` that extend the real notifier classes using `super.empty()` and override load methods to inject state without touching Firestore. Used with `ProviderContainer` overrides for derived-provider tests.
- **`test/features/family/logic/`** — `FamilyNotifier` CRUD tests (using `FakeFirebaseFirestore`).
- **`test/features/medications/logic/`** — `MedicationNotifier` CRUD + `toggleTaken` tests (using `FakeFirebaseFirestore`), `dailyMedicationsProvider` filtering tests (fake overrides), `getWeekDatesFrom` + date StateProvider tests (pure).
- **`test/features/symptoms/logic/`** — `SymptomNotifier` CRUD tests (using `FakeFirebaseFirestore`), `dailySymptomProvider` filtering/sorting tests (fake overrides).
- **`test/features/history/logic/`** — `historyEventsProvider` tests covering symptom events, oneOff/temporary/permanent medication event generation, and mixed-event grouping (fake overrides).

### Writing New Tests

- **Firestore-backed tests** (testing notifiers directly): create a `FakeFirebaseFirestore` instance and pass it to the notifier constructor along with a test `groupId`. Use `await Future.delayed(Duration.zero)` after writes to let snapshot listeners fire.
- **Derived-provider tests** (testing computed providers): create a `ProviderContainer` with `overrideWith` using the fake notifiers from `fake_notifiers.dart` — no Firestore setup needed.
- **`toggleTaken` caveat**: the method logs `DateTime.now()` when toggling on, so tests that toggle off must use today's date for the day-match comparison to work.
