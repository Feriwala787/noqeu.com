# ⏳ NoQeu

> **Stop Waiting, Start Living.**
> A lightweight, QR-based digital token and queue management system for local service businesses.

NoQeu eliminates physical waiting rooms. Instead of a complex calendar, it uses a **blind-slot token model**: a customer scans a shop QR, taps one button, and receives an estimated service window. The platform enforces discipline with a strike system so genuine customers are prioritized and owner time is protected.

---

## ✨ Core Features

- **🔒 Private shop access (QR-first):** Users can only access and book shops they have physically scanned.
- **⚡ One-tap token booking:** No calendar UX for end users; backend calculates next available slot from queue pressure.
- **🚫 Strike enforcement:** If users no-show, strikes increase. At 2+ strikes, online booking is blocked.
- **🔔 Automated reminders:** Push reminder 30 minutes before slot start.
- **💰 Ad-supported customer flow:** Interstitial ad can be shown at booking confirmation.

---

## 🛠️ Tech Stack

**Frontend (Mobile App)**
- React Native or Flutter
- Firebase Phone Auth (OTP)
- Google AdMob

**Backend (API & Logic)**
- Node.js + Express
- MongoDB + Mongoose
- `node-cron`
- Firebase Admin SDK (Auth verify + FCM)

---

## 🧱 Canonical Data Model (MongoDB)

### `users`
- `_id: ObjectId`
- `firebaseUid: String` (unique)
- `phone: String`
- `strikes: Number` (default `0`)
- `accessedShops: ObjectId[]` (shop references discovered by QR scan)
- `createdAt: Date`

### `shops`
- `_id: ObjectId`
- `ownerId: String` (Firebase UID of shop owner)
- `name: String`
- `occupation: String` (e.g., barber, mechanic, clinic, salon, consultant)
- `totalSeats: Number`
- `avgTimePerCustomer: Number` (minutes)
- `isAcceptingOnline: Boolean` (default `true`)
- `qrCodeString: String` (deep-link payload, e.g., `noqeu://shop/<id>`)

### `appointments` (with TTL)
- `_id: ObjectId`
- `shopId: ObjectId` (ref `shops`)
- `userId: ObjectId | null` (null for offline walk-ins)
- `slotStart: Date`
- `slotEnd: Date`
- `status: 'Pending' | 'Completed' | 'No-Show' | 'Cancelled'`
- `expireAt: Date` (TTL index; delete automatically after service window + 24h)

**TTL Index:**
```js
// appointments
{ expireAt: 1 }, { expireAfterSeconds: 0 }
```

---

## ⚙️ Backend API Logic

### 1) Next Slot Calculation
`GET /api/shops/:id/next-slot`

1. Validate shop.
2. If `isAcceptingOnline === false`, return walk-in only message.
3. Count today's pending appointments for the shop.
4. Compute:
   - `groupsAhead = Math.ceil(totalPending / totalSeats)`
   - `waitTimeMinutes = groupsAhead * avgTimePerCustomer`
   - `expectedStartTime = now + waitTimeMinutes`
   - `expectedEndTime = expectedStartTime + avgTimePerCustomer`
5. Return an estimated slot window.

---

### 2) Book Appointment
`POST /api/appointments/book`

1. Verify Firebase token.
2. Load user and enforce strike policy (`strikes >= 2 => HTTP 403`).
3. Recalculate slot at write time (race-safe).
4. Create appointment with `status='Pending'`.
5. Set `expireAt = slotEnd + 24h`.

---

### 3) Register Offline Walk-in
`POST /api/appointments/offline`

- Owner adds walk-in tokens via dashboard quick action.
- Create appointment with `userId = null`.
- Use same slot allocation logic so offline entries consume queue capacity.

---

### 4) Appointment Action (Owner)
`PUT /api/appointments/:id/action`

Payload:
```json
{ "action": "Completed" }
```
or
```json
{ "action": "No-Show" }
```

Rules:
- `Completed` -> mark completed.
- `No-Show` -> mark no-show and increment customer strikes (if `userId` exists).

---

## ⏱️ Cron Jobs (`cron.js`)

### 30-minute Reminder Job
- Schedule: every minute (`* * * * *`).
- Target range: `now + 30m` to `now + 31m`.
- Query: pending appointments where `slotStart` is in target range.
- Send FCM message:
  - **Title:** `Your turn is almost here!`
  - **Body:** `Your slot at [Shop Name] starts in 30 mins. Reach on time or cancel now to avoid a strike.`

