-- Convert schema 'sql/conkan-Schema-0.0015-MySQL.sql' to 'conkan::Schema v0.0016':;

BEGIN;

ALTER TABLE pg_cast DROP FOREIGN KEY pg_cast_fk_pgid;

ALTER TABLE pg_cast ADD CONSTRAINT pg_cast_fk_pgid FOREIGN KEY (pgid) REFERENCES pg_program (pgid) ON DELETE NO ACTION ON UPDATE CASCADE;

ALTER TABLE pg_program DROP FOREIGN KEY pg_program_fk_regpgid;

ALTER TABLE pg_program ADD CONSTRAINT pg_program_fk_regpgid FOREIGN KEY (regpgid) REFERENCES pg_reg_program (regpgid) ON DELETE NO ACTION ON UPDATE CASCADE;

ALTER TABLE pg_progress DROP FOREIGN KEY pg_progress_fk_regpgid;

ALTER TABLE pg_progress ADD CONSTRAINT pg_progress_fk_regpgid FOREIGN KEY (regpgid) REFERENCES pg_reg_program (regpgid) ON DELETE NO ACTION ON UPDATE CASCADE;

ALTER TABLE pg_reg_cast DROP FOREIGN KEY pg_reg_cast_fk_regpgid;

ALTER TABLE pg_reg_cast ADD CONSTRAINT pg_reg_cast_fk_regpgid FOREIGN KEY (regpgid) REFERENCES pg_reg_program (regpgid) ON DELETE NO ACTION ON UPDATE CASCADE;

ALTER TABLE pg_reg_equip DROP FOREIGN KEY pg_reg_equip_fk_regpgid;

ALTER TABLE pg_reg_equip ADD CONSTRAINT pg_reg_equip_fk_regpgid FOREIGN KEY (regpgid) REFERENCES pg_reg_program (regpgid) ON DELETE NO ACTION ON UPDATE CASCADE;


COMMIT;

