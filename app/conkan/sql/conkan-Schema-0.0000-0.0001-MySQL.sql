-- Convert schema '/var/conkan/conkan-Schema-0.0000-MySQL.sql' to 'conkan::Schema v0.0001':;

BEGIN;

ALTER TABLE pg_staff CHANGE COLUMN otheruid otheruid text NULL;


COMMIT;

