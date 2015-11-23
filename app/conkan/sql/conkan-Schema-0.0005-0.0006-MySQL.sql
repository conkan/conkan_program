-- Convert schema 'sql/conkan-Schema-0.0005-MySQL.sql' to 'conkan::Schema v0.0006':;

BEGIN;

ALTER TABLE pg_all_cast ADD UNIQUE name_UNIQUE (name);


COMMIT;

