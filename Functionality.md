# Loomea — Planned Functionality

Features ordered by priority (highest impact / lowest effort first).

---

## P0 — Critical

| # | Feature | Why |
|---|---------|-----|
| 1 | **Working hours** ✅ | Slot generation is unconstrained; owners have no way to define open/close times per day. Bookings can be created at 3am. |
| 2 | **Real payments (Stripe)** | Demo card form blocks monetisation. Subscription and booking payments need a real provider. |
| 3 | **Booking reminders** ✅ | Notification infrastructure exists but is unused. A 1h-before push cuts no-shows significantly. |

---

## P1 — High Value

| # | Feature | Why |
|---|---------|-----|
| 4 | **In-app chat** | Clients and owners currently have no way to communicate within the app (e.g. "I'm running late"). |
| 5 | **Waitlist** ✅ | When a slot is fully booked, clients can join a queue and get notified on cancellation. |
| 6 | **Availability search** ✅ | "Find any salon open at 3pm today" — cross-salon slot search, currently impossible. |
| 7 | **Image uploads** ✅ | Portfolio posts and avatars rely on URLs. Direct upload (camera/gallery → server) is expected UX. |

---

## P2 — Growth

| # | Feature | Why |
|---|---------|-----|
| 8 | **Loyalty points** | Earn points per booking, redeem for discounts. Increases retention. |
| 9 | **Promotions / discount codes** | Owners create time-limited offers to fill slow slots. |
| 10 | **Tags & filters** ✅ | Filter salon search by price range, rating, distance, category. |
| 11 | **Trending salons** | Surface high-rated or newly added salons on the home explore screen. |

---

## P3 — Nice to Have

| # | Feature | Why |
|---|---------|-----|
| 12 | **Staff management** ✅ | Multiple stylists per salon; assign bookings to a specific staff member. |
| 13 | **Service-level ratings** | Rate individual services separately from the overall salon. |
| 14 | **Revenue export** | Download monthly earnings as CSV from the owner dashboard. |
| 15 | **No-show auto-flag** ✅ | Reliability score exists; automatically restrict clients who accumulate no-shows. |
