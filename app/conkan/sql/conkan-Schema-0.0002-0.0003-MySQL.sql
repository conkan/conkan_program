-- Convert schema 'sql/conkan-Schema-0.0002-MySQL.sql' to 'conkan::Schema v0.0003':;

BEGIN;

ALTER TABLE pg_regist_conf ADD COLUMN upperkeyval varchar(64) NULL;


COMMIT;

