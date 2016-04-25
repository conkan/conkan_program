UPDATE pg_system_conf SET pg_conf_value="[\"公開\",\"実行\",\"調整中\",\"保留\",\"中止\",\"統合\",\"分割\"]" where pg_conf_code="pg_status_vals";
INSERT INTO pg_system_conf (pg_conf_code,pg_conf_name,pg_conf_value) VALUES("pg_status_color","各実行ステータス+未定色","[\"#008080\",\"#008000\",\"#00ffff\",\"#ffff00\",\"#808000\",\"#880000\",\"#808000\",\"#d3d3d3\"]"),("pg_active_status","CSV出力ステータス","[\"公開\",\"実行\"]");

