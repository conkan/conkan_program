UPDATE pg_system_conf SET pg_conf_value="[\"公開\",\"実行\",\"調整中\",\"保留\",\"中止\",\"統合\",\"分割\",\"要確認\"]" where pg_conf_code="pg_status_vals";
UPDATE pg_system_conf SET pg_conf_value="[\"#008080\",\"#008000\",\"#00ffff\",\"#ffff00\",\"#808000\",\"#880000\",\"#808000\",\"#ffcc33\",\"#d3d3d3\"]" where pg_conf_code="pg_status_color";

