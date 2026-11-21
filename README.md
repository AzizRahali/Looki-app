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

Mock mode is enabled by default. Run `flutter run` and the app reads from the
JSON file through `MockRepository` instead of hitting the API.

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

Use build-time settings to enable the API and point the app at your server
without changing the mock-mode defaults:

```bash
flutter run -d chrome --dart-define=USE_MOCK_DATA=false --dart-define=API_BASE_URL=http://localhost:8081
```

Use the port on which the backend is listening. For Android emulators use
`http://10.0.2.2:<port>`; for a physical device use the host machine's LAN IP.
Without these options, the app continues to use mock data.

The backend lives in the sibling `looki-backend` folder.

On the search screen, typing runs a regular keyword search. Pressing Enter or
the ✨ button runs a smart (natural-language) search, for example
"manucure à La Marsa samedi". The filters the app understood are shown as chips;
**Clear** returns to keyword results. In mock mode, smart search falls back to
keyword search. See the backend README for the AI setup.

The owner dashboard shows an **Insights** card for the last 28 days: bookings,
revenue, cancellation and no-show rates, returning clients, busiest and
quietest times, top services, and an AI-written summary with suggestions in the
app's language. The numbers come from the backend; if AI is unavailable, the
card still shows them.

**Help Center** (client Profile tab) and **Help & Support** (owner Profile tab)
open an AI support chat. It answers how-to questions in the app's language
using only Looki's help articles, offers suggested questions, and points to
support@loomea.app when it has no answer. It cannot see or change bookings. In
mock mode it always shows the "unavailable" message.

For an isolated local backend on Windows, run the following in PowerShell from
that folder. This uses an in-memory database; its data disappears on restart.

```powershell
$env:PORT = '8081'
$env:SERVER_ADDRESS = '127.0.0.1'
$env:SPRING_DATASOURCE_URL = 'jdbc:h2:mem:loomea;DB_CLOSE_DELAY=-1'
$env:SPRING_DATASOURCE_USERNAME = 'sa'
$env:SPRING_DATASOURCE_PASSWORD = ''
$env:SPRING_DATASOURCE_DRIVER_CLASS_NAME = 'org.h2.Driver'
$env:SPRING_JPA_PROPERTIES_HIBERNATE_DIALECT = 'org.hibernate.dialect.H2Dialect'
$env:JWT_SECRET = [Convert]::ToBase64String((1..64 | ForEach-Object { [byte](Get-Random -Maximum 256) }))
mvn spring-boot:run
```

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
