# Expense Tracker

A responsive Flutter expense-tracking app built for the CyphLab Flutter Developer Internship technical assessment.

The app supports guest usage through Firebase Anonymous Authentication and lets a guest upgrade the same Firebase account to email/password authentication without losing existing expenses. Expenses are stored in Cloud Firestore and scoped to the authenticated Firebase UID.

## Features

### Core requirements

- Add expenses with title, amount, category, date, and optional note
- Edit existing expenses
- Delete expenses with a 5-second Undo action
- Expense categories
- Firebase Cloud Firestore persistence
- Current/selected month expense total
- Expense history
- Month, specific-date, all-time, and category filtering
- Transaction search by title, note, or category
- Form validation
- Skeleton loading, empty, and error states
- Responsive UI using `flutter_screenutil`

### Additional features

- Dashboard category spending donut chart
- All-time Firestore cursor pagination (20 expenses per page)
- Anonymous-first Firebase Authentication
- Upgrade guest account to email/password while preserving the same UID and data
- Existing-account sign in
- Email verification
- Password reset
- Sign out back to a fresh anonymous session
- Persistent System / Light / Dark theme preference
- Material 3 UI
- Unit tests for expense and theme ViewModels

## App structure

The project follows MVVM with a repository abstraction:

```text
UI / Views
    ↓
Provider
    ↓
ViewModels (ChangeNotifier)
    ↓
ExpenseRepository
    ↓
FirebaseExpenseRepository
    ↓
Firebase Auth + Cloud Firestore
```

Firebase-specific data access is kept inside the repository/service layer. ViewModels depend on abstractions rather than calling Firestore directly, which keeps application logic testable with fake repositories.

## Main screens

- **Dashboard** — selected-month total, category summary chart, and recent expenses
- **Transactions** — search, Month / Date / All time scopes, category filtering, pagination, edit/delete actions
- **Profile** — guest/account state, account creation/sign-in, verification/reset flows, and theme settings

## Technologies and packages

- Flutter / Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Provider
- flutter_screenutil
- fl_chart
- skeletonizer
- slide_to_act
- shared_preferences
- intl

See `pubspec.yaml` for the exact package versions used by this project.

## Firebase data model

Expenses are stored per authenticated user:

```text
users/{uid}/expenses/{expenseId}
```

Each expense contains:

```text
title
amount
category
date
note
createdAt
updatedAt
```

The repository uses bounded realtime Firestore queries for month/date views and cursor pagination for the All time view.

## Firebase security

Firestore access is restricted so an authenticated user can only read and write expenses under their own UID path. The rules and required Firestore composite indexes are version-controlled in:

```text
firestore.rules
firestore.indexes.json
```

If you previously edited Firestore rules in the Firebase Console, copy those rules into `firestore.rules` before deploying; a Firebase CLI rules deployment replaces the deployed rules with the version in this repository.

Deploy the version-controlled Firestore configuration with:

```bash
firebase deploy --only firestore
```

If only the composite indexes changed, deploy just the indexes:

```bash
firebase deploy --only firestore:indexes
```

The **All time + category** query requires the composite `expenses` index defined in
`firestore.indexes.json` (`category ASC`, `date DESC`, document ID DESC). Index
creation is asynchronous, so wait until its status is **Enabled** in the Firebase
Console before testing that filter.

## Setup

### Prerequisites

Install:

- Flutter stable SDK
- Dart (included with Flutter)
- Firebase CLI
- FlutterFire CLI
- Android Studio / Android SDK for Android builds

Verify Flutter first:

```bash
flutter doctor
```

### 1. Clone the repository

```bash
git clone <repository-url>
cd expense_tracker
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Create or select a Firebase project and enable:

- **Authentication → Anonymous**
- **Authentication → Email/Password**
- **Cloud Firestore**

Log in and configure FlutterFire:

```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates/updates `lib/firebase_options.dart` and platform Firebase configuration.

Deploy Firestore rules and indexes:

```bash
firebase deploy --only firestore
```

### 4. Run the app

```bash
flutter run
```

## Quality checks

Before committing or creating a release build:

```bash
dart format lib test
flutter analyze
flutter test
```

## Tests

The test suite focuses on ViewModel behavior using a fake `ExpenseRepository`, so unit tests do not depend on a live Firebase project.

Covered behavior includes:

- Expense creation/edit/delete error and success paths
- Monthly totals and category summaries
- Search and category filters
- Specific-date filtering
- All-time pagination
- Pagination errors and end-of-list behavior
- Dashboard state isolation from transaction filters
- Theme preference persistence

Run all tests with:

```bash
flutter test
```

## Release APK

For assessment distribution, build a release APK with:

```bash
flutter build apk --release
```

The APK is generated under:

```text
build/app/outputs/flutter-apk/
```

For smaller architecture-specific APKs:

```bash
flutter build apk --split-per-abi
```

Before a production/store release, configure a unique application ID and production signing key. Do not commit signing keys or `android/key.properties`.

## Known limitations

- When **All time** pagination is active, text search applies to the pages currently loaded. Load additional pages to search older transactions.
- Signing into an already-existing account does not merge the current guest account's expenses into that account. Guest → new email/password account linking preserves the same UID and therefore preserves data automatically.
- Currency is currently fixed to LKR.

## AI tools used

**ChatGPT (OpenAI)** was used during development for:

- planning and breaking the assessment into milestones
- architecture discussions and code reviews
- reviewing current Flutter/Firebase API usage
- identifying edge cases and implementation tradeoffs
- generating/refining unit-test scenarios
- debugging assistance
- README/documentation preparation

AI suggestions were reviewed, adapted, tested, and understood before being included. The submitted code was validated with Flutter analysis, automated tests, and manual application testing.

## Submission checklist

- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Firebase rules/indexes deployed
- [ ] Core flows manually tested on a physical device/emulator
- [ ] Release APK built and installed successfully
- [ ] GitHub repository is public
- [ ] Screen recording uploaded with public/view access
- [ ] GitHub and recording links ready to submit
