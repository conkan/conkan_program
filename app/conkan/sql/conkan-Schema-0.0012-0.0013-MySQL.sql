-- Convert schema 'sql/conkan-Schema-0.0012-MySQL.sql' to 'conkan::Schema v0.0013':;

BEGIN;

ALTER TABLE pg_all_equip DROP COLUMN count;

ALTER TABLE pg_program ADD COLUMN sname varchar(64) NULL;

ALTER TABLE pg_reg_cast ADD COLUMN title varchar(64) NULL;

ALTER TABLE pg_reg_program ADD COLUMN openpg varchar(64) NOT NULL,
                           ADD COLUMN restpg varchar(64) NOT NULL;

ALTER TABLE pg_regist_conf DROP FOREIGN KEY pg_regist_conf_fk_upperkeyid;

DROP TABLE pg_regist_conf;


COMMIT;

