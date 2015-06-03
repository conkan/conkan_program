-- Convert schema 'sql/conkan-Schema-0.0007-MySQL.sql' to 'conkan::Schema v0.0008':;

BEGIN;

ALTER TABLE pg_all_cast ADD COLUMN memo text NULL;

ALTER TABLE pg_cast ADD COLUMN memo text NULL;

ALTER TABLE pg_program ADD COLUMN memo text NULL;

ALTER TABLE pg_reg_cast CHANGE COLUMN entrantregno entrantregno varchar(64) NULL;


COMMIT;

