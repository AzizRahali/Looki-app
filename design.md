# Loomea — Frontend Design Document

> **Purpose:** Complete reference for generating screens, components, and flows consistent with the existing codebase.

---

## 1. Brand Identity

**App name:** Loomea (displayed as "looki" in the logo mark)  
**Concept:** Warm, minimal, premium salon booking — feels like a high-end lifestyle app, not a utility.  
**Personality:** Clean, airy, trustworthy. Navy authority meets cream warmth.

---

## 2. Design System

### 2.1 Color Palette

| Token | Hex | Usage |
|---|---|---|
| `background` | `#FAF7F2` | Screen background — warm cream |
| `surface` | `#FFFFFF` | Cards, inputs, bottom sheets |
| `inputBackground` | `#FFFFFF` | Text field fills |
| `textPrimary` | `#0A2A6B` | Headings, body text, icons — deep navy |
| `textSecondary` | `#8E8E93` | Placeholders, captions, muted labels |
| `border` | `#E5E5EA` | Input borders, dividers, card outlines |
| `primary` | `#0A2A6B` | Filled CTA buttons, selected states |
| `onPrimary` | `#FFFFFF` | Text/icons on primary buttons |
| `accent` | `#1E6FE8` | Links, focused borders, active icons, bottom-nav selected |
| `error` | `#FF3B30` | Error text, destructive actions |
| `errorBg` | `#FDECEB` | Error banner backgrounds |
| `success` | `#34C759` | Confirmed status, positive feedback |
| `successBg` | `#E8F5E9` | Success banner backgrounds |
| `warning` | `#FF9500` | Pending status, caution states |
| `warningBg` | `#FFF3E0` | Warning banner backgrounds |

**Reliability tier colors (inline use only):**
- TRUSTED: `#22C55E` (green)
- NORMAL: `#3B82F6` (blue)
- RISKY: `#F59E0B` (amber)
- RESTRICTED: `#EF4444` (red)

### 2.2 Typography

Font: **Google Fonts** (system default with Material 3 text theme applied)

| Role | Size | Weight | Color | Usage |
|---|---|---|---|---|
| `titleLarge` | 24sp | 600 | textPrimary | Screen titles |
| `titleMedium` | 18sp | 600 | textPrimary | Section headings |
| `bodyLarge` | 16sp | 400 | textPrimary | Body copy, input values |
| `bodyMedium` | 16sp | 400 | textSecondary | Supporting body, placeholders |
| `bodySmall` | 14sp | 400 | textSecondary | Captions, metadata |
| `labelLarge` | 16sp | 500 | white | Button labels |
| Hero headline | 28sp | 700 | textPrimary | Onboarding / hero moments |
| Overline | 12sp | 600 | textSecondary | Tab labels, badge counts |

Line heights: 1.25 (titles) · 1.4–1.45 (body) · 1.5 (long-form text)  
Letter spacing: –0.3 on titles for tighter, premium feel.

### 2.3 Spacing Tokens

| Token | Value | Use |
|---|---|---|
| `screenPaddingH` | 24dp | Horizontal screen margin |
| `gapSm` | 8dp | Tight spacing between related elements |
| `gapMd` | 16dp | Standard gap between components |
| `gapLg` | 24dp | Section spacing |
| `gapXl` | 32dp | Large section breaks |

### 2.4 Border Radius Tokens

| Token | Value | Use |
|---|---|---|
| `radiusInput` | 12dp | Text fields, social buttons, chips |
| `radiusCard` | 16dp | Surface cards, modals, list items |
| `radiusHero` | 20dp | Hero images, large photo containers |
| `radiusPill` | 9999dp | Tags, chips, badges, FABs |

### 2.5 Component Specs

**Buttons**
- Primary: height 48dp · radius 12dp · background `primary` · text white 16/600 · no shadow
- Outlined: height 48dp · radius 12dp · border `border` · background `background` · text `textPrimary` 16/500
- Text button: foreground `primary` or `accent`

