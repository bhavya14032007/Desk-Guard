-- ============================================================================
-- SMART LIBRARY MANAGEMENT SYSTEM - AUTOMATED DATABASE TEST SUITE
-- File: supabase/tests/database_tests.sql
-- ============================================================================

-- Runs inside a rolled-back transaction so it never leaves permanent test artifacts.
BEGIN;

DO $$
DECLARE
    v_lib_id UUID := '11111111-1111-4111-8111-111111111111';
    v_user1_id UUID := gen_random_uuid();
    v_user2_id UUID := gen_random_uuid();
    v_seat1_id UUID;
    v_seat2_id UUID;
    v_result JSONB;
    v_state JSONB;
    v_booking_id UUID;
    v_error_caught BOOLEAN := false;
BEGIN
    RAISE NOTICE '=== STARTING SMART LIBRARY DATABASE TEST SUITE ===';

    -- 1. Verify Library Exists
    IF NOT EXISTS (SELECT 1 FROM public.libraries WHERE id = v_lib_id) THEN
        RAISE EXCEPTION 'TEST FAILED: Demo library % does not exist. Run seed.sql first!', v_lib_id;
    END IF;
    RAISE NOTICE '[PASS] Demo library verified';

    -- Grab test seats
    SELECT id INTO v_seat1_id FROM public.seats WHERE library_id = v_lib_id AND label = 'A1';
    SELECT id INTO v_seat2_id FROM public.seats WHERE library_id = v_lib_id AND label = 'A2';
    IF v_seat1_id IS NULL OR v_seat2_id IS NULL THEN
        RAISE EXCEPTION 'TEST FAILED: Seed seats A1 and A2 not found.';
    END IF;
    RAISE NOTICE '[PASS] Seed seats retrieved: Seat1(%), Seat2(%)', v_seat1_id, v_seat2_id;

    -- 2. Mock Test User Profiles
    INSERT INTO auth.users (id, email) VALUES (v_user1_id, 'student1@test.edu'), (v_user2_id, 'student2@test.edu') ON CONFLICT DO NOTHING;
    INSERT INTO public.profiles (id, full_name, role) VALUES (v_user1_id, 'Alice Student', 'student'), (v_user2_id, 'Bob Student', 'student') ON CONFLICT DO NOTHING;

    -- Test: Cannot book without active visit
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user1_id)::text, true);
    BEGIN
        PERFORM public.book_seat(v_seat1_id);
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%NO_ACTIVE_VISIT%' THEN
            v_error_caught := true;
        END IF;
    END;
    IF NOT v_error_caught THEN
        RAISE EXCEPTION 'TEST FAILED: Should have rejected booking without an active visit';
    END IF;
    RAISE NOTICE '[PASS] Rejected booking without active entry visit';

    -- 3. Scan Entry Test (Fresh Entry)
    v_result := public.scan_entry(v_lib_id);
    IF (v_result->>'result') != 'entered' THEN
        RAISE EXCEPTION 'TEST FAILED: Expected result "entered", got %', v_result;
    END IF;
    RAISE NOTICE '[PASS] Fresh entry scan successful: %', v_result;

    -- 4. Duplicate Entry Scan (Idempotency)
    v_result := public.scan_entry(v_lib_id);
    IF (v_result->>'result') != 'already_inside' THEN
        RAISE EXCEPTION 'TEST FAILED: Expected duplicate scan result "already_inside", got %', v_result;
    END IF;
    RAISE NOTICE '[PASS] Duplicate entry scan properly identified as already_inside';

    -- 5. Book Seat A1
    v_result := public.book_seat(v_seat1_id);
    v_booking_id := (v_result->>'booking_id')::UUID;
    IF (v_result->>'booking_status') != 'active' OR (v_result->>'seat_label') != 'A1' THEN
        RAISE EXCEPTION 'TEST FAILED: Expected active booking for A1, got %', v_result;
    END IF;
    RAISE NOTICE '[PASS] Seat A1 successfully booked: %', v_result;

    -- 6. One-User One-Seat Rule (User1 attempts to book Seat A2 while holding A1)
    v_error_caught := false;
    BEGIN
        PERFORM public.book_seat(v_seat2_id);
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%ALREADY_HAS_SEAT%' THEN
            v_error_caught := true;
        END IF;
    END;
    IF NOT v_error_caught THEN
        RAISE EXCEPTION 'TEST FAILED: User should be prevented from holding two seats';
    END IF;
    RAISE NOTICE '[PASS] One-user one-seat rule enforced (ALREADY_HAS_SEAT caught)';

    -- 7. Concurrent Seat Reservation Rule (User2 tries to book already booked Seat A1)
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user2_id)::text, true);
    PERFORM public.scan_entry(v_lib_id); -- User2 enters
    v_error_caught := false;
    BEGIN
        PERFORM public.book_seat(v_seat1_id); -- Tries to book Seat A1
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE '%SEAT_UNAVAILABLE%' THEN
            v_error_caught := true;
        END IF;
    END;
    IF NOT v_error_caught THEN
        RAISE EXCEPTION 'TEST FAILED: Seat A1 double-booking not prevented';
    END IF;
    RAISE NOTICE '[PASS] Seat collision prevented (SEAT_UNAVAILABLE caught)';

    -- 8. Seat Map Verification (User1 sees 'mine', User2 sees 'occupied')
    v_result := public.get_seat_map(v_lib_id);
    IF NOT EXISTS (
        SELECT 1 FROM jsonb_array_elements(v_result) elem
        WHERE (elem->>'seat_id')::UUID = v_seat1_id
          AND elem->>'availability_status' = 'occupied'
          AND (elem->>'is_mine')::boolean = false
    ) THEN
        RAISE EXCEPTION 'TEST FAILED: User2 should see Seat A1 as occupied and not mine';
    END IF;
    RAISE NOTICE '[PASS] User2 seat map correctly reports Seat A1 as occupied and not mine';

    -- Switch back to User1
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user1_id)::text, true);
    v_result := public.get_seat_map(v_lib_id);
    IF NOT EXISTS (
        SELECT 1 FROM jsonb_array_elements(v_result) elem
        WHERE (elem->>'seat_id')::UUID = v_seat1_id
          AND elem->>'availability_status' = 'mine'
          AND (elem->>'is_mine')::boolean = true
    ) THEN
        RAISE EXCEPTION 'TEST FAILED: User1 should see Seat A1 as mine';
    END IF;
    RAISE NOTICE '[PASS] User1 seat map correctly reports Seat A1 as mine';

    -- 9. Start Temporary-Away Grace Period (Step Out - 20 mins)
    v_result := public.start_grace_period(v_lib_id);
    IF (v_result->>'booking_status') != 'temporarily_away' OR (v_result->>'grace_deadline') IS NULL THEN
        RAISE EXCEPTION 'TEST FAILED: Expected temporarily_away with grace_deadline, got %', v_result;
    END IF;
    RAISE NOTICE '[PASS] Grace period initiated: %', v_result;

    -- 10. Return Before Grace Deadline (Scan Entry -> returned)
    v_result := public.scan_entry(v_lib_id);
    IF (v_result->>'result') != 'returned' THEN
        RAISE EXCEPTION 'TEST FAILED: Expected result "returned", got %', v_result;
    END IF;
    RAISE NOTICE '[PASS] Return before deadline restored booking: %', v_result;

    -- 11. Grace Period Expiry Simulation
    PERFORM public.start_grace_period(v_lib_id);
    -- Artificially simulate grace deadline passing by backdating grace_deadline
    UPDATE public.bookings 
    SET grace_deadline = timezone('utc'::text, now()) - INTERVAL '5 minutes'
    WHERE id = v_booking_id;

    -- User returns after expiry -> scan_entry should detect expired reservation and grant new visit
    v_result := public.scan_entry(v_lib_id);
    IF (v_result->>'result') != 'grace_expired_new_visit' THEN
        RAISE EXCEPTION 'TEST FAILED: Expected "grace_expired_new_visit", got %', v_result;
    END IF;
    RAISE NOTICE '[PASS] Return after deadline correctly identified: grace_expired_new_visit';

    -- Verify seat A1 is now freed and available for re-booking
    v_result := public.get_seat_map(v_lib_id);
    IF NOT EXISTS (
        SELECT 1 FROM jsonb_array_elements(v_result) elem
        WHERE (elem->>'seat_id')::UUID = v_seat1_id
          AND elem->>'availability_status' = 'available'
    ) THEN
        RAISE EXCEPTION 'TEST FAILED: Seat A1 was not released after expiry';
    END IF;
    RAISE NOTICE '[PASS] Seat A1 automatically released and made available';

    -- 12. Permanent Exit Test
    -- User1 books Seat A2 now
    PERFORM public.book_seat(v_seat2_id);
    v_result := public.leave_library(v_lib_id);
    IF (v_result->>'result') != 'success' OR (v_result->>'visit_status') != 'completed' THEN
        RAISE EXCEPTION 'TEST FAILED: Expected success on leave_library, got %', v_result;
    END IF;
    RAISE NOTICE '[PASS] Permanent exit completed: %', v_result;

    -- 13. State after exit
    v_state := public.get_my_state(v_lib_id);
    IF v_state->>'visit_id' IS NOT NULL THEN
        RAISE EXCEPTION 'TEST FAILED: User visit state should be null after exit';
    END IF;
    RAISE NOTICE '[PASS] User state is clean after exit: %', v_state;

    RAISE NOTICE '=== ALL 13 TEST SUITE CASES PASSED WITH 100%% SUCCESS ===';
END;
$$;

ROLLBACK;
