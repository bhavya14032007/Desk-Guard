# Smart Library Management System — Testing Guide & Verification Matrix

This guide outlines the validation procedures for the Smart Library system across database integrity, concurrency enforcement, camera/simulator QR testing, and session lifecycles.

---

## 1. Automated PostgreSQL Test Suite

The automated test script [`supabase/tests/database_tests.sql`](../supabase/tests/database_tests.sql) verifies the entire business logic within a single rolled-back transaction.

### Covered Scenarios

| # | Test Case | Expected Result | Enforced Mechanism |
|---|---|---|---|
| 1 | Demo library verification | Library UUID `11111111-...` exists | Foreign key check |
| 2 | Booking without entry | Throws `NO_ACTIVE_VISIT` | RPC validation against `visits` |
| 3 | Fresh entry scan | Returns `result: "entered"` | Insert into `visits(status='inside')` |
| 4 | Duplicate entry scan | Returns `result: "already_inside"` | Idempotency guard on active visit |
| 5 | Valid seat booking | Returns `booking_status: "active"` | Row lock `FOR UPDATE` + Insert |
| 6 | One-user one-seat rule | Throws `ALREADY_HAS_SEAT` | Partial unique index `uq_active_user_booking` |
| 7 | Concurrent seat booking | Throws `SEAT_UNAVAILABLE` | Partial unique index `uq_active_seat_booking` |
| 8 | Privacy & seat map state | Seat is marked `occupied` for others, `mine` for owner | RPC dynamic masking |
| 9 | Start 20-min grace period | Status `temporarily_away`, `grace_deadline = now() + 20m` | Database clock arithmetic |
| 10 | Return before deadline | Scan ENTRY restores seat to `active`, returns `returned` | Expiry check + state update |
| 11 | Expiry after deadline | Scan ENTRY returns `grace_expired_new_visit`, frees seat | `expire_stale_bookings()` cleanup |
| 12 | Permanent exit | Marks visit and booking `completed`, frees seat | `leave_library` atomic release |
| 13 | State after exit | `get_my_state` returns null fields | Clean state reset |

### How to Run:
Paste the content of [`supabase/tests/database_tests.sql`](../supabase/tests/database_tests.sql) into the Supabase Dashboard SQL Editor and click **Run**.

---

## 2. iOS Simulator Testing (Without Physical Camera)

When running the iOS application in the Xcode Simulator (or on Mac), the camera hardware is simulated.

To make hackathon testing immediate:
1. Tap **Scan QR Code** on the Home screen.
2. The scanner view displays a **"SIMULATOR DEMO CONTROLS"** panel at the bottom:
   - **ENTRY QR Button**: Injects payload `SLMS|ENTRY|11111111-1111-4111-8111-111111111111`.
   - **EXIT QR Button**: Injects payload `SLMS|EXIT|11111111-1111-4111-8111-111111111111`.
3. Tapping **ENTRY QR**:
   - Triggers `scan_entry` on Supabase.
   - Automatically navigates to the **Interactive Seat Map** with 48 realistic seats.
4. Select any available green seat (e.g., `A1`), inspect amenities (Power Outlet, Quiet Zone), and tap **Reserve Seat**.
5. Switch to **My Seat**:
   - Tap **Step Out (20 Min Grace)**.
   - Observe the live circular countdown timer counting down from 20 minutes based on the database server deadline.
6. Tap **Scan ENTRY QR to Return**:
   - Use the **ENTRY QR** simulation button.
   - Observe the toast: *"Welcome back! Your seat reservation has been restored."*

---

## 3. Physical iOS Device Testing (With Real Camera)

To test with a physical iPhone camera:
1. Generate QR codes for the demo payloads using any free online QR generator or terminal tool:
   - **ENTRY QR**: `SLMS|ENTRY|11111111-1111-4111-8111-111111111111`
   - **EXIT QR**: `SLMS|EXIT|11111111-1111-4111-8111-111111111111`
2. Display the generated QR codes on a monitor screen.
3. Open the Smart Library app on your iPhone.
4. Tap the prominent green **Scan QR Code** button.
5. Point the camera at the ENTRY QR on your monitor.
6. The app parses the payload, validates camera permission, vibrates on detection, and processes the check-in immediately.

---

## 4. Concurrency & Integrity Edge Case Matrix

| Edge Case | Simulated Action | Expected System Behavior |
|---|---|---|
| **Two students tap Reserve on the same seat simultaneously** | Run `book_seat(seat_id)` for User 1 and User 2 in parallel | PostgreSQL `FOR UPDATE` serializes the requests. First user succeeds (`active`); second user receives `SEAT_UNAVAILABLE` error with a prompt to pick another seat. |
| **Student exits app while in 20-min grace period** | Kill the iOS app, wait 10 minutes, relaunch | App queries `get_my_state()` on launch, retrieves the database `grace_deadline`, and recalculates remaining seconds accurately. |
| **Student returns 25 minutes after stepping out** | Grace period expired. Scan ENTRY QR | Server detects `now() > grace_deadline`. Old booking marked `expired`. Visit reset to fresh entry. User receives notification that their previous seat was freed and opens the seat map. |
| **Student scans random Wi-Fi or website QR code** | Scan invalid QR format | Scanner immediately rejects with *"Payload must follow format 'SLMS\|ENTRY\|<UUID>' or 'SLMS\|EXIT\|<UUID>'"*. |
| **Student scans QR of a different library** | Scan `SLMS\|ENTRY\|22222222-...` | Scanner rejects with *"This QR code belongs to a different library. Please scan Central Library's QR code."* |
