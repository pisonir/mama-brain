# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mama Brain is a Flutter family health tracking app for logging medications, symptoms, and medical history. It uses a local-first architecture with Hive for persistence and Riverpod for state management.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run code generation (Hive adapters & Riverpod providers)
dart run build_runner build
dart run build_runner watch          # continuous rebuild on file changes

# Run all tests
flutter test

# Run a single test file
flutter test test/features/medications/logic/date_provider_test.dart

# Static analysis
flutter analyze

# Generate launcher icons / splash screen
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Architecture

**Pattern:** Feature-based organization with Riverpod state management and Hive local database.

### Source Layout (`lib/src/`)

- **`core/models/`** — Hive-annotated data models (`FamilyMember`, `Medication`, `Symptom`). Each model uses `@HiveType`/`@HiveField` annotations and has a generated adapter. When adding or modifying model fields, run `dart run build_runner build` to regenerate adapters.
- **`core/theme/`** — `AppTheme` class defining Material 3 theme with Nunito font and pastel color palette.
- **`features/`** — Each feature has `logic/` (Riverpod providers) and `ui/` (widgets) subdirectories:
  - **`family/`** — Family member CRUD, avatar row with colored circles
  - **`medications/`** — Medication tracking with date strip, daily filtering, duration logic (one-off / temporary / permanent)
  - **`symptoms/`** — Symptom logging (fever, cough, vomit, pain, rash, other) with flexible `Map<String, dynamic>` data
  - **`history/`** — Calendar view aggregating medications and symptoms via `HistoryEvent`
  - **`home/`** — Main medications tab composing date strip + family row + medication list

### State Management

- **`StateNotifierProvider`** for mutable collections (family members, medications, symptoms) — these read from and write to Hive boxes.
- **`Provider`** for derived/computed state (e.g., `dailyMedicationsProvider` filters by selected date and family member).
- **`StateProvider`** for simple UI state (e.g., selected date).
- Widgets extend `ConsumerWidget` or use `ConsumerState` for Riverpod access.

### Database (Hive)

Three boxes opened at startup in `main.dart`: `family_members`, `medications`, `symptoms`. All adapter registrations happen before `runApp()`. When adding a new model, register its adapter in `main.dart` and open a box for it.

### Navigation

Bottom navigation bar in `MainScreen` with three tabs: Medications, Symptoms, History. New-item flows use modal bottom sheets; family member creation uses a dialog.

## Key Conventions

- Dates are normalized to midnight (year/month/day only) for grouping and comparison.
- Every entity gets a UUID string as its ID via the `uuid` package.
- Family member colors are stored as `int` values and converted to `Color` objects in the UI.
- Medication duration types: `oneOff` (single day), `temporary` (start + duration days), `permanent` (start date onward indefinitely).

## Testing

Unit tests live in `test/features/`, mirroring the source layout. Run all with `flutter test`.

### Test Layout

- **`test/helpers/hive_test_helper.dart`** — Shared Hive setUp/tearDown: creates a temp directory, initializes Hive, registers all adapters (with `isAdapterRegistered` guards), and cleans up after each test.
- **`test/helpers/fake_notifiers.dart`** — `FakeFamilyNotifier`, `FakeMedicationNotifier`, `FakeSymptomNotifier` that extend the real notifier classes but override load methods to inject state without touching Hive. Used with `ProviderContainer` overrides for derived-provider tests.
- **`test/features/family/logic/`** — `FamilyNotifier` CRUD tests (Hive-backed).
- **`test/features/medications/logic/`** — `MedicationNotifier` CRUD + `toggleTaken` tests (Hive-backed), `dailyMedicationsProvider` filtering tests (fake overrides), `getWeekDatesFrom` + date StateProvider tests (pure).
- **`test/features/symptoms/logic/`** — `SymptomNotifier` CRUD tests (Hive-backed), `dailySymptomProvider` filtering/sorting tests (fake overrides).
- **`test/features/history/logic/`** — `historyEventsProvider` tests covering symptom events, oneOff/temporary/permanent medication event generation, and mixed-event grouping (fake overrides).

### Writing New Tests

- **Hive-backed tests** (testing notifiers directly): use `setUpHive()` / `tearDownHive()` from `hive_test_helper.dart` and open the required box before creating a notifier.
- **Derived-provider tests** (testing computed providers): create a `ProviderContainer` with `overrideWith` using the fake notifiers from `fake_notifiers.dart` — no Hive setup needed.
- **`toggleTaken` caveat**: the method logs `DateTime.now()` when toggling on, so tests that toggle off must use today's date for the day-match comparison to work.
