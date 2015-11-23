-- Convert schema 'sql/conkan-Schema-0.0008-MySQL.sql' to 'conkan::Schema v0.0009':;

BEGIN;

ALTER TABLE pg_program ADD UNIQUE PgID (pgid);


COMMIT;

