インストール手順
====

データベース設定
====

以下は、mysqlのrootユーザで実行

1. データベースおよび管理ユーザ作成

````
mysql> create database [[DB名]] default character set utf8;
mysql> grant all on [[DB名]].* to [[管理ユーザ名]] identified by '[パスワード]';
mysql> flush privileges;
mysql> exit;

DB名、管理ユーザ名、パスワードは後で使用するので控えておくこと


