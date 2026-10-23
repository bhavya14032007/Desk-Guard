-- ============================================================================
-- SMART LIBRARY MANAGEMENT SYSTEM - SUPABASE POSTGRESQL SCHEMA & RPCS
-- Migration: 20241024000000_initial_schema_and_rpcs.sql
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. TABLES
-- ----------------------------------------------------------------------------

-- Libraries table
CREATE TABLE IF NOT EXISTS public.libraries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    timezone TEXT NOT NULL DEFAULT 'UTC',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Profiles table (synced from auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'librarian', 'admin')),
    preferences JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Seats table
CREATE TABLE IF NOT EXISTS public.seats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    library_id UUID NOT NULL REFERENCES public.libraries(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    floor_number INT NOT NULL DEFAULT 1,
    zone TEXT NOT NULL DEFAULT 'Main Hall',
    x_position NUMERIC(5,2) NOT NULL CHECK (x_position >= 0 AND x_position <= 100),
    y_position NUMERIC(5,2) NOT NULL CHECK (y_position >= 0 AND y_position <= 100),
    features JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_library_seat_label UNIQUE (library_id, label)
);

-- Visits table
CREATE TABLE IF NOT EXISTS public.visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    library_id UUID NOT NULL REFERENCES public.libraries(id) ON DELETE CASCADE,
    entered_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    status TEXT NOT NULL DEFAULT 'inside' CHECK (status IN ('inside', 'away', 'completed')),
    exited_at TIMESTAMPTZ
);

-- Bookings table
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    seat_id UUID NOT NULL REFERENCES public.seats(id) ON DELETE CASCADE,
    visit_id UUID NOT NULL REFERENCES public.visits(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'temporarily_away', 'completed', 'expired', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    grace_deadline TIMESTAMPTZ,
    released_at TIMESTAMPTZ
);

-- ----------------------------------------------------------------------------
-- 2. PARTIAL UNIQUE INDEXES FOR CONCURRENCY & INTEGRITY
-- ----------------------------------------------------------------------------

-- Enforce: A user can only have one active/away visit per library at a time
CREATE UNIQUE INDEX IF NOT EXISTS uq_active_user_visit 
    ON public.visits (user_id, library_id) 
    WHERE status IN ('inside', 'away');

-- Enforce: A seat can only have one active/temporarily_away booking at a time
CREATE UNIQUE INDEX IF NOT EXISTS uq_active_seat_booking 
    ON public.bookings (seat_id) 
    WHERE status IN ('active', 'temporarily_away');

-- Enforce: A user can only hold one active/temporarily_away booking at a time
CREATE UNIQUE INDEX IF NOT EXISTS uq_active_user_booking 
    ON public.bookings (user_id) 
    WHERE status IN ('active', 'temporarily_away');

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_seats_library_id ON public.seats(library_id);
CREATE INDEX IF NOT EXISTS idx_visits_user_library ON public.visits(user_id, library_id);
CREATE INDEX IF NOT EXISTS idx_bookings_user_status ON public.bookings(user_id, status);
CREATE INDEX IF NOT EXISTS idx_bookings_seat_status ON public.bookings(seat_id, status);
CREATE INDEX IF NOT EXISTS idx_bookings_grace_deadline ON public.bookings(grace_deadline) WHERE status = 'temporarily_away';

-- ----------------------------------------------------------------------------
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- ----------------------------------------------------------------------------

ALTER TABLE public.libraries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Libraries: Read-only for all authenticated users
CREATE POLICY "Authenticated users can read libraries"
    ON public.libraries FOR SELECT
    TO authenticated
    USING (true);

-- Seats: Read-only for all authenticated users
CREATE POLICY "Authenticated users can read seats"
    ON public.seats FOR SELECT
    TO authenticated
    USING (true);

-- Profiles: Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (id = auth.uid());

-- Profiles: Users can update their own profile (prevent changing role)
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (
        id = auth.uid() AND 
        role = (SELECT role FROM public.profiles WHERE id = auth.uid())
    );

