-- Convert schema 'sql/conkan-Schema-0.0001-MySQL.sql' to 'conkan::Schema v0.0002':;

BEGIN;

ALTER TABLE pg_room ADD COLUMN comment text NULL;


COMMIT;

