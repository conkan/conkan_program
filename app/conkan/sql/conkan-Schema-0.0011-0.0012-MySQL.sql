-- Convert schema 'sql/conkan-Schema-0.0011-MySQL.sql' to 'conkan::Schema v0.0012':;

BEGIN;

ALTER TABLE pg_all_cast CHANGE COLUMN namef namef varchar(64) NULL,
                        CHANGE COLUMN status status varchar(64) NULL;

ALTER TABLE pg_cast CHANGE COLUMN status status varchar(64) NULL;

ALTER TABLE pg_program CHANGE COLUMN staffid staffid integer unsigned NULL;


COMMIT;

