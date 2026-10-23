# looki — Design System

> Minimal, warm, and confident. looki's visual language is built from three colours pulled directly from the logo mark: cream, navy, and blue. Everything else is neutral.

---

## Logo

The looki mark is a stylised eye — a navy squircle outer shell, a bright blue ring, a white sclera, a navy pupil offset up-right (the "curious glance"), a white catch-light, and five navy lashes arching above.

**Source SVG** — `C:/Users/izh/Downloads/looki-logo_1.svg`  
**Flutter widget** — `lib/presentation/core/widgets/looki_logo.dart` → `LookiLogo(width: double)`

The widget is a `CustomPainter`; no SVG dependency needed. Pass `width` and the height is automatically `width × 1.2` (matches the SVG viewBox ratio of 200 × 240).

| Usage | Width |
|---|---|
| Onboarding hero | 140 |
| Sign-in screen | 80 |
| Sign-up screen | 56 |

---

## Colour

Defined in `lib/presentation/core/theme/app_theme.dart` → `AppColors`.

### Core palette

| Token | Hex | Usage |
|---|---|---|
| `background` | `#FAF7F2` | Scaffold / screen background — warm cream |
| `surface` | `#FFFFFF` | Cards, bottom sheets, modal fills |
| `inputBackground` | `#FFFFFF` | Text field fills |
| `primary` | `#0A2A6B` | Filled CTA buttons, active states |
| `onPrimary` | `#FFFFFF` | Text / icons on primary buttons |
| `accent` | `#1E6FE8` | Links, icons, focused input border, bottom nav selected |
| `textPrimary` | `#0A2A6B` | Headlines, body copy, labels |
| `textSecondary` | `#8E8E93` | Placeholders, captions, inactive labels |
| `border` | `#E5E5EA` | Input borders, dividers, social button borders |

### Semantic palette

| Token | Hex | Usage |
|---|---|---|
| `error` | `#FF3B30` | Validation errors, destructive actions |
| `errorBg` | `#FDECEB` | Error banner / toast background |
| `success` | `#34C759` | Confirmation, password strength (strong), check icons |
| `successBg` | `#E8F5E9` | Success banner background |
| `successDark` | `#4CAF50` | Progress indicators |
| `warning` | `#FF9500` | Caution states |
| `warningBg` | `#FFF3E0` | Warning banner background |

### Logo colours (raw, for the painter only)

| Name | Hex |
|---|---|
| Navy | `#0A2A6B` |
| Blue | `#1E6FE8` |
| White | `#FFFFFF` |

> **Rule** — do not introduce new brand colours. Any new UI need should be satisfied by tinting or combining existing tokens.

---

## Typography

Font family: **Google Fonts** (configured in `main.dart`). Scale follows Material 3 text roles.

| Role | Flutter token | Size | Weight | Colour | Notes |
|---|---|---|---|---|---|
| Screen title | `titleLarge` | 24 | 600 | `textPrimary` | letterSpacing −0.3, height 1.25 |
| Section heading | `titleMedium` | 18 | 600 | `textPrimary` | |
| Body copy | `bodyLarge` | 16 | 400 | `textPrimary` | height 1.4 |
| Secondary body | `bodyMedium` | 16 | 400 | `textSecondary` | height 1.45 |
| Caption / label | `bodySmall` | 14 | 400 | `textSecondary` | |
| Button label | `labelLarge` | 16 | 500 | `#FFFFFF` | Used inside `ElevatedButton` |

### Ad-hoc overrides used in auth screens

| Element | Size | Weight | Colour |
|---|---|---|---|
| App name "looki" (sign-in) | 32 | 700 | `textPrimary` |
| App name "looki" (onboarding) | 20 | 700 | `textPrimary` |
| Onboarding headline | 28 | 700 | `textPrimary` |
| Forgot password link | 13 | 600 | `accent` |
| Bottom link (new here / sign in) | 14 | 400/600 | `textSecondary` / `accent` |

> **Convention** — brand name "looki" is always lowercase. Subtitle copy ("welcome back, beautiful") is also lowercase, matching the identity shown in the mockup.

---

## Spacing

Defined in `lib/presentation/core/theme/loomea_tokens.dart` → `LoomeaTokens`.

| Token | Value | Use |
|---|---|---|
| `screenPaddingH` | 24 | Horizontal screen edge padding |
| `gapSm` | 8 | Tight gaps (label → field, icon → text) |
| `gapMd` | 16 | Standard component gap |
| `gapLg` | 24 | Section gap |
| `gapXl` | 32 | Large section gap / bottom safe area |

---

## Radii

| Token | Value | Use |
|---|---|---|
| `radiusInput` | 12 | Text fields, social buttons, role toggle |
| `radiusCard` | 16 | Cards, surface containers |
| `radiusHero` | 20 | Large hero / image containers |
| `radiusPill` | 9999 | Fully rounded chips, badges |

---

## Component specs

### ElevatedButton (primary CTA)

```
fill:       primary  (#0A2A6B)
text:       onPrimary (#FFFFFF), 16/600
height:     48
radius:     12
elevation:  0
```

### OutlinedButton (secondary action)

```
fill:       background (#FAF7F2)
border:     border (#E5E5EA), 1px
text:       textPrimary (#0A2A6B), 16/500
height:     48
radius:     12
elevation:  0
```

### Text input

```
fill:           inputBackground (#FFFFFF)
border:         border (#E5E5EA), 1px
focused border: accent (#1E6FE8), 1px
radius:         12
padding:        16h × 16v
hint:           textSecondary, 16/400
label:          textSecondary, 14/500
height:         48
```

### App bar

```
background:    background (#FAF7F2)
elevation:     0
scrolled tint: none
title:         textPrimary, 16/600, centred
```

### Bottom navigation bar

```
background:        background (#FAF7F2)
selected icon/label: accent (#1E6FE8)
unselected:        textSecondary (#8E8E93)
selected label:    12/600
unselected label:  12/400
elevation:         0
```

### Card

```
fill:    surface (#FFFFFF)
radius:  16
shadow:  navy (#0A2A6B) 5% opacity, blur 20, offset (0,4), spread −2
margin:  0
```

### Social login tile (Google / Apple)

```
fill:   surface (#FFFFFF)
border: border (#E5E5EA), 1px
radius: 12
height: 48
icon:   textPrimary, 22px
label:  textPrimary, 14/500
```

---

## Shadow

One shadow level, used for elevated cards only:

```
color:   textPrimary (#0A2A6B) at 5% opacity
blur:    20
offset:  (0, 4)
spread: −2
```

> Avoid adding more shadow levels. Depth is communicated through colour contrast (cream → white), not elevation.

---

## Dividers

```
colour:    border (#E5E5EA)
thickness: 1px
```

The "or continue with" divider uses `border` at 60% opacity to feel lighter.

---

## Source files

| File | Purpose |
|---|---|
| `lib/presentation/core/theme/app_theme.dart` | `AppColors` + `buildLoomeaTheme()` |
| `lib/presentation/core/theme/loomea_tokens.dart` | Spacing, radii, font size constants |
| `lib/presentation/core/widgets/looki_logo.dart` | `LookiLogo` custom painter |
| `lib/presentation/core/widgets/loomea_ui.dart` | Shared UI components |
