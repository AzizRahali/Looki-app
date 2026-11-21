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

The API address defaults to `http://localhost:8080`, which works for Chrome, Windows and the iOS simulator. Point the app somewhere else at build time, without editing code:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://looki-backend.onrender.com
```

For the Android emulator use `http://10.0.2.2:8080`; for a phone on the same Wi-Fi, your computer's LAN IP. On Android, plain `http://` is blocked by default, so you'll also need `android:usesCleartextTraffic="true"` on the `<application>` tag in `AndroidManifest.xml` for local testing.

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

## AI features

The AI runs on the backend; see its README for setup. Without it, each feature falls back as described.

- **Smart search.** On the search screen, typing runs a regular keyword search. Pressing Enter or the ✨ button runs a natural-language search, for example "manucure à La Marsa samedi". The filters the app understood show as chips; **Clear** returns to the keyword results. Without AI it falls back to keyword search.
- **Owner insights.** The owner dashboard shows an **Insights** card for the last 28 days: bookings, revenue, cancellation and no-show rates, returning clients, busiest and quietest times, top services, and an AI-written summary with suggestions in the app's language. The numbers come from the backend, so the card still shows them without AI.
- **Support chat.** **Help Center** (client Profile tab) and **Help & Support** (owner Profile tab) open a support chat. It answers how-to questions in the app's language using only Looki's help articles, offers suggested questions, and points to support@loomea.app when it has no answer. It can't see or change bookings. Without AI it shows an "unavailable" message.

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
