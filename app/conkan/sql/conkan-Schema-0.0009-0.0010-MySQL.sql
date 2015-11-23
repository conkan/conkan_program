-- Convert schema 'sql/conkan-Schema-0.0009-MySQL.sql' to 'conkan::Schema v0.0010':;

BEGIN;

ALTER TABLE pg_all_equip ADD COLUMN count integer unsigned NULL DEFAULT 1;

ALTER TABLE pg_cast DROP FOREIGN KEY pg_cast_fk_pgid;

ALTER TABLE pg_cast ADD CONSTRAINT pg_cast_fk_pgid FOREIGN KEY (pgid) REFERENCES pg_program (pgid) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE pg_equip DROP FOREIGN KEY pg_equip_fk_pgid;

ALTER TABLE pg_equip DROP COLUMN count,
                     ADD CONSTRAINT pg_equip_fk_pgid FOREIGN KEY (pgid) REFERENCES pg_program (pgid) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE pg_program DROP PRIMARY KEY,
                       DROP INDEX PgID,
                       DROP FOREIGN KEY pg_program_fk_pgid,
                       DROP INDEX pg_program_idx_pgid,
                       DROP COLUMN id,
                       ADD COLUMN regpgid integer unsigned NOT NULL,
                       ADD COLUMN subno integer unsigned NULL DEFAULT 0,
                       CHANGE COLUMN pgid pgid integer unsigned NOT NULL auto_increment,
                       CHANGE COLUMN staffid staffid integer unsigned NOT NULL,
                       ADD INDEX pg_program_idx_regpgid (regpgid),
                       ADD PRIMARY KEY (pgid),
                       ADD CONSTRAINT pg_program_fk_regpgid FOREIGN KEY (regpgid) REFERENCES pg_reg_program (regpgid) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE pg_progress DROP FOREIGN KEY pg_progress_fk_pgid,
                        DROP INDEX pg_progress_idx_pgid,
                        DROP COLUMN pgid,
                        ADD COLUMN regpgid integer unsigned NOT NULL,
                        ADD INDEX pg_progress_idx_regpgid (regpgid),
                        ADD CONSTRAINT pg_progress_fk_regpgid FOREIGN KEY (regpgid) REFERENCES pg_reg_program (regpgid) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE pg_reg_cast DROP FOREIGN KEY pg_reg_cast_fk_pgid,
                        DROP INDEX pg_reg_cast_idx_pgid,
                        DROP COLUMN pgid,
                        ADD COLUMN regpgid integer unsigned NOT NULL,
                        ADD INDEX pg_reg_cast_idx_regpgid (regpgid),
                        ADD CONSTRAINT pg_reg_cast_fk_regpgid FOREIGN KEY (regpgid) REFERENCES pg_reg_program (regpgid) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE pg_reg_equip DROP FOREIGN KEY pg_reg_equip_fk_pgid,
                         DROP INDEX pg_reg_equip_idx_pgid,
                         DROP COLUMN pgid,
                         ADD COLUMN regpgid integer unsigned NOT NULL,
                         ADD INDEX pg_reg_equip_idx_regpgid (regpgid),
                         ADD CONSTRAINT pg_reg_equip_fk_regpgid FOREIGN KEY (regpgid) REFERENCES pg_reg_program (regpgid) ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE pg_reg_program DROP PRIMARY KEY,
                           DROP COLUMN pgid,
                           ADD COLUMN regpgid integer unsigned NOT NULL auto_increment,
                           ADD PRIMARY KEY (regpgid);


COMMIT;

