-- ============================================================================
-- SMART LIBRARY MANAGEMENT SYSTEM - AUTOMATIC 20-MINUTE EXPIRY CRON JOB
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_available_extensions WHERE name = 'pg_cron'
    ) THEN
        CREATE EXTENSION IF NOT EXISTS pg_cron;
        PERFORM cron.unschedule('expire-stale-seat-bookings');
        PERFORM cron.schedule(
            'expire-stale-seat-bookings',
            '* * * * *',
            'SELECT public.expire_stale_bookings();'
        );
        RAISE NOTICE 'Successfully scheduled pg_cron job: expire-stale-seat-bookings';
    ELSE
        RAISE NOTICE 'pg_cron extension is not available in this environment. Falling back to on-demand RPC expiry cleanup.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Could not schedule pg_cron: %. Fallback to on-demand RPC cleanup.', SQLERRM;
END;
$$;
