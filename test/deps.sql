-- Note: pgTap is loaded by setup.sql
-- ... But we need to manually install it for tg_sanity_tap;

CREATE SCHEMA IF NOT EXISTS tap;
CREATE EXTENSION IF NOT EXISTS pgtap SCHEMA tap;

CREATE EXTENSION tg_sanity;
CREATE EXTENSION tg_sanity_tap;

-- Need this so we don't get warnings when pgxntool installs pgtap
SET client_min_messages = WARNING;

-- Add any test dependency statements here
