-- MySQL Script generated by MySQL Workbench
-- 04/06/15 19:32:19
-- Model: conkan    Version: 1.0

-- コンベンション管理システム

-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema conkan
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `conkan` ;

-- -----------------------------------------------------
-- Schema conkan
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `conkan` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci ;
USE `conkan` ;

-- -----------------------------------------------------
-- Table `conkan`.`pg_system_conf`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conkan`.`pg_system_conf` ;

CREATE TABLE IF NOT EXISTS `conkan`.`pg_system_conf` (
  `pg_conf_code` VARCHAR(10) NOT NULL,
  `pg_conf_name` VARCHAR(64) NOT NULL,
  `pg_conf_value` VARCHAR(128) NOT NULL,
  PRIMARY KEY (`pg_conf_code`))
ENGINE = InnoDB
COMMENT = 'Define value for THIS convention';


-- -----------------------------------------------------
-- Table `conkan`.`pg_regist_conf`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conkan`.`pg_regist_conf` ;

CREATE TABLE IF NOT EXISTS `conkan`.`pg_regist_conf` (
  `JsonKeyID` VARCHAR(10) NOT NULL,
  `HashKey` VARCHAR(64) NOT NULL,
  `DB_name` VARCHAR(128) NOT NULL,
  `ValType` VARCHAR(32) NOT NULL,
  `UpperKeyID` VARCHAR(10) NULL DEFAULT NULL,
  PRIMARY KEY (`JsonKeyID`),
  INDEX `Hash_Key_idx` (`HashKey` ASC),
  INDEX `UpperKeyID_fkey_idx` (`UpperKeyID` ASC),
  CONSTRAINT `UpperKeyID_fkey`
    FOREIGN KEY (`UpperKeyID`)
    REFERENCES `conkan`.`pg_regist_conf` (`JsonKeyID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'Program META structure';


-- -----------------------------------------------------
-- Table `conkan`.`pg_staff`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conkan`.`pg_staff` ;

CREATE TABLE IF NOT EXISTS `conkan`.`pg_staff` (
  `StaffID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL,
  `account` VARCHAR(64) NOT NULL,
  `passwd` VARCHAR(64) NULL DEFAULT NULL,
  `role` ENUM('NORM','ROOT','PG') NOT NULL,
  `ma` VARCHAR(64) NULL DEFAULT NULL,
  `telno` VARCHAR(64) NULL DEFAULT NULL,
  `regno` INT UNSIGNED NULL DEFAULT NULL,
  `tname` VARCHAR(64) NULL DEFAULT NULL,
  `tnamef` VARCHAR(64) NULL DEFAULT NULL,
  `oname` VARCHAR(64) NULL DEFAULT NULL,
  `onamef` VARCHAR(64) NULL DEFAULT NULL,
  `comment` VARCHAR(128) NULL DEFAULT NULL,
  `rmdate` DATETIME NULL DEFAULT NULL,
  `dummy_regno` INT NOT NULL,
  PRIMARY KEY (`StaffID`),
  INDEX `account_key` (`account` ASC))
ENGINE = InnoDB
COMMENT = 'staff info';


-- -----------------------------------------------------
-- Table `conkan`.`pg_room`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conkan`.`pg_room` ;

CREATE TABLE IF NOT EXISTS `conkan`.`pg_room` (
  `RoomID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL,
  `roomNo` VARCHAR(64) NOT NULL,
  `max` INT NULL DEFAULT NULL,
  `type` VARCHAR(64) NOT NULL,
  `size` INT NULL DEFAULT NULL,
  `tablecnt` INT NULL DEFAULT NULL,
  `chaircnt` INT NULL DEFAULT NULL,
  `equips` VARCHAR(64) NULL DEFAULT NULL,
  `useabletime` VARCHAR(64) NULL DEFAULT NULL,
  `net` ENUM('NONE','W','E') NOT NULL,
  `rmdate` DATETIME NULL DEFAULT NULL,
  PRIMARY KEY (`RoomID`),
  INDEX `roomNo_key` (`roomNo` ASC))
ENGINE = InnoDB
COMMENT = 'room info';


-- -----------------------------------------------------
-- Table `conkan`.`pg_all_equip`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conkan`.`pg_all_equip` ;

CREATE TABLE IF NOT EXISTS `conkan`.`pg_all_equip` (
  `EquipID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL,
  `equipNo` VARCHAR(64) NOT NULL,
  `spec` VARCHAR(64) NULL DEFAULT NULL,
  `comment` VARCHAR(64) NULL DEFAULT NULL,
  `rmdate` DATETIME NULL DEFAULT NULL,
  PRIMARY KEY (`EquipID`),
  INDEX `equipNo_key` (`equipNo` ASC),
  UNIQUE INDEX `equipNo_UNIQUE` (`equipNo` ASC))
ENGINE = InnoDB
COMMENT = 'all equipment info';


-- -----------------------------------------------------
-- Table `conkan`.`pg_reg_program`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conkan`.`pg_reg_program` ;

CREATE TABLE IF NOT EXISTS `conkan`.`pg_reg_program` (
  `PgID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(64) NOT NULL,
  `namef` VARCHAR(64) NOT NULL,
  `regdate` DATE NOT NULL,
  `regname` VARCHAR(64) NOT NULL,
  `regMa` VARCHAR(64) NOT NULL,
  `regno` INT NOT NULL,
  `type` VARCHAR(64) NOT NULL,
  `place` VARCHAR(64) NOT NULL,
  `layout` VARCHAR(64) NOT NULL,
  `date` VARCHAR(64) NOT NULL,
  `classLen` VARCHAR(64) NOT NULL,
  `expMaxcnt` VARCHAR(64) NOT NULL,
  `content` VARCHAR(128) NOT NULL,
  `contentPub` VARCHAR(64) NOT NULL,
  `realPub` VARCHAR(64) NOT NULL,
  `afterPub` VARCHAR(64) NOT NULL,
  `avoidDup` VARCHAR(128) NULL DEFAULT NULL,
  `experience` VARCHAR(64) NOT NULL,
  `comment` VARCHAR(128) NULL DEFAULT NULL,
  PRIMARY KEY (`PgID`))
ENGINE = InnoDB
COMMENT = 'program registration data';


-- -----------------------------------------------------
-- Table `conkan`.`pg_reg_cast`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conkan`.`pg_reg_cast` ;

CREATE TABLE IF NOT EXISTS `conkan`.`pg_reg_cast` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `PgID` INT UNSIGNED NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `namef` VARCHAR(64) NULL DEFAULT NULL,
  `entrantRegNo` INT UNSIGNED NULL DEFAULT NULL,
  `needReq` ENUM('req','accepted','innego','yetnego') NOT NULL,
  `needGuest` ENUM('Y','N') NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `PgId_fkey_idx` (`PgID` ASC),
  CONSTRAINT `reg_cast_PgId_fkey`
    FOREIGN KEY (`PgID`)
    REFERENCES `conkan`.`pg_reg_program` (`PgID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'cast registration data';


-- -----------------------------------------------------
-- Table `conkan`.`pg_reg_equip`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conkan`.`pg_reg_equip` ;

CREATE TABLE IF NOT EXISTS `conkan`.`pg_reg_equip` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `PgID` INT UNSIGNED NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `count` INT UNSIGNED NOT NULL,
  `vIF` VARCHAR(64) NULL DEFAULT NULL,
  `aIF` VARCHAR(64) NULL DEFAULT NULL,
  `eIF` VARCHAR(64) NULL DEFAULT NULL,
  `intendE` VARCHAR(64) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `PgID_fkey_idx` (`PgID` ASC),
  CONSTRAINT `reg_equip_PgID_fkey`
    FOREIGN KEY (`PgID`)
    REFERENCES `conkan`.`pg_reg_program` (`PgID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'equipment registration data';


-- -----------------------------------------------------
-- Table `conkan`.`pg_program`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conkan`.`pg_program` ;

CREATE TABLE IF NOT EXISTS `conkan`.`pg_program` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `PgID` INT UNSIGNED NOT NULL,
  `StaffID` INT UNSIGNED NOT NULL,
  `status` VARCHAR(64) NOT NULL,
  `date1` DATE NULL DEFAULT NULL,
  `stime1` TIME NULL DEFAULT NULL,
  `etime1` TIME NULL DEFAULT NULL,
  `date2` DATE NULL DEFAULT NULL,
  `stime2` TIME NULL DEFAULT NULL,
  `etime2` TIME NULL DEFAULT NULL,
  `RoomID` INT UNSIGNED NULL DEFAULT NULL,
  `LayerNo` INT NULL DEFAULT 0,
  `progressPrp` VARCHAR(64) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `PgID_fkey_idx` (`PgID` ASC),
  INDEX `StaffID_fkey_idx` (`StaffID` ASC),
  INDEX `RoomID_fkey_idx` (`RoomID` ASC),
  CONSTRAINT `program_PgID_fkey`
    FOREIGN KEY (`PgID`)
    REFERENCES `conkan`.`pg_reg_program` (`PgID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `program_StaffID_fkey`
    FOREIGN KEY (`StaffID`)
    REFERENCES `conkan`.`pg_staff` (`StaffID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `program_RoomID_fkey`
    FOREIGN KEY (`RoomID`)
    REFERENCES `conkan`.`pg_room` (`RoomID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'Program Management Master';


-- -----------------------------------------------------
-- Table `conkan`.`pg_progress`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conkan`.`pg_progress` ;

CREATE TABLE IF NOT EXISTS `conkan`.`pg_progress` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `PgID` INT UNSIGNED NOT NULL,
  `StaffID` INT UNSIGNED NOT NULL,
  `repDateTime` DATETIME NOT NULL,
  `report` TEXT NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `PgID_fkey_idx` (`PgID` ASC),
  INDEX `StaffID_fkey_idx` (`StaffID` ASC),
  CONSTRAINT `progress_PgID_fkey`
    FOREIGN KEY (`PgID`)
    REFERENCES `conkan`.`pg_reg_program` (`PgID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `progress_StaffID_fkey`
    FOREIGN KEY (`StaffID`)
    REFERENCES `conkan`.`pg_staff` (`StaffID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'Progress data';


-- -----------------------------------------------------
-- Table `conkan`.`pg_all_cast`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conkan`.`pg_all_cast` ;

CREATE TABLE IF NOT EXISTS `conkan`.`pg_all_cast` (
  `CastID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `regno` INT UNSIGNED NULL DEFAULT NULL,
  `name` VARCHAR(64) NOT NULL,
  `namef` VARCHAR(64) NOT NULL,
  `status` VARCHAR(64) NOT NULL,
  `restdate` VARCHAR(64) NULL DEFAULT NULL,
  PRIMARY KEY (`CastID`),
  UNIQUE INDEX `regno_UNIQUE` (`regno` ASC))
ENGINE = InnoDB
COMMENT = 'All cast data';


-- -----------------------------------------------------
-- Table `conkan`.`pg_cast`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conkan`.`pg_cast` ;

CREATE TABLE IF NOT EXISTS `conkan`.`pg_cast` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `PgID` INT UNSIGNED NOT NULL,
  `CastID` INT UNSIGNED NOT NULL,
  `status` VARCHAR(64) NOT NULL,
  `name` VARCHAR(64) NULL DEFAULT NULL,
  `namef` VARCHAR(64) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `PgID_fkey_idx` (`PgID` ASC),
  INDEX `CastID_fkey_idx` (`CastID` ASC),
  CONSTRAINT `cast_PgID_fkey`
    FOREIGN KEY (`PgID`)
    REFERENCES `conkan`.`pg_reg_program` (`PgID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `cast_CastID_fkey`
    FOREIGN KEY (`CastID`)
    REFERENCES `conkan`.`pg_all_cast` (`CastID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'Cast Management master';


-- -----------------------------------------------------
-- Table `conkan`.`pg_equip`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `conkan`.`pg_equip` ;

CREATE TABLE IF NOT EXISTS `conkan`.`pg_equip` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `PgID` INT UNSIGNED NOT NULL,
  `EquipID` INT UNSIGNED NULL DEFAULT NULL,
  `count` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `PgID_fkey_idx` (`PgID` ASC),
  INDEX `EquipID_fkey_idx` (`EquipID` ASC),
  CONSTRAINT `equip_PgID_fkey`
    FOREIGN KEY (`PgID`)
    REFERENCES `conkan`.`pg_reg_program` (`PgID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `equip_EquipID_fkey`
    FOREIGN KEY (`EquipID`)
    REFERENCES `conkan`.`pg_all_equip` (`EquipID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'Equipment Management master';


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