**Inputs**
- Height: 48dp · radius 12dp · fill `surface` · border `border` 1dp
- Focus border: `accent` 1dp
- Hint text: `textSecondary` 16/400
- Label (above input): `textSecondary` 14/500

**Cards**
- Background `surface` · radius 16dp · elevation 0
- Soft shadow (optional): `rgba(0A2A6B, 0.05)` blur 20dp offset (0, 4)

**Bottom sheets**
- Handle bar: 36×4dp · radius 2dp · color `border` · centered at top
- Top padding 20dp · side padding 24dp · bottom = `viewInsets.bottom + 20dp`

**Segment / Tab controls**
- Container: `surface` fill · radius pill · padding 4dp
- Selected chip: `background` fill · soft shadow · text `textPrimary` 14/600
- Unselected: transparent · text `textSecondary` 14/400

**Status chips**
- PENDING: `warningBg` background · `warning` text
- CONFIRMED: `successBg` background · `success` text
- COMPLETED: `surface` background · `textSecondary` text
- CANCELLED: `errorBg` background · `error` text
- NO_SHOW: `border` background · `textSecondary` text

**AppBar**
- Background `background` · no elevation · center title · 16/600 `textPrimary`
- Back button: 36×36dp circle · `surface` fill · `arrow_back_ios_new_rounded` 16dp icon

**Bottom navigation**
- Background `background` · no elevation · 4 or 5 tabs
- Selected: `accent` icon + label 12/600
- Unselected: `textSecondary` icon + label 12/400

**Notification dot**
- 8dp red circle overlay on top-right of nav icon
- Color `error`

---

## 3. App Structure & Navigation

### 3.1 Entry Flow

```
App Launch
  │
  ├── Not logged in → /onboarding
  │     └── Get Started / Sign In → /sign-in or /sign-up
  │           └── /phone-verification
  │                 └── /otp-verification
  │                       └── CLIENT → /home
  │                           SALON_OWNER → /owner-onboarding → /owner-subscription → /owner-home
  │
  └── Logged in → redirect
        ├── CLIENT → /home
        └── SALON_OWNER → /owner-home
```

### 3.2 Client Shell — Bottom Navigation (4 tabs)

Located at `/home` — `HomeShellPage`

| Tab | Icon | Label | Content |
|---|---|---|---|
| 0 | `explore_rounded` | Explore | Salon grid / search |
| 1 | `search_rounded` | Search | Search + filters |
| 2 | `calendar_today_rounded` | Bookings | Upcoming / past / waitlist |
| 3 | `person_rounded` | Profile | User profile + settings |

**Bookings tab** shows a red notification dot when an appointment status changes (polled every 3 seconds).

### 3.3 Owner Shell — Bottom Navigation (4 tabs)

Located at `/owner-home` — `OwnerShellPage`

| Tab | Icon | Label | Content |
|---|---|---|---|
| 0 | `dashboard_rounded` | Dashboard | Revenue stats + today's bookings |
| 1 | `storefront_rounded` | My Salon | Salon details, team, services, portfolio |
| 2 | `calendar_month_rounded` | Bookings | Upcoming / past client bookings |
| 3 | `person_rounded` | Profile | Owner profile + subscription |

---

## 4. Screens

### 4.1 Onboarding (`/onboarding`)
**Layout:** Full-screen single-page  
**Elements:**
- Logo mark "looki" centered near top (140dp wide)
- Hero illustration area (large ClipRRect with decorative gradient, fills most of screen)
- Title: "Book your next beauty appointment" — 28sp bold navy
- Subtitle: supporting tagline — 16sp textSecondary
- "Get Started" → primary full-width button → `/sign-up`
- "Sign in" → text link → `/sign-in`

---

### 4.2 Sign In (`/sign-in`)
**Layout:** Centered card on cream background, scrollable  
**Elements:**
- Logo mark (80dp wide) · centered
- Title "Welcome back" 24sp 700
- Subtitle "Sign in to your account" 16sp textSecondary
- Email field (labeled above)
- Password field (labeled above, toggle visibility)
- "Forgot password?" → right-aligned text link
- "Sign In" → primary full-width button
- `LoomeaOrContinueDivider`
- `LoomeaSocialButtonRow` (Google + Apple)
- "Don't have an account? Sign up" → bottom link

