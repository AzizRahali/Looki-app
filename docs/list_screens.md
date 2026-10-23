# Loomea — stitched screen list

Single reference for design (e.g. Stitch), QA, and routing.  
**Source of truth in code:** `lib/presentation/core/routes/list_screens.dart` and `app_router.dart`.

## Design system (aligned with Stitch)

| Token | Role |
|--------|------|
| `AppColors` + `LoomeaTokens` | `lib/presentation/core/theme/` |
| Shared UI (back pill, OR CONTINUE WITH, social row, surface cards) | `lib/presentation/core/widgets/loomea_ui.dart` |
| Typography | Inter via `google_fonts` in `main.dart` |

Palette: background `#FFFFFF`, surface `#F5F5F7`, input `#F2F2F7`, text `#1A1A1A` / `#8E8E93`, accent `#5E5CE6`, 24px horizontal padding, 10px input/button radius, 52px control height.

## All routes (GoRouter)

| Route name | Path | Screen |
|------------|------|--------|
| `onboarding` | `/onboarding` | Onboarding / Welcome |
| `signIn` | `/sign-in` | Sign In |
| `signUp` | `/sign-up` | Create Account |
| `phoneVerification` | `/phone-verification` | Phone number entry |
| `otpVerification` | `/otp-verification` | OTP verification |
| `home` | `/home` | Home shell (bottom nav) |
| `search` | `/search` | Search salons / services |
| `salonProfile` | `/salon` | Salon profile (+ services) |
| `selectTimeSlot` | `/time-slot` | Calendar / time slots |
| `bookingReview` | `/booking-review` | Review & confirmation |
| `bookingConfirmation` | `/booking-confirmation` | Booking confirmed |

## Stitched flows

### A — Sign up → verify → home

`signUp` → `phoneVerification` → `otpVerification` → `home`

### B — Discover → book → confirm

`home` → `search` → `salonProfile` → `selectTimeSlot` → `bookingReview` → `bookingConfirmation`

### C — Home shell tabs (same route `/home`)

Not separate URLs: **Home** | **My Appointments** | **Saved** | **Profile**

## Notes

- `salonProfile` accepts optional `extra` (String) for salon name.
- Keep this doc in sync when adding or renaming routes.
