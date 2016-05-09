-- Convert schema 'sql/conkan-Schema-0.0016-MySQL.sql' to 'conkan::Schema v0.0017':;

BEGIN;

ALTER TABLE pg_all_cast DROP INDEX name_UNIQUE,
                        ADD COLUMN rmdate datetime NULL,
                        CHANGE COLUMN regno regno varchar(64) NULL;

ALTER TABLE pg_cast DROP FOREIGN KEY pg_cast_fk_pgid;

ALTER TABLE pg_cast ADD CONSTRAINT pg_cast_fk_pgid FOREIGN KEY (pgid) REFERENCES pg_program (pgid) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE pg_staff CHANGE COLUMN regno regno varchar(64) NULL;


COMMIT;

