-- ============================================================================
-- SMART LIBRARY MANAGEMENT SYSTEM - SEED DATA
-- Target: Demo Library (11111111-1111-4111-8111-111111111111)
-- 48 Realistic Seats distributed across 2 Floors & 4 Zones with Coordinates (0-100)
-- ============================================================================

-- 1. Insert Demo Central Library
INSERT INTO public.libraries (id, name, timezone)
VALUES (
    '11111111-1111-4111-8111-111111111111',
    'Central Library',
    'America/New_York'
)
ON CONFLICT (id) DO UPDATE 
SET name = EXCLUDED.name,
    timezone = EXCLUDED.timezone;

-- 2. Clean previous demo seats if any (to make seed idempotent)
DELETE FROM public.seats WHERE library_id = '11111111-1111-4111-8111-111111111111';

-- 3. Insert 48 Distinct Seats across Floors & Zones
-- Floor 1: Main Hall & Collaborative Hub
-- Floor 2: Silent Study (Quiet Zone) & Research Pods

INSERT INTO public.seats (library_id, label, floor_number, zone, x_position, y_position, features, is_active) VALUES
-- Floor 1 - Zone: Main Reading Room (Row A)
('11111111-1111-4111-8111-111111111111', 'A1', 1, 'Main Reading Room', 12.0, 18.0, '["power_outlet", "lamp"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'A2', 1, 'Main Reading Room', 24.0, 18.0, '["power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'A3', 1, 'Main Reading Room', 36.0, 18.0, '["power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'A4', 1, 'Main Reading Room', 48.0, 18.0, '["power_outlet", "lamp"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'A5', 1, 'Main Reading Room', 60.0, 18.0, '["power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'A6', 1, 'Main Reading Room', 72.0, 18.0, '["power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'A7', 1, 'Main Reading Room', 84.0, 18.0, '["power_outlet", "window_view"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'A8', 1, 'Main Reading Room', 92.0, 18.0, '["power_outlet", "window_view"]'::jsonb, true),

-- Floor 1 - Zone: Main Reading Room (Row B)
('11111111-1111-4111-8111-111111111111', 'B1', 1, 'Main Reading Room', 12.0, 36.0, '["power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'B2', 1, 'Main Reading Room', 24.0, 36.0, '["power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'B3', 1, 'Main Reading Room', 36.0, 36.0, '["power_outlet", "lamp"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'B4', 1, 'Main Reading Room', 48.0, 36.0, '["power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'B5', 1, 'Main Reading Room', 60.0, 36.0, '["power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'B6', 1, 'Main Reading Room', 72.0, 36.0, '["power_outlet", "lamp"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'B7', 1, 'Main Reading Room', 84.0, 36.0, '["power_outlet", "window_view"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'B8', 1, 'Main Reading Room', 92.0, 36.0, '["power_outlet", "window_view"]'::jsonb, true),

-- Floor 1 - Zone: Tech & Collaboration Pods (Row C)
('11111111-1111-4111-8111-111111111111', 'C1', 1, 'Tech & Collaboration', 12.0, 60.0, '["power_outlet", "external_monitor"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'C2', 1, 'Tech & Collaboration', 24.0, 60.0, '["power_outlet", "external_monitor"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'C3', 1, 'Tech & Collaboration', 36.0, 60.0, '["power_outlet", "standing_desk"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'C4', 1, 'Tech & Collaboration', 48.0, 60.0, '["power_outlet", "standing_desk"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'C5', 1, 'Tech & Collaboration', 60.0, 60.0, '["power_outlet", "whiteboard"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'C6', 1, 'Tech & Collaboration', 72.0, 60.0, '["power_outlet", "whiteboard"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'C7', 1, 'Tech & Collaboration', 84.0, 60.0, '["power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'C8', 1, 'Tech & Collaboration', 92.0, 60.0, '["power_outlet"]'::jsonb, true),

-- Floor 2 - Zone: Silent Study (Quiet Zone) (Row D)
('11111111-1111-4111-8111-111111111111', 'D1', 2, 'Silent Study Area', 15.0, 20.0, '["quiet_zone", "power_outlet", "lamp"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'D2', 2, 'Silent Study Area', 26.0, 20.0, '["quiet_zone", "power_outlet", "lamp"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'D3', 2, 'Silent Study Area', 38.0, 20.0, '["quiet_zone", "power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'D4', 2, 'Silent Study Area', 50.0, 20.0, '["quiet_zone", "power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'D5', 2, 'Silent Study Area', 62.0, 20.0, '["quiet_zone", "power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'D6', 2, 'Silent Study Area', 74.0, 20.0, '["quiet_zone", "power_outlet", "lamp"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'D7', 2, 'Silent Study Area', 85.0, 20.0, '["quiet_zone", "power_outlet", "window_view"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'D8', 2, 'Silent Study Area', 94.0, 20.0, '["quiet_zone", "power_outlet", "window_view"]'::jsonb, true),

-- Floor 2 - Zone: Silent Study (Quiet Zone) (Row E)
('11111111-1111-4111-8111-111111111111', 'E1', 2, 'Silent Study Area', 15.0, 44.0, '["quiet_zone", "power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'E2', 2, 'Silent Study Area', 26.0, 44.0, '["quiet_zone", "power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'E3', 2, 'Silent Study Area', 38.0, 44.0, '["quiet_zone", "power_outlet", "lamp"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'E4', 2, 'Silent Study Area', 50.0, 44.0, '["quiet_zone", "power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'E5', 2, 'Silent Study Area', 62.0, 44.0, '["quiet_zone", "power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'E6', 2, 'Silent Study Area', 74.0, 44.0, '["quiet_zone", "power_outlet", "lamp"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'E7', 2, 'Silent Study Area', 85.0, 44.0, '["quiet_zone", "power_outlet", "window_view"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'E8', 2, 'Silent Study Area', 94.0, 44.0, '["quiet_zone", "power_outlet", "window_view"]'::jsonb, true),

-- Floor 2 - Zone: Research Carrels (Row F)
('11111111-1111-4111-8111-111111111111', 'F1', 2, 'Research Carrels', 15.0, 72.0, '["quiet_zone", "power_outlet", "standing_desk"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'F2', 2, 'Research Carrels', 26.0, 72.0, '["quiet_zone", "power_outlet", "standing_desk"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'F3', 2, 'Research Carrels', 38.0, 72.0, '["quiet_zone", "power_outlet", "external_monitor"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'F4', 2, 'Research Carrels', 50.0, 72.0, '["quiet_zone", "power_outlet", "external_monitor"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'F5', 2, 'Research Carrels', 62.0, 72.0, '["quiet_zone", "power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'F6', 2, 'Research Carrels', 74.0, 72.0, '["quiet_zone", "power_outlet"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'F7', 2, 'Research Carrels', 85.0, 72.0, '["quiet_zone", "power_outlet", "window_view"]'::jsonb, true),
('11111111-1111-4111-8111-111111111111', 'F8', 2, 'Research Carrels', 94.0, 72.0, '["quiet_zone", "power_outlet", "window_view"]'::jsonb, true);
