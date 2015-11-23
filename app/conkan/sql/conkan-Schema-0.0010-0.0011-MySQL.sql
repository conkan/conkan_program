-- Convert schema 'sql/conkan-Schema-0.0010-MySQL.sql' to 'conkan::Schema v0.0011':;

BEGIN;

ALTER TABLE pg_cast ADD COLUMN title varchar(64) NULL;


COMMIT;

