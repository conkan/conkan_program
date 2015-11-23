-- Convert schema 'sql/conkan-Schema-0.0003-MySQL.sql' to 'conkan::Schema v0.0004':;

BEGIN;

ALTER TABLE pg_program CHANGE COLUMN staffid staffid integer unsigned NULL,
                       CHANGE COLUMN status status varchar(64) NULL;


COMMIT;

