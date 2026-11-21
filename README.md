# looki

Flutter app for the looki salon booking platform. Clients browse and book salons; salon owners manage their services, bookings and dashboard.

The app talks to the Spring Boot backend in the `loomea-service` repo, so you need that running before you start the app.

## Requirements

- Flutter 3.29 or newer (Dart 3.7+)
- The backend (`loomea-service`) and its database running locally on port 8080
- A device target: Chrome, Windows, an emulator/simulator, or a physical phone

Check your setup with:

```bash
flutter doctor
```

## Running the app

Start the backend first, then install the dependencies:

```bash
flutter pub get
```

And run it:

```bash
flutter run
```

If more than one device is connected, pick one explicitly:

```bash
flutter devices          # list what's available
flutter run -d chrome    # or an emulator / device id
```

## Pointing at the backend

The API address is set in `lib/data/api/app_config.dart`. It defaults to `http://localhost:8080`, which works for Chrome, Windows and the iOS simulator. Other targets need a different address:

```dart
static const String apiBaseUrl = 'http://localhost:8080';      // web / Windows / iOS simulator
// static const String apiBaseUrl = 'http://10.0.2.2:8080';     // Android emulator
// static const String apiBaseUrl = 'http://192.168.1.x:8080';  // phone on the same Wi-Fi
```

On Android, plain `http://` is blocked by default, so you'll also need `android:usesCleartextTraffic="true"` on the `<application>` tag in `AndroidManifest.xml` for local testing.

To check the backend is up before launching the app:

```bash
curl http://localhost:8080/api/salons
```

## Accounts

Create accounts through the app's sign-up screen, picking either the client or salon owner role. The role you sign up with decides which side of the app you land on after login.

## Card payments (Stripe)

Clients can pay for a booking by card, and salon owners buy their monthly or yearly plan the same way. Card details are typed into Stripe Checkout, never into the app. On Android and iOS Checkout opens inside the app; on web and desktop it opens in the browser and the app picks up the result by itself.

- A card booking is confirmed as soon as Stripe reports it paid. If the client cancels, the owner rejects it, or the slot was taken while they were paying, the money is refunded automatically.
- Abandoned checkouts are cancelled and their slot is freed.
- Clients see their payments under Profile → Payment history; owners manage their plan under Profile → Subscription.

The backend talks to Stripe with the key in `loomea-service`'s `application.yml`. In test mode you can pay with the card `4242 4242 4242 4242`, any future expiry and any CVC.

Your Stripe account can't charge in TND, so charges go out in USD at the same number by default (15 TND is charged as 15.00 USD). The payment screen shows the exact amount Stripe will take. To charge in another currency, set `STRIPE_CURRENCY` and `STRIPE_CONVERSION_RATE` for the backend, for example `eur` and `0.29`.

## Project layout

```
lib/
  data/          models, API repository, api client
  logic/blocs/    one bloc per feature (auth, booking, salon, owner…)
  presentation/   screens, routing, theme, shared widgets
assets/
  images/        app images
  l10n/          translations (en, fr, ar_TN)
```
