# FuelProof — System Design Document

> **Version** 1.0 · **Platform** Flutter (iOS + Android) · **Spring 2026**

---

## 1. Purpose

FuelProof is a real-time fuel transaction verification mobile application. It connects customers directly to IoT hardware embedded in a fuel dispenser, giving them an independent, signal-based reading of the exact fuel quantity dispensed — without relying on the attendant, the station display, or any manual input.

The core problem it solves is trust. Petrol stations across Pakistan operate on blind faith. Customers pay for fuel they cannot independently verify. FuelProof breaks that dependency by putting verified data directly in the customer's hand at the moment of dispensing.

---

## 2. Target Users

| Role | Description |
|---|---|
| **Customer** | Vehicle owner at a petrol station. Scans QR, monitors live dispensing, receives receipt |
| **Station Admin** | Manages nozzles, reviews fraud alerts, tracks employee activity and sales |
| **Super Admin** | Platform-level oversight, analytics, station onboarding |

---

## 3. Design Philosophy

FuelProof is designed around three principles that inform every layout, component, and interaction decision:

**Clarity over decoration.**
Every screen has one primary action. No carousels, no decorative elements, no information overload. The user always knows what the screen is for within two seconds of opening it.

**Trust through precision.**
Numbers are large, prominent, and real-time. Data is never hidden behind a tap. If fuel is flowing, the user sees the exact figure updating live. Precision in data display reinforces the core promise of the product.

**Calm confidence.**
The visual language is restrained. Deep navy, clean white, electric teal as a single accent. No aggressive reds unless there is a genuine fraud alert. The app should feel like a tool built by engineers who know what they are doing, not a startup trying to look exciting.

---

## 4. Visual Identity

### 4.1 Color System

```
Primary Background     #FFFFFF   White
Surface / Card         #F4F6FA   Cool off-white
Primary Text           #0D1B2A   Near black
Secondary Text         #6B7A8D   Slate grey
Brand Navy             #1A2744   Deep navy (primary brand)
Accent Teal            #00B4A6   Electric teal (CTAs, live indicators)
Success                #1e7e34   Green (honest reading confirmed)
Alert                  #C0392B   Red (fraud detected)
Divider                #E2E8F0   Light border
```

### 4.2 Typography

```
Font Family            Inter (Google Fonts)

Display / Hero         Inter 700   32px   Near black
Section Heading        Inter 600   20px   Near black
Card Title             Inter 600   16px   Near black
Body                   Inter 400   14px   Secondary text
Caption / Label        Inter 400   12px   Slate grey
Live Data (numbers)    Inter 700   40px   Brand navy
```

All type is left-aligned unless the screen is a single-focus splash or confirmation state. No centered body text.

### 4.3 Spacing System

Base unit of `4px`. All padding, margin, and gap values are multiples of 4.

```
xs    4px
sm    8px
md    16px
lg    24px
xl    32px
2xl   48px
```

### 4.4 Component Tokens

```
Border Radius
  Card              12px
  Button            10px
  Input             8px
  Badge             99px  (pill)

Elevation
  Card              box-shadow: 0 2px 8px rgba(0,0,0,0.06)
  Modal             box-shadow: 0 8px 32px rgba(0,0,0,0.12)

Icon Size
  Navigation        24px
  In-card           20px
  Inline with text  16px
```

---

## 5. Screen Architecture

### 5.1 Navigation Structure

```
FuelProof
├── Auth Stack
│   ├── Splash
│   ├── Login
│   ├── Register
│   └── Forgot Password / OTP
│
└── Main Shell (Bottom Navigation)
    ├── Home
    ├── Scan (QR)
    ├── History
    └── Profile
        └── Settings
```

### 5.2 Admin Shell (separate entry point)

```
Admin Shell (Side Drawer)
├── Dashboard Overview
├── Live Nozzle Monitor
├── Fraud Alerts
├── Transaction Reports
├── Complaint Management
├── Employee Performance
└── Station Settings
```

---

## 6. Screen Specifications

### 6.1 Splash Screen
- FuelProof logo centered, white background
- 1.8s display, then route based on auth state
- No animation beyond a single fade-in

### 6.2 Login
- Full white screen, logo top-center
- Email + Password fields, Inter 400 14px placeholder
- Primary CTA button full-width, teal, 52px height
- "Forgot password?" text link below button, slate grey
- No social login, no clutter

