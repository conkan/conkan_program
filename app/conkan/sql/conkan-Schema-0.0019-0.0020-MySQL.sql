-- Convert schema 'sql/conkan-Schema-0.0019-MySQL.sql' to 'conkan::Schema v0.0020':;

BEGIN;

ALTER TABLE pg_reg_equip ADD COLUMN updateflg varchar(64) NULL;

ALTER TABLE pg_reg_program ADD COLUMN originaljson text NULL,
                           ADD COLUMN cloudtag varchar(128) NULL;


COMMIT;