---

### 4.3 Sign Up (`/sign-up`)
**Layout:** Same as Sign In  
**Elements:**
- Logo mark · "Create account" title · subtitle
- Full name field
- Email field
- Password field
- Role selector: CLIENT or SALON_OWNER (segmented or toggle chips)
- "Continue" → primary button → `/phone-verification`
- Social buttons row
- "Already have an account? Sign in" link

---

### 4.4 Phone Verification (`/phone-verification`)
**Layout:** Centered, single column  
**Elements:**
- Back button
- Title "Verify your number" 24sp
- Subtitle with email shown
- Phone number field (with country code prefix)
- "Send Code" → primary button → `/otp-verification`

---

### 4.5 OTP Verification (`/otp-verification`)
**Layout:** Centered  
**Elements:**
- Back button
- Title "Enter verification code"
- Subtitle "We sent a code to +XX XXXX"
- 6-digit OTP input (individual digit boxes or single field)
- "Verify" → primary button → home (CLIENT) or owner onboarding (OWNER)
- "Resend code" → text link (with countdown)

---

### 4.6 Owner Onboarding (`/owner-onboarding`)
**Layout:** Full screen welcome  
**Elements:**
- Illustration or icon
- "Welcome to Loomea for Business" headline
- Feature bullet points (manage bookings, grow your salon, etc.)
- "Get Started" → primary button → `/owner-subscription`

---

### 4.7 Owner Subscription (`/owner-subscription`)
**Layout:** Scrollable with plan cards  
**Elements:**
- Title "Choose your plan"
- Plan cards (Monthly / Annual) with feature list and price
- Selected plan: `primary` border highlight
- Card input section (number, expiry, CVV, cardholder name) — labeled fields
- "Subscribe" → primary button

---

### 4.8 Explore / Home Tab (Tab 0 of HomeShell)
**Layout:** SafeArea scroll  
**Elements:**
- Header row: greeting "Good morning, [firstName]" + location button
- Search bar (tappable, navigates to `/search`) — `surface` fill, radius 12, search icon left
- Horizontal category chips scroll: All · Hair · Nails · Skin · Massage · …
- Section heading "Nearby Salons" + "See all" link
- Vertical list of `SalonCard` items

**SalonCard:**
- `surface` fill · radius 16dp · full-width
- Top: salon image (height 140dp · radius 16dp top corners · NetworkImage)
- Body: salon name 16/600 · address 13 textSecondary · rating star + count · distance pill
- Tags row: horizontal scrolling chips (radius pill · `surface` fill · border)
- Bottom: "Book Now" text button (right aligned · `accent`)

---

### 4.9 Search Page (`/search`)
**Layout:** Column — search bar + chips + results list  
**Elements:**
- Search text field (auto-focused, back button left)
- **Filter chips row** (horizontal scroll):
  - "Filters" badge button (shows active count)
  - "Available at" chip (opens date+time picker, blue when active)
  - Category chips from results
  - Sort chips: Rating / Distance / Price
- Results list of `SalonCard` (same as Explore)
- Empty state: icon + "No salons found" message (different for availability mode)

**Filter Bottom Sheet:**
- "Filters" title + "Reset" button (top row)
- Rating: Any / 3★+ / 4★+ / 4.5★+ chips
- Max price: Any / $50 / $100 / $200 chips
- Categories: multi-select chips from available results
- "Apply Filters" primary button

---

### 4.10 Explore Map (`/explore-map`)
**Layout:** Full-screen `FlutterMap`  
**Elements:**
- Map fills screen (OpenStreetMap tiles)
- Circular map markers for each salon (navy pin)
- Back button overlay (top-left)
- Salon preview card slides up from bottom on marker tap (name, rating, address)

---

