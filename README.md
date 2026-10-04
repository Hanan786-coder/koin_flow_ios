# Koin Flow

Koin Flow is a local-first personal finance app built with Flutter. It helps
you track everyday expenses, manage a monthly budget, and keep a clear record
of money you owe or expect to receive.

The app is designed for a focused iOS experience while remaining runnable on
any Flutter-supported platform.

## Features

### Expense tracking

- Add expenses with a title, amount, category, and date.
- Search expenses by title or category.
- Filter by category, relative date range, a specific month, or a specific
  date.
- Sort transactions from newest to oldest or oldest to newest.
- Swipe an expense to delete it.
- Review monthly spending and category breakdowns.

### People and balances

- Record money you owe or money owed to you.
- Add an optional due date; balances can be saved without a deadline.
- Search balances by person or note.
- Filter and sort open and settled balances.
- Settle balances directly from the People screen.
- Automatically record an expense when you settle money that you owed.
- Update available funds when a receivable is actually settled.

### Budget management

- Set a monthly budget with the numeric input or slider.
- Use the mobile keyboard's Done action or the confirmation button to save a
  budget.
- View spending, remaining budget, open receivables, and outstanding payments.
- Choose whether existing expenses should count when changing the budget.

### Data controls and feedback

- Delete all expenses from the Expenses screen.
- Delete all people and balances from the People screen.
- Confirm destructive actions before data is removed.
- Receive clear, branded toast messages after additions, settlements, budget
  changes, deletions, and other important actions.
- Store data locally on the device using `shared_preferences`.
- Export a JSON backup of the local ledger.

## Technology

- Flutter and Dart
- Material 3
- `google_fonts` for typography
- `shared_preferences` for local persistence
- iOS app icon assets and a shared transparent in-app logo asset

## Requirements

- Flutter SDK compatible with Dart `^3.13.5`
- Xcode and CocoaPods for iOS development
- A configured iOS Simulator or physical iPhone for device testing

Check your local installation with:

```bash
flutter doctor
```

## Getting started

Clone the repository and install dependencies:

```bash
git clone https://github.com/Hanan786-coder/koin_flow_ios.git
cd koin_flow
flutter pub get
```

Run the application:

```bash
flutter run
```

To target a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

## iOS development

Open the iOS workspace when native configuration or signing changes are
needed:

```bash
open ios/Runner.xcworkspace
```

Build a release iOS application:

```bash
flutter build ios --release
```

For App Store or TestFlight distribution, configure signing and provisioning in
Xcode before archiving and uploading the build.

## Web development and validation

The project can also be run in a browser for quick interaction checks:

```bash
flutter run -d chrome
```

Build a production web bundle:

```bash
flutter build web --release
```

The browser build is useful for validating layout and basic interactions, but
final iOS verification should be performed on an iOS Simulator or physical
device.

## Quality checks

Run static analysis:

```bash
flutter analyze
```

Run the test suite:

```bash
flutter test
```

Format Dart source files:

```bash
dart format lib test
```

## Project structure

```text
koin_flow/
├── assets/
│   └── koin_logo.png
├── ios/
│   └── Runner/
│       └── Assets.xcassets/
├── lib/
│   └── main.dart
├── test/
├── pubspec.yaml
└── README.md
```

The current application is intentionally compact: the primary data models,
state management, screens, sheets, and persistence flow are implemented in
`lib/main.dart`.

## Local data and backups

Koin Flow stores its ledger locally using `shared_preferences`. The data is
device-local and is not synchronized to a server.

Use the Export ledger action in the app to copy a JSON backup. Keep backups in
a secure location because they may contain personal financial information.

Deleting all expenses or all people is permanent for the current local data
store. The app displays a confirmation dialog before either operation.

## Design and interaction principles

- Preserve a focused, dark finance-dashboard experience.
- Keep primary actions easy to reach on iPhone-sized screens.
- Use optional due dates instead of forcing a deadline for every balance.
- Make financial changes visible immediately through updated totals and
  confirmation toasts.
- Prefer native platform behavior for keyboards, sheets, navigation, and
  touch targets.

## Documentation

Additional project documentation is available in:

- `CHANGES.md` for the implementation changelog
- `USER_GUIDE.md` for feature usage
- `IMPLEMENTATION_SUMMARY.md` for technical details
- `STATUS_REPORT.md` for verification notes
- `DOCUMENTATION_INDEX.md` for the complete documentation map

## License

This project is currently maintained as a private application. No open-source
license has been specified.