### 6.3 Home Screen
- Top bar: "FuelProof" wordmark left, notification bell right
- Greeting strip: "Good morning, [Name]" in Inter 600 20px
- **Quick Action Card** — large teal card, "Scan to Start" with QR icon, 100% width
- Recent Transactions — card list, last 3 entries, ghost state if empty
- Nearby Station strip — horizontal scroll, minimal cards with distance badge
- Bottom nav: Home · Scan · History · Profile

### 6.4 QR Scan Screen
- Full-screen camera view, dark overlay with square crop guide
- Single instruction label at bottom: "Scan the dispenser QR code"
- No extra controls. Cancel button top-left only.
- On successful scan — haptic feedback, transitions to Live Session

### 6.5 Live Session Screen ← most critical screen
- Station name + nozzle ID in subheader
- **Hero number** — live litre counter, Inter 700 64px, teal, updating in real time
- Two sub-readings below hero:
  - Sensor 1 (Dispenser Side) — smaller, navy
  - Sensor 2 (Nozzle Side) — smaller, navy
- Delta indicator — if values match: green pill "Verified". If mismatch: red pulsing pill "Discrepancy Detected"
- Amount in PKR — calculated in real time below the litre counter
- Session auto-ends when next customer scans. No manual action required.
- On session end → transition to Receipt screen

### 6.6 Receipt Screen
- Summary card: Station, Date/Time, Litres, Amount, Verification status
- Verification badge: large green checkmark + "Transaction Verified" or red alert
- "Save Receipt" button — saves to History
- Share icon top right

### 6.7 Transaction History
- Filter bar: All · Verified · Flagged
- Card list — date, station name, litres, PKR amount, status badge
- Tap to expand full receipt detail

### 6.8 Profile and Settings
- Avatar initials circle (no photo upload for MVP)
- Name, email, vehicle count
- Settings rows: Notifications · Language · Change Password · About · Logout

---

## 7. Key Interaction Patterns

**Live data updates**
Socket.io events update the hero litre counter directly in the widget state. No polling. The number increments smoothly without screen rebuilds.

**Fraud alert**
When delta exceeds threshold, the delta badge transitions from green to red with a subtle pulse animation. A bottom sheet slides up with the alert detail. It does not block the session — the customer can still see the live data.

**Session handoff**
When the next customer scans the QR, the current customer's session closes and the screen transitions to the Receipt screen with a brief "Session ended — another customer has connected" banner.

**Empty states**
Every list screen has a defined empty state — an icon, a one-line message, and where appropriate a CTA. No blank white screens.

**Loading states**
Skeleton loaders only. No spinners except for single-action confirmation buttons.

---

## 8. Flutter Implementation Notes

```
State Management     Riverpod
Navigation           GoRouter
HTTP Client          Dio
WebSocket            socket_io_client
Backend Auth         Firebase Auth
Database             Cloud Firestore
QR Scanner           mobile_scanner
Local Storage        flutter_secure_storage
Charts               fl_chart
Linting              flutter_lints (strict)
```

**Folder structure**

```
lib/
├── core/
│   ├── constants/      (colors, text styles, spacing)
│   ├── theme/          (AppTheme, ThemeData)
│   ├── router/         (GoRouter config)
│   └── utils/          (formatters, validators)
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/       (Firebase, Socket, API)
├── features/
│   ├── auth/
│   ├── home/
│   ├── session/        (QR + live session + receipt)
│   ├── history/
│   ├── profile/
│   └── admin/
└── shared/
    ├── widgets/        (buttons, cards, badges, inputs)
    └── providers/
```

---

## 9. Design Constraints and Decisions

| Decision | Rationale |
|---|---|
| Inter typeface only | Single font family, no mixing. Keeps visual weight consistent throughout |
| No dark mode in v1 | Adds significant testing overhead for a demo-first product. Revisit post-panel |
| No onboarding carousel | Users arrive at the app with context. Carousels are skipped 90% of the time |
| Bottom nav limited to 4 items | Anything beyond 4 degrades discoverability on mobile |
| Teal as single accent | One accent colour enforces hierarchy. Two accents create visual noise |
| Full-width primary buttons | Touch targets on mobile need to be generous. Full-width removes all ambiguity |

---

## 10. Quality Standards

- All tap targets minimum **48 x 48px**
- All text passes **WCAG AA contrast** ratio at minimum
- No hardcoded strings — all text via constants file
- No `print()` statements in production code
- Every feature widget has its own folder with `widget`, `controller`, and `state` files
- Zero tolerance for `setState` in business logic — state lives in Riverpod providers only

---

*FuelProof · IoT-Based Fuel Dispenser with Verification · SZABIST University Islamabad · Spring 2026*