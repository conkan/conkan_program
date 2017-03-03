-- MySQL Script
-- Model: conkan

-- システム設定値のリセット (システム設定情報ではない)

UPDATE pg_system_conf SET pg_conf_value='[\"2017/08/26\",\"2017/08/27\"]' where pg_conf_code="dates";
UPDATE pg_system_conf SET pg_conf_value='[\"09:00\",\"09:00\"]' where pg_conf_code='start_hours';
UPDATE pg_system_conf SET pg_conf_value='[\"21:00\",\"18:00\"]' where pg_conf_code='end_hours';
UPDATE pg_system_conf SET pg_conf_value='[\"公開\",\"実行\",\"調整中\",\"保留\",\"中止\",\"統合\",\"分割\",\"要確認\"]' where pg_conf_code='pg_status_vals';
UPDATE pg_system_conf SET pg_conf_value='[\"#008080\",\"#008000\",\"#00ffff\",\"#ffff00\",\"#808000\",\"#880000\",\"#808000\",\"#ffcc33\",\"#d3d3d3\"]' where pg_conf_code='pg_status_color';
UPDATE pg_system_conf SET pg_conf_value='[\"公開\",\"実行\"]' where pg_conf_code='pg_active_status';
UPDATE pg_system_conf SET pg_conf_value='[\"申込者\",\"未交渉\",\"申込者交渉中\",\"委員会交渉中\",\"保留\",\"企画中止\",\"企画不参加\",\"大会不参加\",\"要確認\",\"出演了承済\",\"出演(非表示)\",\"不参加(バーチャル出演)\",\"客席で参加\",\"欠席\",\"裏方参加\",\"通訳として参加\",\"部屋付きスタッフ\"]' where pg_conf_code='cast_status_vals';
UPDATE pg_system_conf SET pg_conf_value='[{\"ホワイトボード\":\"provide\"},{\"壇上マイク\":\"multi\"},{\"客席マイク\":\"multi\"},{\"モニタ/スクリーン\":\"provide\"},{\"BD/DVDプレイヤー\":\"provide\"},{\"書画カメラ\":\"provide\"},{\"持ち込み映像機器\":\"bring-av\"},{\"持ち込みPC\":\"bring-pc\"}]' where pg_conf_code='def_regEquip';
UPDATE pg_system_conf SET pg_conf_value='[\"一般参加\",\"交渉中\",\"ゲスト参加(Web登録済)\",\"ゲスト参加(一般参加から移行済)\",\"Web登録誘導中\",\"ゲスト参加(招待状送付、Web登録済)\",\"ゲスト同伴者\",\"ゲスト同伴者(通訳)\",\"スタッフ参加\",\"住所確認中\",\"依頼済→承諾(未登録)\",\"企画中止につき交渉打ち切り\",\"招待状発送済(回答待ち)\",\"招待状発送→不参加\",\"招待状発送→不参加(未登録)\",\"招待状発送→未着\",\"招待未送付\",\"大会不参加\",\"要確認\"]' where pg_conf_code='contact_status_vals';
UPDATE pg_system_conf SET pg_conf_value='{\"2017/08/26\":[540,1260,0,\"09\",\"21\"],\"2017/08/27\":[540,1080,12,\"09\",\"18\"]}' where pg_conf_code='gantt_scale_str';
UPDATE pg_system_conf SET pg_conf_value='<table class=ganttHead><tr><th colspan=12>2017/08/26</th><th colspan=9>2017/08/27</th></tr><tr><td class=ganttCell>09</td><td class=ganttCell>10</td><td class=ganttCell>11</td><td class=ganttCell>12</td><td class=ganttCell>13</td><td class=ganttCell>14</td><td class=ganttCell>15</td><td class=ganttCell>16</td><td class=ganttCell>17</td><td class=ganttCell>18</td><td class=ganttCell>19</td><td class=ganttCell>20</td><td class=ganttCell>09</td><td class=ganttCell>10</td><td class=ganttCell>11</td><td class=ganttCell>12</td><td class=ganttCell>13</td><td class=ganttCell>14</td><td class=ganttCell>15</td><td class=ganttCell>16</td><td class=ganttCell>17</td></tr></table>' where pg_conf_code='gantt_header';
UPDATE pg_system_conf SET pg_conf_value='{\"\":\"#d3d3d3\",\"要確認\":\"#ffcc33\",\"中止\":\"#808000\",\"実行\":\"#008000\",\"分割\":\"#808000\",\"統合\":\"#88000\",\"保留\":\"#ffff00\",\"調整中\":\"#00ffff\",\"公開\":\"#008080\"}' where pg_conf_code='gantt_color_str';
UPDATE pg_system_conf SET pg_conf_value='<table class=ganttRowBack><tr class=ui-grid-row><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td><td class=ganttCell></td></tr></table>' where pg_conf_code='gantt_back_grid';
UPDATE pg_system_conf SET pg_conf_value=21 where pg_conf_code='gantt_colmnum';