### 4.11 Salon Profile (`/salon`)
**Layout:** `CustomScrollView` with `SliverAppBar`  
**Elements:**
- **Sticky app bar** (pinned): back button · salon name · favorite heart toggle (filled `error` / outline)
- **Hero image** (expandedHeight 220dp): salon cover photo or gradient placeholder
- **Info section:**
  - Salon name 22/700 · verified badge (if verified)
  - Star rating + review count + distance
  - Address row (icon + text) · Phone row (icon + text)
  - Tags chips row (horizontal scroll)
  - Opening hours text
- **Services section** ("Services" heading 18/600):
  - Category filter chips (horizontal scroll)
  - Service cards: icon left · name + description · duration · price right · checkbox toggle
  - Selected services count badge
- **Staff section** ("Our Team" heading): horizontal scroll of staff avatars (name + role below)
- **Portfolio section** ("Portfolio" heading): 2-column grid of portfolio images (tap to expand)
- **Reviews section** ("Reviews" heading):
  - Overall rating large · star breakdown bars
  - Review cards: avatar · name · date · star row · comment
  - "Write a Review" button (client only)
- **Sticky bottom bar:** "Book Now" primary button + total price (shown when services selected)

---

### 4.12 Select Time Slot (`/time-slot`)
**Layout:** Column — date picker + slot grid + bottom CTA  
**Elements:**
- AppBar "Select Time & Date" + back button
- Horizontal date scroll: weekday pills (Mon 14, Tue 15, …) · selected: `primary` fill
- Available time slot grid: 2-column · each slot = pill chip · Available: `surface` border · Selected: `primary` fill · Booked: `border` fill grayed out
- **Bottom bar:**
  - If all booked: "Join Waitlist" or "On Waitlist" button
  - Otherwise: "Confirm Time" primary button

---

### 4.13 Booking Review (`/booking-review`)
**Layout:** Scrollable + sticky bottom bar  
**Elements:**
- AppBar "Review & Confirmation" + back button
- **Booking Summary** heading 22/700
- Salon card: image placeholder (160dp) + salon name + date/time row + address row
- **Services breakdown**: each service row — icon · name · price right · duration
- Subtotal row + total row (bold)
- Divider
- **Payment Method**: "Pay at Salon" / "Pay with Card" chips (toggle)
- **Preferred Stylist** (shown only if salon has staff): chip row — "No Preference" + staff chips (avatar + name)
- **Notes**: multi-line text field "Any special requests?"
- **Cancellation Policy** info box (icon + text)
- **Bottom bar**: "Back" outlined (120dp) + "Confirm Booking" primary (expanded)

---

### 4.14 Booking Confirmation (`/booking-confirmation`)
**Layout:** Centered success screen  
**Elements:**
- Large success icon (circle · `success` background · checkmark)
- "Booking Confirmed!" 24/700
- Booking details card: salon · date · time · services · total
- "View My Appointments" → primary button
- "Back to Explore" → outlined button

---

### 4.15 My Appointments (`/home` Tab 2)
**Layout:** Scrollable with tab switcher  
**Elements:**
- Title "My Appointments" 24/700
- **Reliability banner** (shown for RISKY/RESTRICTED tier): colored warning box with icon + message + tier color
- **Segment control**: Upcoming · Past · Waitlist (3 tabs, pill style)
- **Upcoming tab:** List of `AppointmentCard`
- **Past tab:** List of `AppointmentCard` (with "Book Again" action)
- **Waitlist tab:** List of `WaitlistCard`

**AppointmentCard:**
- `surface` card · radius 16dp
- Status chip (top-right corner)
- Salon name 16/600 · services text · date + time row · address
- **Attendance confirmation banner** (amber, for RISKY tier unconfirmed appointments): "Confirm Attendance" button
- Actions row: "Cancel" (error text) + "Reschedule" or "Book Again"

**WaitlistCard:**
- Salon name + date + "On Waitlist" or "Notified" badge
- "Leave Waitlist" destructive text button

**Empty state:** centered icon + "No appointments yet" + "Book a Service" button

---

