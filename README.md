# looki

Flutter app for the looki salon booking platform. Clients browse and book salons; salon owners manage their services, bookings and dashboard.

The app can run two ways: against the live backend, or fully offline on bundled mock data. Mock mode is the quickest way to get the UI up without touching the server.

## Requirements

- Flutter 3.29 or newer (Dart 3.7+)
- A device target: Android emulator, iOS simulator, Chrome, or a physical phone

Check your setup with:

```bash
flutter doctor
```

## Running the app

Install the dependencies first:

```bash
flutter pub get
```

Then run it:

```bash
flutter run
```

If more than one device is connected, pick one explicitly:

```bash
flutter devices          # list what's available
flutter run -d chrome    # or an emulator / device id
```

## Mock data mode

Everything the app needs to render is in `assets/data/mock_data.json` — salons, services, reviews, a client profile, appointments, and owner-side salons, bookings and dashboard stats. No backend, no login server, no network.

To switch it on, open `lib/data/api/app_config.dart` and set:

```dart
static const bool useMockData = true;
```

Then `flutter run`. The app reads from the JSON file through `MockRepository` instead of hitting the API.

### Test accounts

There's no real auth in mock mode — the password is ignored and any value works. The email decides which side of the app you land on:

| Role | Email | Password |
|------|-------|----------|
| Client | `client@looki.test` | anything |
| Salon owner | `owner@looki.test` | anything |

Any email with `owner` in it signs in as the salon owner; everything else is treated as a client. The two profiles live under `profile` and `ownerProfile` in `mock_data.json`.

### Editing the data

Just edit `assets/data/mock_data.json` and restart the app (a hot restart, `R`, is enough — hot reload won't re-read the asset). The top-level keys map to what you see on screen:

| Key | Shows up in |
|-----|-------------|
| `profile` | Client account & saved salons |
| `salons` | Explore / search / salon detail (services + reviews) |
| `appointments` | Client's upcoming & past bookings |
| `categories` | Category chips on the home screen |
| `ownerSalons` | Owner's "My Salon" screen |
| `ownerBookings` | Owner booking list (upcoming / past) |
| `dashboard` | Owner dashboard stats |

A few things to keep in mind when editing:

- Appointment `status` is one of `PENDING`, `CONFIRMED`, `COMPLETED`, `CANCELLED`, `NO_SHOW`. Upcoming vs. past is decided by status, not date.
- Review dates use the `createdAt` field (ISO-8601).
- Keep `id` values unique within each list.

## Running against the backend

Set `useMockData` back to `false` and point `apiBaseUrl` at your server in the same `app_config.dart`:

```dart
static const bool useMockData = false;
static const String apiBaseUrl = 'http://localhost:8080';   // web / iOS simulator
// static const String apiBaseUrl = 'http://10.0.2.2:8080';  // Android emulator
// static const String apiBaseUrl = 'http://192.168.1.x:8080'; // phone on same Wi-Fi
```

The backend lives in the `loomea-service` repo.

## Project layout

```
lib/
  data/          models, repositories (API + mock), api client
  logic/blocs/    one bloc per feature (auth, booking, salon, owner…)
  presentation/   screens, routing, theme, shared widgets
assets/
  data/          mock_data.json
  images/        app images
  l10n/          translations (en, fr, ar_TN)
```
