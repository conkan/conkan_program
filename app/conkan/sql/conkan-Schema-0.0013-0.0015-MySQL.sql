-- Convert schema 'sql/conkan-Schema-0.0013-MySQL.sql' to 'conkan::Schema v0.0015':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `login_log` (
  `logid` integer unsigned NOT NULL auto_increment,
  `staffid` integer unsigned NOT NULL,
  `login_date` datetime NOT NULL,
  INDEX `login_log_idx_staffid` (`staffid`),
  PRIMARY KEY (`logid`),
  CONSTRAINT `login_log_fk_staffid` FOREIGN KEY (`staffid`) REFERENCES `pg_staff` (`staffid`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE pg_staff ADD COLUMN lastlogin datetime NULL;


COMMIT;

