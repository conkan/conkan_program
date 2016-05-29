-- Convert schema 'sql/conkan-Schema-0.0017-MySQL.sql' to 'conkan::Schema v0.0018':;

BEGIN;

ALTER TABLE pg_equip ADD COLUMN vif varchar(64) NULL,
                     ADD COLUMN aif varchar(64) NULL,
                     ADD COLUMN eif varchar(64) NULL,
                     ADD COLUMN intende varchar(64) NULL;


COMMIT;

