CREATE OR REPLACE FUNCTION tg_sanity_tap(
  trigger_table regclass
  , trigger_name text
  , timing text
  , events text
  , trigger_arguments text
) RETURNS SETOF text LANGUAGE plpgsql AS $body$
DECLARE
  v_schema name;
  v_table name;

  c_extension CONSTANT name := 'tg_sanity';
  c_events CONSTANT text[] := events;
  c_oid CONSTANT oid := cat_tools.trigger__get_oid__loose(
    trigger_table
    , trigger_name
  );

  c_sanity_schema CONSTANT name := (
    SELECT nspname
      FROM pg_namespace n
        JOIN pg_extension e ON n.oid = e.extnamespace
      WHERE extname=c_extension
  );

  r record;
  b boolean;
BEGIN
  SELECT INTO STRICT v_schema, v_table
      relschema, relname
    FROM cat_tools.pg_class(trigger_table)
  ;
  RAISE DEBUG 'v_schema "%", v_table "%", trigger_name "%"', v_schema, v_table, trigger_name;

  RETURN NEXT ok(
    c_sanity_schema IS NOT NULL
    , c_extension || ' exists'
  );

  IF c_sanity_schema IS NULL THEN
    RETURN NEXT skip(
      1
      , 'Extension does not exist'
    );
  ELSE
    RETURN NEXT trigger_is(
      v_schema, v_table
      , trigger_name
      , c_sanity_schema
      , 'tg_sanity'
    );
  END IF;

  /*
   * Need to verify this stuff manually. Note that we NEED the preceeding
   * test to ensure we find something here
   */

  IF c_oid IS NULL THEN
    RETURN NEXT skip(
      5
      , 'Trigger does not exist'
    );
  ELSE
    r := cat_tools.trigger__parse(c_oid);

    RETURN NEXT isnt(
      r.timing
      , 'INSTEAD OF'
      , 'tg_sanity must be BEFORE or AFTER'
    );

    b := r.events @> c_events AND c_events @> r.events;
    RETURN NEXT ok(
      b, 'Trigger events match' ||
        CASE WHEN b THEN ''
          ELSE diag( format( '
        have: %s
        want: %s'
              , r.events
              , c_events
            ) )
        END
    );

    RETURN NEXT is(
      r.row_statement
      , timing
      , 'Is a row trigger'
    );

    RETURN NEXT is(
      r.when_clause
      , NULL
      , 'WHEN clause'
    );

    /*
     * is() uses IS NOT DISTINCT but we don't care about that distinction, so
     * coalesce()
     */
    RETURN NEXT is(
      coalesce(r.function_arguments, '') -- Don't cast this to JSON in case it's not valid
      , coalesce(trigger_arguments::text, '')
      , 'Trigger function arguments'
    );
  END IF;
END
$body$;

COMMENT ON FUNCTION tg_sanity_tap(
  trigger_table regclass
  , trigger_name text
  , timing text
  , events text
  , trigger_arguments text
) IS $$Function to verify the definition of a trigger that calls tg_sanity().

Parameters:
trigger_table   Table that trigger is defined on
trigger_name    Name of trigger
timing          Whether trigger *should* be BEFORE or AFTER
events          Events (INSERT, UPDATE, etc) that trigger *should* fire on
trigger_arguments   Arguments that trigger should be supplying to the function.
                    NOTE: This is compared as plain text, so much match exactly
                    what is stored in the catalog.

Returns:
Set of TAP ouput
$$;

-- vi: expandtab ts=2 sw=2
