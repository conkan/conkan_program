-- Convert schema 'sql/conkan-Schema-0.0004-MySQL.sql' to 'conkan::Schema v0.0005':;

BEGIN;

ALTER TABLE pg_reg_cast CHANGE COLUMN needreq needreq varchar(64) NULL,
                        CHANGE COLUMN needguest needguest varchar(10) NULL;

ALTER TABLE pg_reg_program DROP PRIMARY KEY,
                           CHANGE COLUMN regno regno varchar(64) NOT NULL,
                           CHANGE COLUMN layout layout varchar(64) NOT NULL,
                           ADD PRIMARY KEY (pgid);


COMMIT;

