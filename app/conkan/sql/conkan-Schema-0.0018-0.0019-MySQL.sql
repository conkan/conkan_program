-- Convert schema 'app/conkan/sql/conkan-Schema-0.0018-MySQL.sql' to 'conkan::Schema v0.0019':;

BEGIN;

ALTER TABLE pg_all_equip ADD COLUMN roomid integer unsigned NULL,
                         ADD COLUMN suppliers varchar(64) NULL,
                         ADD INDEX pg_all_equip_idx_roomid (roomid),
                         ADD CONSTRAINT pg_all_equip_fk_roomid FOREIGN KEY (roomid) REFERENCES pg_room (roomid) ON DELETE NO ACTION ON UPDATE NO ACTION;


COMMIT;

