-- MySQL Script
-- Model: conkan

-- スタッフ情報のリセット

DELETE from login_log;
ALTER TABLE login_log AUTO_INCREMENT=1;
DELETE from pg_staff where staffid > 2;

