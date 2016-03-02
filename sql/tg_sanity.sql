CREATE OR REPLACE FUNCTION tg_sanity(
) RETURNS trigger LANGUAGE plpgsql AS $body$
DECLARE
  c_args CONSTANT jsonb := TG_ARGV[0];
  c_ok_query CONSTANT text := c_args->>'ok_query';
  c_not_ok_if CONSTANT text := c_args->>'not_ok_if';

  detail text;
  allow boolean := false;
BEGIN
  -- If there's no args then simply deny the operation
  IF TG_NARGS > 0 THEN
    DECLARE
      c_new_old CONSTANT text := format(
        'WITH
          NEW AS (SELECT (r).* FROM (SELECT ($1)::%1$s r) s)
          , OLD AS (SELECT (r).* FROM (SELECT ($2)::%1$s r) s)
        '
        , TG_RELID::regclass
      );

      sql text;
    BEGIN
      IF ( c_ok_query || c_not_ok_if ) IS NOT NULL THEN
        RAISE 'Only c_ok_query OR c_not_ok_if may be set at once'
          USING DETAIL = 'arguments: ' || c_args
        ;
      END IF;

      IF c_not_ok_if IS NOT NULL THEN
        detail := 'not ok if: ' || c_not_ok_if;
        sql := c_new_old
          || format(
              'SELECT NOT (%s)::boolean FROM NEW, OLD'
              , c_not_ok_if
            )
        ;
      END IF;

      IF c_ok_query IS NOT NULL THEN
        detail := 'ok if "' || c_ok_query || '" returns true';
        sql := c_new_old || c_ok_query;
      END IF;

      RAISE DEBUG 'sql = %', sql;
      IF TG_OP='INSERT' THEN
        EXECUTE sql INTO STRICT allow USING NEW, NULL;
      ELSIF TG_OP='UPDATE' THEN
        EXECUTE sql INTO STRICT allow USING NEW, OLD;
      ELSE
        EXECUTE sql INTO STRICT allow USING NULL, OLD;
      END IF;
    END;
  END IF;

  IF allow IS NOT TRUE THEN -- Treat NULL as false
    DECLARE
      msg CONSTANT text := coalesce(
        c_args->>'message'
        , format(
            '%s on %s denied by trigger %I'
            , TG_OP
            , TG_RELID::regclass
            , TG_NAME
          )
      );
    BEGIN
      IF detail IS NULL THEN
        RAISE '%', msg;
      ELSE
        RAISE '%', msg
          USING DETAIL = detail
        ;
      END IF;
    END;
  END IF;
  RETURN NEW;
END
$body$;

-- vi: expandtab ts=2 sw=2
