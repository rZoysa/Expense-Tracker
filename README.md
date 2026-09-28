# Expense Tracker

A clean, responsive Flutter expense-tracking application built for the **CyphLab Flutter Developer Internship technical assessment**.

The app helps users record day-to-day expenses, review monthly spending, search and filter transaction history, and understand category-wise spending through a simple dashboard. Expenses are stored in Firebase Cloud Firestore, with optional account sign-in so users can access their expenses across devices.

## Demo

- 🎥 Screen recording: [View demo](https://drive.google.com/file/d/1SrYYXu90zvZ8oUfPOuiWTyO-yKpGIJ44/view?usp=sharing)
- 📱 Release APK: [Download APK](https://drive.google.com/file/d/1CBwQBQ_R2IVx4Sx3iRjHYHrQ12kWzqaf/view?usp=drive_link)

## Features

### Core requirements

- Add expenses with **title, amount, category, date, and optional note**
- Edit existing expenses
- Delete expenses
- Select an expense category
- Store expenses in **Firebase Cloud Firestore**
- Display the total expenses for the selected/current month
- Show expense history with month, date, and all-time views
- Filter expenses by category and date
- Validate expense form input
- Handle loading, empty, and error states

### Additional features implemented

- Dashboard with a category spending donut chart
- Monthly/category-wise spending summary
- Search transactions by title, note, or category
- Month, specific-date, and All time transaction scopes
- Firestore cursor pagination for All time history
- Transaction Details screen with note and timestamps
- Slide-to-confirm deletion using `slide_to_act`
- 5-second Undo after deletion
- Skeleton loading states for data-dependent content
- Anonymous-first Firebase Authentication
- Create an email/password account while preserving current guest expenses
- Sign in to an existing account and access its expenses across devices
- Email verification and password reset
- Sign out back to a fresh guest session
- Persistent **System / Light / Dark** theme preference
- Material 3 interface with responsive sizing
- Animated extended/collapsed transaction FAB
- Unit tests for expense and theme ViewModels

## Main screens

- **Dashboard** — selected-month total, category spending chart, recent expenses, and quick add action
- **Transactions** — search, Month / Date / All time scopes, category filters, paginated history, and transaction navigation
- **Transaction Details** — amount, category, date, note, created/updated timestamps, and edit access
- **Add / Edit Expense** — validated expense form with category, date, note, and destructive delete flow for existing expenses
- **Profile** — account access, verification/reset flows, sign out, and theme settings

## Architecture

The project uses a lightweight **MVVM + Repository** structure. `provider` is used for dependency injection and exposing `ChangeNotifier` state to the UI; it is not treated as a separate architectural layer.

```text
Views
  ↓ observe / trigger actions
ViewModels (ChangeNotifier)
  ↓
Repository abstraction
  ↓
FirebaseExpenseRepository
  ↓
Firebase Authentication + Cloud Firestore

Provider → dependency injection and state exposure
```

Firebase-specific data access stays inside repository/service classes. ViewModels depend on abstractions rather than calling Firestore directly, which keeps business logic easier to test with fake repositories.

## Project structure

```text
lib/
├── app/             # App theme and authenticated expense scope
├── extensions/      # Expense category presentation helpers
├── models/          # Expense and UI/domain models
├── repositories/    # Repository contract and Firebase implementation
├── services/        # Authentication and theme preference services
├── utils/           # Formatting utilities
├── viewmodels/      # ChangeNotifier presentation/business state
├── views/           # Dashboard, transactions, details, forms, profile
├── firebase_options.dart
└── main.dart

test/
├── fakes/           # Fake repository used by unit tests
└── viewmodels/      # ViewModel tests
```

## Technologies and packages

| Technology / package | Purpose                                               |
| -------------------- | ----------------------------------------------------- |
| Flutter / Dart       | Mobile application framework and language             |
| `provider`           | Dependency injection and ViewModel state exposure     |
| `firebase_core`      | Firebase initialization                               |
| `cloud_firestore`    | Expense persistence, realtime queries, and pagination |
| `firebase_auth`      | Anonymous and email/password authentication           |
| `flutter_screenutil` | Responsive dimensions and spacing                     |
| `fl_chart`           | Category spending donut chart                         |
| `skeletonizer`       | Skeleton loading states                               |
| `slide_to_act`       | Slide-to-confirm destructive deletion                 |
| `shared_preferences` | Persistent theme preference                           |
| `intl`               | Currency and date formatting                          |

See `pubspec.yaml` for the exact versions used by this project.

## Quick start

### Prerequisites

- Flutter stable SDK
- Android Studio / Android SDK or another supported Flutter development environment

Verify your Flutter installation:

```bash
flutter doctor
```

### 1. Clone the repository

```bash
git clone <https://github.com/rZoysa/Expense-Tracker.git>
cd expense_tracker
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the app

The submitted project already contains the FlutterFire configuration used for the assessment environment.

```bash
flutter run
```

## Firebase configuration

Expenses are stored under the authenticated user's document path:

```text
users/{uid}/expenses/{expenseId}
```

Each expense stores:

```text
title
amount
category
date
note
createdAt
updatedAt
```

The repository uses bounded realtime Firestore queries for Month/Date views and cursor pagination for the All time view.

### Firestore security

The version-controlled rules restrict users to their own expense documents:

```text
firestore.rules
firestore.indexes.json
```

The **All time + category** query requires the composite `expenses` index defined in `firestore.indexes.json`:

```text
category ASC
date DESC
document ID DESC
```

Firestore index creation is asynchronous, so the index must reach **Enabled** status before that query can be used.

### Using your own Firebase project

To run the app against a different Firebase project:

1. Create/select a Firebase project.
2. Enable:
   - Authentication → Anonymous
   - Authentication → Email/Password
   - Cloud Firestore
3. Install/login to the Firebase CLI and FlutterFire CLI.
4. Configure the local project.

```bash
firebase login
firebase use --add
dart pub global activate flutterfire_cli
flutterfire configure
```

Then deploy the version-controlled Firestore rules and indexes:

```bash
firebase deploy --only firestore
```

Or deploy only indexes when needed:

```bash
firebase deploy --only firestore:indexes
```

`firebase use --add` creates a local `.firebaserc` alias. This repository ignores that file because the assessment repository is public.

## Testing and quality checks

ViewModel tests use a fake `ExpenseRepository`, so the unit-test suite does not require a live Firebase project.

Covered behavior includes:

- Expense create/update/delete success and error paths
- Expense validation
- Monthly totals and category summaries
- Month, date, category, and search filtering
- All time pagination and end-of-list behavior
- Pagination and realtime stream errors
- Dashboard state isolation from transaction filters
- Undo/restore behavior
- Theme preference behavior

Run formatting, static analysis, and tests with:

```bash
dart format lib test
flutter analyze
flutter test
```

## Release APK

Build an Android release APK with:

```bash
flutter build apk --release
```

The generated APK is placed under:

```text
build/app/outputs/flutter-apk/
```

For architecture-specific APKs:

```bash
flutter build apk --split-per-abi
```

## Known limitations

- In **All time** mode, text search applies to pages that have already been loaded. Loading more pages extends the searchable history without downloading the entire dataset at once.
- Creating a new account from guest mode preserves the current user's expenses. Signing into a different existing account switches to that account's data rather than merging the two datasets.
- Currency is currently fixed to **LKR (Sri Lankan Rupee)**.

## AI tools used

**ChatGPT (OpenAI)** was used as a development assistant for:

- planning the implementation into manageable milestones
- architecture discussions and code reviews
- checking current Flutter/Firebase/package APIs before implementation
- identifying edge cases and implementation trade-offs
- debugging runtime and test failures
- reviewing UI/UX decisions and user-facing copy
- generating and refining unit-test scenarios
- README/documentation preparation

AI-generated suggestions were reviewed, adapted, tested, and understood before being included. The submitted code was manually reviewed and validated with Flutter static analysis, automated tests, and application testing.
