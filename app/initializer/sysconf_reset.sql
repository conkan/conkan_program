-- MySQL Script
-- Model: conkan

-- システム設定値のリセット (システム設定情報ではない)

UPDATE pg_system_conf SET pg_conf_value='[\"2016/07/09\",\"2016/07/10\"]' where pg_conf_code="dates";
UPDATE pg_system_conf SET pg_conf_value='[\"12:00\",\"07:00\"]' where pg_conf_code='start_hours';
UPDATE pg_system_conf SET pg_conf_value='[\"29:30\",\"11:00\"]' where pg_conf_code='end_hours';
UPDATE pg_system_conf SET pg_conf_value='[\"公開\",\"実行\",\"調整中\",\"保留\",\"中止\",\"統合\",\"分割\",\"要確認\"]' where pg_conf_code='pg_status_vals';
UPDATE pg_system_conf SET pg_conf_value='[\"#008080\",\"#008000\",\"#00ffff\",\"#ffff00\",\"#808000\",\"#880000\",\"#808000\",\"#ffcc33\",\"#d3d3d3\"]' where pg_conf_code='pg_status_color';
UPDATE pg_system_conf SET pg_conf_value='[\"公開\",\"実行\"]' where pg_conf_code='pg_active_status';
UPDATE pg_system_conf SET pg_conf_value='[\"申込者\",\"未交渉\",\"申込者交渉中\",\"委員会交渉中\",\"保留\",\"企画中止\",\"企画不参加\",\"大会不参加\",\"要確認\",\"出演了承済\",\"出演(非表示)\",\"不参加屋付きスタッフ\"]' where pg_conf_code='cast_status_vals';
UPDATE pg_system_conf SET pg_conf_value='[\"一般参加\",\"交渉中\",\"ゲスト参加(Web登録済)\",\"ゲスト参加(一般参加から移行済)\",\"Web登録誘導中\",\"ゲスト参加(招待状送付、Web登録済)\",\"ゲスト同伴者\",\"ゲスト同伴者(通訳)\",\"スタッフ参加\",\"住所確認中\",\"依頼済→承諾(未登録)\",\"企画中止につき交渉打ち切り\",\"招待状発送済(回答待ち)\",\"招待状発送→不参加\",\"招待 状発送→不参加(未登録)\",\"招待状発送→未着\",\"招待未送付\",\"大会不参加\",\"要確認\"]' where pg_conf_code='contact_status_vals';
