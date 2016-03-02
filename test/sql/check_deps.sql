\set ECHO none

\set QUIET true

BEGIN;
CREATE EXTENSION pgtap;
\echo EXPECT: required extension "tg_sanity" is not installed
CREATE EXTENSION tg_sanity_tap;
ROLLBACK;
BEGIN;
CREATE EXTENSION tg_sanity;
\echo EXPECT: required extension "pgtap" is not installed
CREATE EXTENSION tg_sanity_tap;
ROLLBACK;

-- vi: expandtab sw=2 ts=2