---

## 📱 Frontend Flow

### QR / Deep-Link Flow
- QR example: `noqeu.com/shop/<shopId>` or app scheme `noqeu://shop/<shopId>`.
- If logged out: OTP -> persist accessed shop -> navigate to shop detail.
- If logged in: persist accessed shop -> direct navigation.

### Customer Flow
1. **Home:** show `accessedShops`.
2. **Shop Detail:** fetch `/next-slot` and show CTA like `Get Token (Est: 2:00 PM)`.
3. **Confirm:** show strike warning modal.
4. **Monetization step:** show AdMob interstitial.
5. **Active Token:** countdown + conditional cancel button (`>30 min remaining`).

### Owner Dashboard Flow
- Show today's pending list (online + walk-ins).
- Quick controls:
  - `+1 Walk-In`
  - `Pause Queue` toggle (`isAcceptingOnline`)
- Gesture actions on queue item:
  - Mark Done -> `Completed`
  - Mark No-Show -> `No-Show` + strike increment

---

## 🧭 Business Scope Note

The queue engine is **occupation-agnostic**. "Barber" is only an example. During shop onboarding, owners register:
- Business name
- Occupation/service type
- Seat/service capacity
- Average service duration

This keeps NoQeu reusable for any local service business with waiting lines.

---

## 🚀 Flutter Starter Included

A Flutter starter client now exists in `mobile/` with:
- API client + repository abstraction
- Home screen for accessed shops
- Shop detail screen for next-slot + booking confirmation
- Shared slot time formatter + unit test

Run locally:
```bash
cd mobile
flutter pub get
flutter test
flutter run
```

### Mobile Config

Set API base URL at build/run time:
```bash
flutter run --dart-define=API_BASE_URL=https://your-api.example.com/api
```



### Next functionality milestones

- Implement deep-link ingestion (`noqeu://shop/<id>`) and persisted accessed-shop writes on login complete.
- Add AdMob interstitial trigger between booking confirm and active-token navigation.
- Add owner dashboard app surfaces: `+1 Walk-In`, queue pause toggle, swipe-to-complete/no-show.
- Add Firebase Auth token injection into API client and secure protected endpoints.
- Add offline caching for recently accessed shops and active token state recovery after app restart.


### Deep-link bootstrap (implemented)

- App now parses `noqeu://shop/<id>` and `https://noqeu.com/shop/<id>` links.
- If user is logged out, app routes to OTP login first, then opens scanned shop.
- If user is logged in, app navigates directly to the scanned shop detail flow.


### Owner dashboard MVP (implemented)

- Added owner dashboard screen with `+1 Walk-In` action.
- Added swipe actions for `Completed` and `No-Show` queue updates.
- Added pause queue UI toggle for temporary online-booking control.

### Local active-token persistence (implemented)

- Added app-level state with shared preferences hydration.
- Active token is saved after booking and restored on app restart.
- Active token can be reopened from home and cleared on cancel.

### Mock-first mode (implemented)

To run without real backend APIs (default):
```bash
flutter run --dart-define=USE_MOCK_API=true
```

To switch to real API later:
```bash
flutter run --dart-define=USE_MOCK_API=false --dart-define=API_BASE_URL=https://your-api.example.com/api
```

The app now supports both mock and real implementations via a service layer toggle.

### Production readiness checklist (remaining)

- Firebase Auth integration with real ID token injection and refresh handling.
- Push notifications (FCM) for 30-minute reminders and foreground handling.
- Analytics + crash reporting (Firebase Analytics/Crashlytics/Sentry).
- E2E tests for customer and owner flows (integration_test).
- Backend contract tests and API schema validation.
- CI pipeline: lint, test, build APK/IPA artifacts.
- App hardening: offline retry queue, connectivity awareness, and secure local storage for sensitive tokens.

### Safety upgrades (implemented in mock-compatible form)

- Added secure token storage via `flutter_secure_storage` through `AuthService`.
- Added auth interceptor to inject bearer token and refresh mock session near expiry.
- Added staged reminder hints (60/30/10 minute windows) in Active Token UX.

This keeps flows mock-friendly now while matching production auth/reminder architecture later.

### Comfort & safety UX upgrades (implemented)

- Queue confidence indicators on shop detail: people ahead, seats active, confidence level, and last updated timestamp.
- Better error recovery on shop detail with retry action if slot fetch fails.
- Owner guardrails: explicit no-show confirmation and undo snackbar after queue actions.
