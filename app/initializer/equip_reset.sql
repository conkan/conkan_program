-- MySQL Script
-- Model: conkan

-- 機材情報のリセット

DELETE from pg_all_equip;
ALTER TABLE pg_all_equip AUTO_INCREMENT=1;
INSERT INTO pg_all_equip (name, equipNo) VALUES("持ち込み映像機器","bring-AV"),("持ち込みPC","bring-PC");

