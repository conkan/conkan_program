-- MySQL Script
-- Model: conkan

-- 部屋情報のリセット

DELETE from pg_room;
ALTER TABLE pg_room AUTO_INCREMENT=1;

