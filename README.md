# Trellis LMS

Trellis LMS is a school management and grading app built for day-to-day academic operations.
It helps schools manage school structures, classes, teachers, students, subjects, assignments, and score tracking in one place, with a Khmer-first UI.

## What the App Does

Trellis focuses on practical workflows used by teachers:

- Organize multiple schools and their academic data
- Manage classes, teachers, students, and subjects
- Record assignment scores and calculate grade summaries
- Support class adviser and subject teacher gradebook views
- View dashboard statistics and school-level insights
- Work with local/offline data storage (SQLite)

## Core Features

### 1) School Management

- Add, search, edit, reorder, and delete schools
- Bulk select and remove schools in edit mode
- Cascade cleanup for related academic data when deleting schools

### 2) Academic Structure Management

- Maintain class, subject, teacher, and student records
- Keep data grouped by school for easier administration

### 3) Gradebook & Score Entry

- Monthly score entry with assignment-based scoring
- Semester override support when manual correction is needed
- Automatic calculations for averages and rankings
- Different gradebook perspectives for:
  - Class adviser
  - Subject teacher

### 4) Dashboard & Statistics

- Home dashboard with quick access guidance
- Global statistics tab for summary views

### 5) Localization & UX

- Khmer interface labels and school-friendly terminology
- Theming support and polished mobile-first UI

## Platform & Storage

- Built with Flutter + Riverpod
- Uses SQLite (`sqflite`) for local persistence
- Runs on Android, iOS, Windows, macOS, Linux, and Web (Flutter targets)

## Project Structure (High Level)

- `lib/features/schools` – school workflows
- `lib/features/classes` – class management
- `lib/features/students` – student management
- `lib/features/teachers` – teacher management
- `lib/features/subjects` – subject management
- `lib/features/assignments` – assignment definitions
- `lib/features/gradebook` – score entry and grade calculations
- `lib/features/dashboard` – main dashboard and statistics

## Getting Started

### Prerequisites

- Flutter SDK (stable)
- Dart SDK (comes with Flutter)
- Android Studio / Xcode / VS Code (any supported Flutter setup)

### Run the App

```bash
flutter pub get
flutter run
```

### Analyze Code

```bash
flutter analyze
```

## Build Android Release APK

```bash
flutter build apk --release
```

Output:

- `build/app/outputs/flutter-apk/app-release.apk`

## GitHub Release (APK)

If GitHub CLI is available:

```bash
git push origin master
git push origin v1.0.0
gh release create v1.0.0 "build/app/outputs/flutter-apk/app-release.apk" --title "Trellis LMS v1.0.0 (Android)" --notes "Initial release"
```

If GitHub CLI is not available, publish from GitHub web:

1. Open repository → **Releases** → **Draft a new release**
2. Select tag (example: `v1.0.0`)
3. Upload `app-release.apk`
4. Publish
