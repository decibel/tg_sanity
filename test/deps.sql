-- Note: pgTap is loaded by setup.sql
-- ... But we need to manually install it for tg_sanity_tap;

CREATE SCHEMA IF NOT EXISTS tap;
CREATE EXTENSION IF NOT EXISTS pgtap SCHEMA tap;

CREATE EXTENSION tg_sanity;
CREATE EXTENSION tg_sanity_tap;

-- Add any test dependency statements here