### 4.16 Profile (`/home` Tab 3)
**Layout:** Scrollable  
**Elements:**
- **Avatar section**: CircleAvatar (80dp) with camera badge overlay (tappable → image picker) · name 20/600 · email 14 textSecondary
- **Reliability Card** (`_ReliabilityCard`):
  - "Reliability Score" label · tier badge (colored pill)
  - Score number 28/700 · score bar (linear progress)
  - Tier description text
- **Account section** (surface card, list rows):
  - Edit Profile → opens bottom sheet
  - Saved Salons → `/favorite-salons`
  - Payment Methods → `/payment-methods`
  - Notifications → `/notifications`
- **Account actions:**
  - "Log Out" → dialog confirmation
  - "Delete Account" → dialog (red, with 30-day grace period message)
- **Pending deletion banner** (if scheduled): days remaining, "Cancel Deletion" button

---

### 4.17 Favorite Salons (`/favorite-salons`)
**Layout:** Scrollable list  
**Elements:**
- AppBar "Saved Salons" + back
- List of `SalonCard` (same as Explore) with filled heart icon
- Empty state: heart icon + "No saved salons yet"

---

### 4.18 Notifications (`/notifications`)
**Layout:** List  
**Elements:**
- AppBar "Notifications" + back
- Notification rows: icon · title · body · timestamp
- Empty state message

---

### 4.19 Payment Methods (`/payment-methods`)
**Layout:** List  
**Elements:**
- AppBar "Payment Methods" + back
- Card rows: card type icon · "•••• 4242" · default badge
- "Add New Card" row (+ icon)
- Empty state

---

### 4.20 Owner Dashboard (Owner Tab 0)
**Layout:** Scrollable  
**Elements:**
- Header: "Good morning, [name]" + salon name
- **Stats grid** (2-column):
  - Today's Appointments (calendar icon · count)
  - Today's Revenue (currency icon · $X)
  - Monthly Revenue (trending-up icon · $X)
  - Completed (checkmark icon · count)
- **Today's Bookings** section: list of `OwnerBookingCard`
- **Upcoming** section: next few bookings

**OwnerBookingCard:**
- Client name + avatar · time · services · status chip
- Reliability tier indicator (colored dot or pill)
- Actions: Confirm / Complete / Reject / No-Show buttons

---

### 4.21 Owner My Salon (Owner Tab 1)
**Layout:** Scrollable  
**Elements:**
- Header row: "My Salon" title + Edit pencil button
- Salon cover image (200dp · radius 20) + image picker overlay
- Salon info card: name · description · rating · address · phone
- **Working Hours section** (`_WorkingHoursSection`):
  - "Working Hours" heading + Edit button
  - Day rows: weekday name · Open/Closed toggle · time range
- **Team section** ("Team" heading + count badge + "Add" button):
  - Staff cards: avatar · name · role · edit/delete icons
  - Empty state
- **Services section** ("Services" heading + count badge + "Add Service" button):
  - Service rows: icon · name · category · duration · price · edit/delete
  - Empty state
- **Portfolio section** ("Portfolio" heading + "Add Post" button):
  - 2-column image grid · tap to edit/delete
- **Reviews section** ("Reviews" heading):
  - Review cards (read-only, owner view)

**Add/Edit sheets (bottom sheets):**
- Service: name · description · category · price · duration · icon picker
- Staff: name · role
- Portfolio post: image picker + caption field

---

### 4.22 Owner Bookings (Owner Tab 2)
**Layout:** Segmented tabs + list  
**Elements:**
- "Bookings" title
- Segment control: Upcoming · Past
- List of `OwnerBookingCard` with full action buttons
- Pull-to-refresh

---

### 4.23 Owner Profile (Owner Tab 3)
**Layout:** Scrollable  
**Elements:**
- Avatar picker (same pattern as client) · name · email
- **Subscription card**: plan name · renewal date · "Manage Subscription" button
- Account rows: Edit Profile · Log Out
- Subscription management (upgrade/cancel)

---

## 5. Shared / Reusable Components

