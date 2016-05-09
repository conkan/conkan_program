-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Mon May  9 14:11:20 2016
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS login_log;

--
-- Table: login_log
--
CREATE TABLE login_log (
  logid integer unsigned NOT NULL auto_increment,
  staffid integer unsigned NOT NULL,
  login_date datetime NOT NULL,
  INDEX login_log_idx_staffid (staffid),
  PRIMARY KEY (logid),
  CONSTRAINT login_log_fk_staffid FOREIGN KEY (staffid) REFERENCES pg_staff (staffid) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

DROP TABLE IF EXISTS pg_all_cast;

--
-- Table: pg_all_cast
--
CREATE TABLE pg_all_cast (
  castid integer unsigned NOT NULL auto_increment,
  regno varchar(64) NULL,
  name varchar(64) NOT NULL,
  namef varchar(64) NULL,
  status varchar(64) NULL,
  memo text NULL,
  restdate text NULL,
  updateflg varchar(64) NULL,
  rmdate datetime NULL,
  PRIMARY KEY (castid),
  UNIQUE regno_UNIQUE (regno)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS pg_all_equip;

--
-- Table: pg_all_equip
--
CREATE TABLE pg_all_equip (
  equipid integer unsigned NOT NULL auto_increment,
  name varchar(64) NOT NULL,
  equipno varchar(64) NOT NULL,
  spec varchar(64) NULL,
  comment varchar(64) NULL,
  updateflg varchar(64) NULL,
  rmdate datetime NULL,
  PRIMARY KEY (equipid),
  UNIQUE equipNo_UNIQUE (equipno)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS pg_cast;

--
-- Table: pg_cast
--
CREATE TABLE pg_cast (
  id integer unsigned NOT NULL auto_increment,
  pgid integer unsigned NOT NULL,
  castid integer unsigned NOT NULL,
  status varchar(64) NULL,
  memo text NULL,
  name varchar(64) NULL,
  namef varchar(64) NULL,
  title varchar(64) NULL,
  updateflg varchar(64) NULL,
  INDEX pg_cast_idx_castid (castid),
  INDEX pg_cast_idx_pgid (pgid),
  PRIMARY KEY (id),
  CONSTRAINT pg_cast_fk_castid FOREIGN KEY (castid) REFERENCES pg_all_cast (castid) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT pg_cast_fk_pgid FOREIGN KEY (pgid) REFERENCES pg_program (pgid) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

DROP TABLE IF EXISTS pg_equip;

--
-- Table: pg_equip
--
CREATE TABLE pg_equip (
  id integer unsigned NOT NULL auto_increment,
  pgid integer unsigned NOT NULL,
  equipid integer unsigned NULL,
  updateflg varchar(64) NULL,
  INDEX pg_equip_idx_equipid (equipid),
  INDEX pg_equip_idx_pgid (pgid),
  PRIMARY KEY (id),
  CONSTRAINT pg_equip_fk_equipid FOREIGN KEY (equipid) REFERENCES pg_all_equip (equipid) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT pg_equip_fk_pgid FOREIGN KEY (pgid) REFERENCES pg_program (pgid) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

DROP TABLE IF EXISTS pg_program;

--
-- Table: pg_program
--
CREATE TABLE pg_program (
  pgid integer unsigned NOT NULL auto_increment,
  regpgid integer unsigned NOT NULL,
  sname varchar(64) NULL,
  subno integer unsigned NULL DEFAULT 0,
  staffid integer unsigned NULL,
  status varchar(64) NULL,
  memo text NULL,
  date1 date NULL,
  stime1 time NULL,
  etime1 time NULL,
  date2 date NULL,
  stime2 time NULL,
  etime2 time NULL,
  roomid integer unsigned NULL,
  layerno integer NULL DEFAULT 0,
  progressprp text NULL,
  updateflg varchar(64) NULL,
  INDEX pg_program_idx_regpgid (regpgid),
  INDEX pg_program_idx_roomid (roomid),
  INDEX pg_program_idx_staffid (staffid),
  PRIMARY KEY (pgid),
  CONSTRAINT pg_program_fk_regpgid FOREIGN KEY (regpgid) REFERENCES pg_reg_program (regpgid) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT pg_program_fk_roomid FOREIGN KEY (roomid) REFERENCES pg_room (roomid) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT pg_program_fk_staffid FOREIGN KEY (staffid) REFERENCES pg_staff (staffid) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

DROP TABLE IF EXISTS pg_progress;

--
-- Table: pg_progress
--
CREATE TABLE pg_progress (
  id integer unsigned NOT NULL auto_increment,
  regpgid integer unsigned NOT NULL,
  staffid integer unsigned NOT NULL,
  repdatetime datetime NOT NULL,
  report text NOT NULL,
  INDEX pg_progress_idx_regpgid (regpgid),
  INDEX pg_progress_idx_staffid (staffid),
  PRIMARY KEY (id),
  CONSTRAINT pg_progress_fk_regpgid FOREIGN KEY (regpgid) REFERENCES pg_reg_program (regpgid) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT pg_progress_fk_staffid FOREIGN KEY (staffid) REFERENCES pg_staff (staffid) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB;

DROP TABLE IF EXISTS pg_reg_cast;

--
-- Table: pg_reg_cast
--
CREATE TABLE pg_reg_cast (
  id integer unsigned NOT NULL auto_increment,
  regpgid integer unsigned NOT NULL,
  name varchar(64) NOT NULL,
  namef varchar(64) NULL,
  title varchar(64) NULL,
  entrantregno varchar(64) NULL,
  needreq varchar(64) NULL,
  needguest varchar(10) NULL,
  INDEX pg_reg_cast_idx_regpgid (regpgid),
  PRIMARY KEY (id),
  CONSTRAINT pg_reg_cast_fk_regpgid FOREIGN KEY (regpgid) REFERENCES pg_reg_program (regpgid) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS pg_reg_equip;

--
-- Table: pg_reg_equip
--
CREATE TABLE pg_reg_equip (
  id integer unsigned NOT NULL auto_increment,
  regpgid integer unsigned NOT NULL,
  name varchar(64) NOT NULL,
  count integer unsigned NULL DEFAULT 1,
  vif varchar(64) NULL,
  aif varchar(64) NULL,
  eif varchar(64) NULL,
  intende varchar(64) NULL,
  INDEX pg_reg_equip_idx_regpgid (regpgid),
  PRIMARY KEY (id),
  CONSTRAINT pg_reg_equip_fk_regpgid FOREIGN KEY (regpgid) REFERENCES pg_reg_program (regpgid) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS pg_reg_program;

--
-- Table: pg_reg_program
--
CREATE TABLE pg_reg_program (
  regpgid integer unsigned NOT NULL auto_increment,
  name varchar(64) NOT NULL,
  namef varchar(64) NOT NULL,
  regdate date NOT NULL,
  regname varchar(64) NOT NULL,
  regma varchar(64) NOT NULL,
  regno varchar(64) NOT NULL,
  telno varchar(64) NULL,
  faxno varchar(64) NULL,
  celno varchar(64) NULL,
  type varchar(64) NOT NULL,
  place varchar(64) NOT NULL,
  layout varchar(64) NOT NULL,
  date varchar(64) NOT NULL,
  classlen varchar(64) NOT NULL,
  expmaxcnt varchar(64) NOT NULL,
  content text NOT NULL,
  contentpub varchar(64) NOT NULL,
  realpub varchar(64) NOT NULL,
  afterpub varchar(64) NOT NULL,
  openpg varchar(64) NOT NULL,
  restpg varchar(64) NOT NULL,
  avoiddup text NULL,
  experience varchar(64) NOT NULL,
  comment text NULL,
  updateflg varchar(64) NULL,
  PRIMARY KEY (regpgid)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS pg_room;

--
-- Table: pg_room
--
CREATE TABLE pg_room (
  roomid integer unsigned NOT NULL auto_increment,
  name varchar(64) NOT NULL,
  roomno varchar(64) NOT NULL,
  max integer NULL,
  type varchar(64) NOT NULL,
  size integer NULL,
  tablecnt integer NULL,
  chaircnt integer NULL,
  equips varchar(64) NULL,
  useabletime varchar(64) NULL,
  net enum('NONE', 'W', 'E') NOT NULL,
  comment text NULL,
  updateflg varchar(64) NULL,
  rmdate datetime NULL,
  PRIMARY KEY (roomid),
  UNIQUE name_UNIQUE (name),
  UNIQUE roomNo_UNIQUE (roomno)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS pg_staff;

--
-- Table: pg_staff
--
CREATE TABLE pg_staff (
  staffid integer unsigned NOT NULL auto_increment,
  name varchar(64) NOT NULL,
  account varchar(64) NOT NULL,
  passwd varchar(64) NULL,
  role enum('NORM', 'ROOT', 'PG', 'ADMIN') NOT NULL,
  ma varchar(64) NULL,
  telno varchar(64) NULL,
  regno varchar(64) NULL,
  tname varchar(64) NULL,
  tnamef varchar(64) NULL,
  comment text NULL,
  otheruid text NULL,
  lastlogin datetime NULL,
  updateflg varchar(64) NULL,
  rmdate datetime NULL,
  PRIMARY KEY (staffid),
  UNIQUE account_UNIQUE (account)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS pg_system_conf;

--
-- Table: pg_system_conf
--
CREATE TABLE pg_system_conf (
  pg_conf_code varchar(64) NOT NULL,
  pg_conf_name varchar(64) NOT NULL,
  pg_conf_value text NOT NULL,
  PRIMARY KEY (pg_conf_code)
);

SET foreign_key_checks=1;

