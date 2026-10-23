# Smart Library Management System — API Contract & Data Dictionary

This document details the PostgreSQL RPC signatures, request parameters, response structures, and exact Swift Codable mappings.

---

## 1. Demo Constants

- **Demo Library UUID**: `11111111-1111-4111-8111-111111111111`
- **Library Name**: `Central Library`
- **Timezone**: `America/New_York` (Stored in UTC in PostgreSQL)
- **Grace Period Duration**: `20 minutes`
- **Realtime Broadcast Topic**: `library:11111111-1111-4111-8111-111111111111`
- **Realtime Broadcast Event**: `seat-map-changed`

---

## 2. QR Code Payloads

QR codes are structured with strict pipe (`|`) delimiters:

| Action | Payload String | Description |
|---|---|---|
| **ENTRY** | `SLMS\|ENTRY\|11111111-1111-4111-8111-111111111111` | Scanned at entrance turnstiles |
| **EXIT** | `SLMS\|EXIT\|11111111-1111-4111-8111-111111111111` | Scanned at exit turnstiles |

---

## 3. RPC Functions & Swift Mapping

### 3.1 `get_seat_map(p_library_id UUID)`
Returns live seat layout and personal booking status for the specified library.

- **PostgreSQL Return Type**: `JSONB` (Array of seat objects)
- **Swift Decodable Model**: `[SeatItem]`

```json
[
  {
    "seat_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "label": "A1",
    "floor_number": 1,
    "zone": "Main Reading Room",
    "x_position": 12.0,
    "y_position": 18.0,
    "features": ["power_outlet", "lamp"],
    "availability_status": "available", // "available" | "occupied" | "temporarily_away" | "mine"
    "is_mine": false,
    "my_booking_status": null,          // "active" | "temporarily_away" | null
    "grace_deadline": null              // ISO-8601 UTC string or null
  }
]
```

---

### 3.2 `get_my_state(p_library_id UUID)`
Returns the authenticated student's active visit and seat reservation state.

- **PostgreSQL Return Type**: `JSONB` (Object)
- **Swift Decodable Model**: `MyLibraryState`

```json
{
  "visit_id": "d3b07384-d113-4674-a524-77e4cb52467b",
  "visit_status": "inside",             // "inside" | "away" | null
  "entered_at": "2024-10-24T00:30:00Z",
  "booking_id": "e6a2b890-a352-45e1-88bc-467812903abc",
  "seat_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "seat_label": "A1",
  "booking_status": "active",           // "active" | "temporarily_away" | null
  "grace_deadline": null                // ISO-8601 UTC string or null
}
```

---

### 3.3 `scan_entry(p_library_id UUID)`
Validates authenticated entry through the library turnstile.

- **PostgreSQL Return Type**: `JSONB` (Object)
- **Swift Decodable Model**: `ScanEntryResponse`

| Result Value | Scenario | Client Action |
|---|---|---|
| `"entered"` | First entry; fresh visit created | Open Interactive Seat Map |
| `"already_inside"` | Repeated scan while visit is active | Show info message; keep current session |
| `"returned"` | Returned before 20-min grace deadline | Seat restored to `active`; redirect to My Seat |
| `"grace_expired_new_visit"` | Returned after 20-min grace expired | Inform user seat was freed; open Seat Map |

---

### 3.4 `book_seat(p_seat_id UUID)`
Atomically reserves a seat for an inside student using row-level locking (`FOR UPDATE`).

- **PostgreSQL Return Type**: `JSONB` (Object)
- **Swift Decodable Model**: `BookSeatResponse`

```json
{
  "booking_id": "e6a2b890-a352-45e1-88bc-467812903abc",
  "seat_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "seat_label": "A1",
  "booking_status": "active",
  "created_at": "2024-10-24T00:35:00Z"
}
```

---

### 3.5 `start_grace_period(p_library_id UUID)`
Initiates a 20-minute temporary absence. Preserves the user's seat while marking the visit as `away`.

- **PostgreSQL Return Type**: `JSONB` (Object)
- **Swift Decodable Model**: `StartGraceResponse`

```json
{
  "booking_id": "e6a2b890-a352-45e1-88bc-467812903abc",
  "seat_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "booking_status": "temporarily_away",
  "grace_deadline": "2024-10-24T00:55:00Z"
}
```

---

### 3.6 `leave_library(p_library_id UUID)`
Permanently leaves the library. Atomically completes the visit and frees any active seat booking.

- **PostgreSQL Return Type**: `JSONB` (Object)
- **Swift Decodable Model**: `LeaveLibraryResponse`

```json
{
  "result": "success",
  "visit_status": "completed",
  "booking_status": "completed",
  "seat_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
```

---

### 3.7 `get_my_history(p_library_id UUID, p_limit INTEGER DEFAULT 20)`
Retrieves sanitized historical visit and reservation logs for the authenticated student.

- **PostgreSQL Return Type**: `JSONB` (Array of visit objects)
- **Swift Decodable Model**: `[VisitHistoryItem]`

---

## 4. Standard Backend Error Codes

When an RPC function aborts, it raises a PostgreSQL exception with one of the following exact string tokens. `AppError.swift` maps each token to a human-friendly UI message:

| Error Code | Meaning | User Feedback |
|---|---|---|
| `UNAUTHORIZED` | Client lacks valid JWT | "Please sign in to access library services." |
| `INVALID_LIBRARY` | Unknown library UUID | "Unrecognized library QR code." |
| `INVALID_SEAT` | Seat ID does not exist | "The selected seat could not be found." |
| `SEAT_DISABLED` | `is_active = false` | "This seat is undergoing maintenance." |
| `NO_ACTIVE_VISIT` | User has not entered turnstile | "You must scan the library ENTRY QR code before reserving a seat." |
| `NOT_INSIDE_LIBRARY` | Visit is in `away` status | "You are currently marked as stepped out. Scan ENTRY QR to resume." |
| `SEAT_UNAVAILABLE` | Seat already booked by another user | "This seat was just reserved by another student. Please pick another seat." |
| `ALREADY_HAS_SEAT` | User already holds an active seat | "You already hold an active seat reservation. Release it first before choosing another." |
| `NO_ACTIVE_BOOKING` | Attempted step-out without a seat | "You do not have an active seat reservation." |
| `GRACE_PERIOD_EXPIRED` | Deadline passed | "Your 20-minute temporary away grace period has expired." |