| Component | File | Description |
|---|---|---|
| `LoomeaScreenPadding` | loomea_ui.dart | 24dp horizontal padding wrapper |
| `LoomeaAppBarLeading` | loomea_ui.dart | Circular back button, surface fill |
| `LoomeaOrContinueDivider` | loomea_ui.dart | "Or continue with" text divider |
| `LoomeaSocialButtonRow` | loomea_ui.dart | Google + Apple login buttons |
| `LoomeaSurfaceCard` | loomea_ui.dart | White card with optional shadow |
| `LoomeaLabeledField` | loomea_ui.dart | Label above input field |
| `_ReliabilityCard` | profile_page.dart | Score bar + tier badge + description |
| `_ReliabilityBanner` | my_appointments_page.dart | Inline warning for RISKY/RESTRICTED |
| `_FilterSheet` | search_page.dart | Rating · price · category filter sheet |
| `_StaffPicker` | booking_review_page.dart | Staff chip row in booking flow |
| `_WorkingHoursSection` | owner_my_salon_page.dart | Day-by-day hours editor |
| `_PaymentChip` | booking_review_page.dart | Pay at Salon / Pay with Card toggle |
| `_WaitlistCard` | my_appointments_page.dart | Waitlist entry with leave button |

---

## 6. Feature Flows (User Journeys)

### Client: Book an Appointment
```
Explore → Salon Profile
  → Select services (checkboxes)
  → "Book Now" (sticky bottom bar)
  → Select Time Slot (date + available slots)
  → Booking Review (payment · preferred stylist · notes)
  → Confirm Booking
  → Booking Confirmation screen
```

### Client: Reschedule
```
My Appointments (Upcoming tab)
  → Appointment card "Reschedule"
  → Select Time Slot (same page, reschedule mode)
  → Confirmation
```

### Client: Join Waitlist
```
Select Time Slot (all slots booked)
  → "Join Waitlist" button
  → Push notification when slot opens (NOTIFIED status)
  → Waitlist tab shows "Notified" badge
```

### Client: Search by Availability
```
Search → "Available at" chip → Date + Time picker
  → Results filtered to salons open at that time
```

### Owner: Manage a Booking
```
Owner Bookings → Booking card
  → Confirm (PENDING → CONFIRMED)
  → Complete (CONFIRMED → COMPLETED)
  → Reject / No-Show
```

### Owner: Add Staff
```
My Salon → Team section → "Add" button
  → Bottom sheet: name + role → Save
```

---

## 7. State & Feedback Patterns

| Scenario | UI Pattern |
|---|---|
| Loading | `CircularProgressIndicator(color: AppColors.primary)` centered |
| Error | `SnackBar` with floating behavior · red background or message |
| Empty state | Centered icon (72dp rounded container) + title 20/600 + subtitle 14 + optional action button |
| Success action | SnackBar floating · `success` color |
| Destructive confirm | `AlertDialog` with "Keep" (textSecondary) + action button (error color) |
| Pull-to-refresh | `RefreshIndicator` with `AppColors.primary` color |
| Status polling | Background timers (3s client, 15s owner) with silent state updates |

---

## 8. Image Handling

- **Salon cover images**: stored as base64 JPEG on backend → served from `/api/salons/{id}/image`
- **Avatar images**: served from `/api/auth/users/{id}/avatar` (requires Auth header)
- **Portfolio images**: served from `/api/portfolio/{id}/image`
- **Staff avatars**: served from `/api/owner/staff/{id}/avatar`
- **Fallback**: `errorBuilder` shows broken image icon on `NetworkImage` failure
- **Image picker**: `image_picker` package → camera or gallery → base64 encoded → PUT to backend

---

## 9. Responsive Behavior

- All screens use `SafeArea` + `SingleChildScrollView` or `ListView`
- Max content width not enforced (designed for mobile portrait, ~375–428dp)
- `MediaQuery.of(context).viewInsets.bottom` used in bottom sheets to clear keyboard
- `ConstrainedBox(minHeight: size.height)` on auth screens for keyboard-push centering

---

## 10. Accessibility Notes

- All interactive elements have minimum 48dp tap targets
- Status colors always paired with text labels (not color-only signaling)
- `Semantics` labels not explicitly added — add where generating new screens
