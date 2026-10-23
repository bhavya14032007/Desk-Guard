# Smart Library Management System — Supabase Backend & iOS Setup Guide

Follow this step-by-step guide to set up the Supabase database and configure the native iOS application.

---

## Part 1: Supabase Backend Setup

### Option A: Using the Supabase Web Dashboard (Recommended for Hackathons)

1. **Log in or Sign Up**:
   Navigate to [https://supabase.com](https://supabase.com) and sign in.
2. **Create a Project**:
   - Project Name: `Smart Library`
   - Database Password: Create a strong password
   - Region: Select your closest region (e.g., US East / EU Central)
3. **Execute the Migration**:
   - Open **SQL Editor** from the left sidebar.
   - Click **+ New Query**.
   - Copy and paste the complete content of [`supabase/migrations/20241024000000_initial_schema_and_rpcs.sql`](../supabase/migrations/20241024000000_initial_schema_and_rpcs.sql).
   - Click **Run** (or `Cmd+Enter`).
   - Verify all tables (`libraries`, `profiles`, `seats`, `visits`, `bookings`) and RPCs are created.
4. **Seed the Database**:
   - In **SQL Editor**, click **+ New Query**.
   - Copy and paste the content of [`supabase/seed.sql`](../supabase/seed.sql).
   - Click **Run**.
   - This inserts the demo Central Library (`11111111-1111-4111-8111-111111111111`) and 48 sample seats with coordinates across 2 floors and 4 zones.
5. **Set up the Scheduled Expiration (Optional pg_cron)**:
   - In **SQL Editor**, run the script from [`supabase/schedule_expiration.sql`](../supabase/schedule_expiration.sql).
   - *Note*: Even if `pg_cron` is disabled on your Supabase tier, the database remains strictly correct because `expire_stale_bookings()` is automatically invoked inside every RPC call.
6. **Enable Realtime**:
   - Go to **Database** -> **Replication**.
   - Ensure the Realtime server is active.
7. **Obtain API Keys**:
   - Go to **Project Settings** -> **API**.
   - Copy **Project URL** (e.g. `https://xyzcompany.supabase.co`).
   - Copy **Project API Keys** -> `anon` / `public` key.

---

### Option B: Using the Supabase CLI (Local Development)

If you have the Supabase CLI installed on your machine:
```bash
cd SmartLibrary
supabase start
supabase db reset
```

---

## Part 2: Running Automated Database Tests

To verify that all 13 core business rules (one-user-one-seat, concurrency lock, 20-min grace period, duplicate scans) are working:

1. Open **SQL Editor** in your Supabase Dashboard.
2. Copy and paste [`supabase/tests/database_tests.sql`](../supabase/tests/database_tests.sql).
3. Click **Run**.
4. Check the **Results / Messages** console. You will see:
   ```text
   === STARTING SMART LIBRARY DATABASE TEST SUITE ===
   [PASS] Demo library verified
   [PASS] Seed seats retrieved: Seat1, Seat2
   [PASS] Rejected booking without active entry visit
   [PASS] Fresh entry scan successful
   [PASS] Duplicate entry scan properly identified as already_inside
   [PASS] Seat A1 successfully booked
   [PASS] One-user one-seat rule enforced (ALREADY_HAS_SEAT caught)
   [PASS] Seat collision prevented (SEAT_UNAVAILABLE caught)
   [PASS] User2 seat map correctly reports Seat A1 as occupied and not mine
   [PASS] User1 seat map correctly reports Seat A1 as mine
   [PASS] Grace period initiated
   [PASS] Return before deadline restored booking
   [PASS] Return after deadline correctly identified: grace_expired_new_visit
   [PASS] Seat A1 automatically released and made available
   [PASS] Permanent exit completed
   [PASS] User state is clean after exit
   === ALL 13 TEST SUITE CASES PASSED WITH 100% SUCCESS ===
   ```

---

## Part 3: iOS Configuration

1. In the `SmartLibrary/ios/` directory, open `Config.xcconfig` (or copy `Config.example.xcconfig` to `Config.xcconfig`).
2. Fill in your project credentials:
   ```xcconfig
   SUPABASE_URL = https://your-actual-project-ref.supabase.co
   SUPABASE_PUBLISHABLE_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6...
   ```
3. Never commit `Config.xcconfig` to public repositories (it is listed in `.gitignore`).
