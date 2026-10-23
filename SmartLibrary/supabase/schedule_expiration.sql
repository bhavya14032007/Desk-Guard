-- ============================================================================
-- SMART LIBRARY MANAGEMENT SYSTEM - AUTOMATIC 20-MINUTE EXPIRY CRON JOB
-- ============================================================================

-- This script schedules an automatic release job using pg_cron in Supabase.
-- Note: Even if pg_cron is disabled, the system remains strictly correct because
-- public.expire_stale_bookings() is executed automatically inside all RPC calls:
-- get_seat_map, get_my_state, scan_entry, book_seat, and start_grace_period.

DO $$
BEGIN
    -- Check if pg_cron extension is available
    IF EXISTS (
        SELECT 1 FROM pg_available_extensions WHERE name = 'pg_cron'
    ) THEN
        CREATE EXTENSION IF NOT EXISTS pg_cron;

        -- Remove existing job if previously scheduled
        PERFORM cron.unschedule('expire-stale-seat-bookings');

        -- Schedule cron job to run every 1 minute:
        -- Calls public.expire_stale_bookings()
        PERFORM cron.schedule(
            'expire-stale-seat-bookings',
            '* * * * *',
            'SELECT public.expire_stale_bookings();'
        );

        RAISE NOTICE 'Successfully scheduled pg_cron job: expire-stale-seat-bookings (runs every 1 minute)';
    ELSE
        RAISE NOTICE 'pg_cron extension is not available in this environment. Falling back to on-demand RPC expiry cleanup.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Could not schedule pg_cron (error: %). Ensure pg_cron is enabled in Supabase Dashboard -> Database -> Extensions.', SQLERRM;
END;
$$;

-- Query to inspect cron execution history in Supabase SQL Editor:
-- SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 20;
