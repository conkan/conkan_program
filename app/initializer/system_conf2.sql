UPDATE pg_system_conf SET pg_conf_code="dates",         pg_conf_name="開催年月日列",    pg_conf_value="[\"2015/08/29\",\"2015/08/30\"]"                                 where pg_conf_code="first_date";
UPDATE pg_system_conf SET pg_conf_code="start_times1",  pg_conf_name="初日開始時刻列",  pg_conf_value="[\"10:30\",\"12:30\",\"14:30\",\"16:30\",\"18:30\",\"20:00\"]"   where pg_conf_code="first_start_times";
UPDATE pg_system_conf SET pg_conf_code="end_times1",    pg_conf_name="初日終了時刻列",  pg_conf_value="[\"12:00\",\"14:00\",\"16:00\",\"18:00\",\"19:30\",\"21:30\"]"   where pg_conf_code="first_end_time";
UPDATE pg_system_conf SET pg_conf_code="start_times2",  pg_conf_name="二日目開始時刻列",pg_conf_value="[\"09:30\",\"11:30\",\"13:30\",\"15:15\"]"                       where pg_conf_code="second_start_times";
UPDATE pg_system_conf SET pg_conf_code="end_times2",    pg_conf_name="二日目終了時刻列",pg_conf_value="[\"11:00\",\"13:00\",\"15:00\",\"16:00\"]"                       where pg_conf_code="second_end_time";