-- Visits: Users can view their own visits
CREATE POLICY "Users can view own visits"
    ON public.visits FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Bookings: Users can view their own bookings
CREATE POLICY "Users can view own bookings"
    ON public.bookings FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- NOTE: Direct INSERT/UPDATE/DELETE on visits & bookings by authenticated role
-- is purposefully disallowed. All modifications must go through SECURITY DEFINER RPCs!

-- ----------------------------------------------------------------------------
-- 4. PROFILE AUTO-CREATION TRIGGER ON AUTH SIGNUP
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public, auth, extensions
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        'student'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 5. PRIVATE EXPIRY HELPER FUNCTION
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.expire_stale_bookings()
RETURNS INTEGER
SECURITY DEFINER
SET search_path = public, auth, extensions
LANGUAGE plpgsql
AS $$
DECLARE
    v_now TIMESTAMPTZ := timezone('utc'::text, now());
    v_expired_count INTEGER := 0;
    v_expired_rec RECORD;
BEGIN
    -- Find and expire stale bookings where grace_deadline <= now()
    FOR v_expired_rec IN
        SELECT b.id AS booking_id, b.visit_id, b.seat_id
        FROM public.bookings b
        WHERE b.status = 'temporarily_away'
          AND b.grace_deadline <= v_now
        FOR UPDATE OF b
    LOOP
        -- Update booking status to expired
        UPDATE public.bookings
        SET status = 'expired',
            released_at = v_now
        WHERE id = v_expired_rec.booking_id;

        -- Update corresponding visit to completed if it is still away
        UPDATE public.visits
        SET status = 'completed',
            exited_at = v_now
        WHERE id = v_expired_rec.visit_id
          AND status = 'away';

        v_expired_count := v_expired_count + 1;
    END LOOP;

    RETURN v_expired_count;
END;
$$;

-- Revoke direct execute on helper from public
REVOKE ALL ON FUNCTION public.expire_stale_bookings() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.expire_stale_bookings() TO authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 6. RPC: get_seat_map(p_library_id UUID)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_seat_map(p_library_id UUID)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public, auth, extensions
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_result JSONB;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    -- Clean up any expired reservations first
    PERFORM public.expire_stale_bookings();

    -- Validate library exists
    IF NOT EXISTS (SELECT 1 FROM public.libraries WHERE id = p_library_id) THEN
        RAISE EXCEPTION 'INVALID_LIBRARY';
    END IF;

    -- Aggregate seat layout and live statuses
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'seat_id', s.id,
                'label', s.label,
                'floor_number', s.floor_number,
                'zone', s.zone,
                'x_position', s.x_position,
                'y_position', s.y_position,
                'features', s.features,
                'availability_status', CASE
                    WHEN b.id IS NULL THEN 'available'
                    WHEN b.user_id = v_user_id THEN 'mine'
                    WHEN b.status = 'temporarily_away' THEN 'temporarily_away'
                    ELSE 'occupied'
                END,
                'is_mine', (b.user_id = v_user_id),
                'my_booking_status', CASE WHEN b.user_id = v_user_id THEN b.status ELSE NULL END,
                'grace_deadline', CASE 
                    WHEN b.status = 'temporarily_away' THEN to_char(b.grace_deadline, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
                    ELSE NULL 
                END
            ) ORDER BY s.floor_number, s.label
        ),
        '[]'::jsonb
    ) INTO v_result
    FROM public.seats s
    LEFT JOIN public.bookings b 
        ON b.seat_id = s.id 
       AND b.status IN ('active', 'temporarily_away')
    WHERE s.library_id = p_library_id
      AND s.is_active = true;

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_seat_map(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 7. RPC: get_my_state(p_library_id UUID)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_my_state(p_library_id UUID)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public, auth, extensions
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_visit RECORD;
    v_booking RECORD;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    -- Clean up expired bookings first
    PERFORM public.expire_stale_bookings();

    -- Find active/away visit
    SELECT id, status, entered_at
    INTO v_visit
    FROM public.visits
    WHERE user_id = v_user_id
      AND library_id = p_library_id
      AND status IN ('inside', 'away')
    ORDER BY entered_at DESC
    LIMIT 1;

    IF v_visit.id IS NULL THEN
        -- No active visit
        RETURN jsonb_build_object(
            'visit_id', NULL,
            'visit_status', NULL,
            'entered_at', NULL,
            'booking_id', NULL,
            'seat_id', NULL,
            'seat_label', NULL,
            'booking_status', NULL,
            'grace_deadline', NULL
        );
    END IF;

    -- Find active/away booking
    SELECT b.id AS booking_id, b.seat_id, b.status AS booking_status, b.grace_deadline, s.label AS seat_label
    INTO v_booking
    FROM public.bookings b
    JOIN public.seats s ON s.id = b.seat_id
    WHERE b.user_id = v_user_id
      AND b.visit_id = v_visit.id
      AND b.status IN ('active', 'temporarily_away')
    LIMIT 1;

    RETURN jsonb_build_object(
        'visit_id', v_visit.id,
        'visit_status', v_visit.status,
        'entered_at', to_char(v_visit.entered_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'booking_id', v_booking.booking_id,
        'seat_id', v_booking.seat_id,
        'seat_label', v_booking.seat_label,
        'booking_status', v_booking.booking_status,
        'grace_deadline', CASE 
            WHEN v_booking.grace_deadline IS NOT NULL 
            THEN to_char(v_booking.grace_deadline, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') 
            ELSE NULL 
        END
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_state(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 8. RPC: scan_entry(p_library_id UUID)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.scan_entry(p_library_id UUID)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public, auth, extensions
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_visit RECORD;
    v_booking RECORD;
    v_now TIMESTAMPTZ := timezone('utc'::text, now());
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.libraries WHERE id = p_library_id) THEN
        RAISE EXCEPTION 'INVALID_LIBRARY';
    END IF;

    -- Process any stale bookings
    PERFORM public.expire_stale_bookings();

    -- Check if user already has a visit for this library
    SELECT id, status, entered_at
    INTO v_visit
    FROM public.visits
    WHERE user_id = v_user_id
      AND library_id = p_library_id
      AND status IN ('inside', 'away')
    LIMIT 1;

    IF v_visit.id IS NOT NULL THEN
        -- Case 1: Already inside
        IF v_visit.status = 'inside' THEN
            RETURN jsonb_build_object('result', 'already_inside');
        END IF;

        -- Case 2: Visit is 'away'. Check booking grace period
        IF v_visit.status = 'away' THEN
            SELECT id, status, grace_deadline
            INTO v_booking
            FROM public.bookings
            WHERE user_id = v_user_id
              AND visit_id = v_visit.id
              AND status = 'temporarily_away'
            LIMIT 1;

            IF v_booking.id IS NOT NULL AND v_booking.grace_deadline > v_now THEN
                -- Grace period valid: restore seat and mark inside
                UPDATE public.bookings
                SET status = 'active',
                    grace_deadline = NULL
                WHERE id = v_booking.id;

                UPDATE public.visits
                SET status = 'inside'
                WHERE id = v_visit.id;

                RETURN jsonb_build_object('result', 'returned');
            ELSE
                -- Grace period expired or no valid reservation: complete old visit, start new visit
                UPDATE public.visits
                SET status = 'completed',
                    exited_at = v_now
                WHERE id = v_visit.id;

                IF v_booking.id IS NOT NULL THEN
                    UPDATE public.bookings
                    SET status = 'expired',
                        released_at = v_now
                    WHERE id = v_booking.id;
                END IF;

                INSERT INTO public.visits (user_id, library_id, status, entered_at)
                VALUES (v_user_id, p_library_id, 'inside', v_now);

                RETURN jsonb_build_object('result', 'grace_expired_new_visit');
            END IF;
        END IF;
    END IF;

    -- Case 3: Fresh Entry
    INSERT INTO public.visits (user_id, library_id, status, entered_at)
    VALUES (v_user_id, p_library_id, 'inside', v_now);

    RETURN jsonb_build_object('result', 'entered');
END;
$$;

GRANT EXECUTE ON FUNCTION public.scan_entry(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 9. RPC: book_seat(p_seat_id UUID)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.book_seat(p_seat_id UUID)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public, auth, extensions
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_seat RECORD;
    v_visit RECORD;
    v_new_booking_id UUID;
    v_now TIMESTAMPTZ := timezone('utc'::text, now());
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    -- Expire stale bookings first
    PERFORM public.expire_stale_bookings();

    -- Lock and validate seat
    SELECT id, library_id, label, is_active
    INTO v_seat
    FROM public.seats
    WHERE id = p_seat_id
    FOR UPDATE;

    IF v_seat.id IS NULL THEN
        RAISE EXCEPTION 'INVALID_SEAT';
    END IF;

    IF NOT v_seat.is_active THEN
        RAISE EXCEPTION 'SEAT_DISABLED';
    END IF;

    -- Validate user has an active 'inside' visit at this library
    SELECT id, status
    INTO v_visit
    FROM public.visits
    WHERE user_id = v_user_id
      AND library_id = v_seat.library_id
      AND status = 'inside'
    LIMIT 1;

    IF v_visit.id IS NULL THEN
        -- Check if user has an 'away' visit or no visit at all
        IF EXISTS (SELECT 1 FROM public.visits WHERE user_id = v_user_id AND library_id = v_seat.library_id AND status = 'away') THEN
            RAISE EXCEPTION 'NOT_INSIDE_LIBRARY';
        ELSE
            RAISE EXCEPTION 'NO_ACTIVE_VISIT';
        END IF;
    END IF;

    -- Check if user already holds an active/away booking
    IF EXISTS (
        SELECT 1 FROM public.bookings 
        WHERE user_id = v_user_id 
          AND status IN ('active', 'temporarily_away')
    ) THEN
        RAISE EXCEPTION 'ALREADY_HAS_SEAT';
    END IF;

    -- Check if seat is currently occupied or reserved
    IF EXISTS (
        SELECT 1 FROM public.bookings 
        WHERE seat_id = p_seat_id 
          AND status IN ('active', 'temporarily_away')
    ) THEN
        RAISE EXCEPTION 'SEAT_UNAVAILABLE';
    END IF;

    -- Atomically insert booking
    INSERT INTO public.bookings (
        user_id,
        seat_id,
        visit_id,
        status,
        created_at
    )
    VALUES (
        v_user_id,
        p_seat_id,
        v_visit.id,
        'active',
        v_now
    )
    RETURNING id INTO v_new_booking_id;

    RETURN jsonb_build_object(
        'booking_id', v_new_booking_id,
        'seat_id', v_seat.id,
        'seat_label', v_seat.label,
        'booking_status', 'active',
        'created_at', to_char(v_now, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.book_seat(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 10. RPC: start_grace_period(p_library_id UUID)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.start_grace_period(p_library_id UUID)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public, auth, extensions
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_visit RECORD;
    v_booking RECORD;
    v_now TIMESTAMPTZ := timezone('utc'::text, now());
    v_deadline TIMESTAMPTZ := v_now + INTERVAL '20 minutes';
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    PERFORM public.expire_stale_bookings();

    -- Validate user has an active visit
    SELECT id, status
    INTO v_visit
    FROM public.visits
    WHERE user_id = v_user_id
      AND library_id = p_library_id
      AND status IN ('inside', 'away')
    LIMIT 1;

    IF v_visit.id IS NULL THEN
        RAISE EXCEPTION 'NO_ACTIVE_VISIT';
    END IF;

    -- If already away, do not extend deadline
    IF v_visit.status = 'away' THEN
        SELECT b.id AS booking_id, b.seat_id, b.status AS booking_status, b.grace_deadline
        INTO v_booking
        FROM public.bookings b
        WHERE b.user_id = v_user_id
          AND b.visit_id = v_visit.id
          AND b.status = 'temporarily_away'
        LIMIT 1;

        IF v_booking.booking_id IS NOT NULL THEN
            RETURN jsonb_build_object(
                'booking_id', v_booking.booking_id,
                'seat_id', v_booking.seat_id,
                'booking_status', v_booking.booking_status,
                'grace_deadline', to_char(v_booking.grace_deadline, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
            );
        END IF;
    END IF;

    -- Look for active booking to step away from
    SELECT id, seat_id
    INTO v_booking
    FROM public.bookings
    WHERE user_id = v_user_id
      AND visit_id = v_visit.id
      AND status = 'active'
    LIMIT 1;

    IF v_booking.id IS NULL THEN
        RAISE EXCEPTION 'NO_ACTIVE_BOOKING';
    END IF;

    -- Mark visit as away
    UPDATE public.visits
    SET status = 'away'
    WHERE id = v_visit.id;

    -- Set booking to temporarily_away with strictly 20 min server deadline
    UPDATE public.bookings
    SET status = 'temporarily_away',
        grace_deadline = v_deadline
    WHERE id = v_booking.id;

    RETURN jsonb_build_object(
        'booking_id', v_booking.id,
        'seat_id', v_booking.seat_id,
        'booking_status', 'temporarily_away',
        'grace_deadline', to_char(v_deadline, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.start_grace_period(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 11. RPC: leave_library(p_library_id UUID)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.leave_library(p_library_id UUID)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public, auth, extensions
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_visit RECORD;
    v_booking RECORD;
    v_now TIMESTAMPTZ := timezone('utc'::text, now());
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    PERFORM public.expire_stale_bookings();

    -- Find active/away visit
    SELECT id, status
    INTO v_visit
    FROM public.visits
    WHERE user_id = v_user_id
      AND library_id = p_library_id
      AND status IN ('inside', 'away')
    LIMIT 1;

    IF v_visit.id IS NULL THEN
        RETURN jsonb_build_object(
            'result', 'no_active_visit',
            'visit_status', 'completed',
            'booking_status', NULL,
            'seat_id', NULL
        );
    END IF;

    -- Release any active or away booking
    SELECT id, seat_id
    INTO v_booking
    FROM public.bookings
    WHERE user_id = v_user_id
      AND visit_id = v_visit.id
      AND status IN ('active', 'temporarily_away')
    LIMIT 1;

    IF v_booking.id IS NOT NULL THEN
        UPDATE public.bookings
        SET status = 'completed',
            released_at = v_now
        WHERE id = v_booking.id;
    END IF;

    -- Mark visit completed
    UPDATE public.visits
    SET status = 'completed',
        exited_at = v_now
    WHERE id = v_visit.id;

    RETURN jsonb_build_object(
        'result', 'success',
        'visit_status', 'completed',
        'booking_status', CASE WHEN v_booking.id IS NOT NULL THEN 'completed' ELSE NULL END,
        'seat_id', v_booking.seat_id
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.leave_library(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 12. RPC: get_my_history(p_library_id UUID, p_limit INTEGER DEFAULT 20)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_my_history(p_library_id UUID, p_limit INTEGER DEFAULT 20)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public, auth, extensions
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_sanitized_limit INT := LEAST(GREATEST(p_limit, 1), 100);
    v_result JSONB;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'visit_id', v.id,
                'entered_at', to_char(v.entered_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
                'exited_at', CASE WHEN v.exited_at IS NOT NULL THEN to_char(v.exited_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') ELSE NULL END,
                'visit_status', v.status,
                'seat_label', s.label,
                'seat_zone', s.zone,
                'floor_number', s.floor_number,
                'booking_status', b.status,
                'created_at', CASE WHEN b.created_at IS NOT NULL THEN to_char(b.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') ELSE NULL END
            ) ORDER BY v.entered_at DESC
        ),
        '[]'::jsonb
    ) INTO v_result
    FROM public.visits v
    LEFT JOIN public.bookings b ON b.visit_id = v.id
    LEFT JOIN public.seats s ON s.id = b.seat_id
    WHERE v.user_id = v_user_id
      AND v.library_id = p_library_id
    LIMIT v_sanitized_limit;

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_history(UUID, INTEGER) TO authenticated;
