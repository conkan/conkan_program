開発時メモ
=========

1. データベース作成

事前にmysqlのrootユーザで
データベース"conkan"を作成し、
管理ユーザにその全権を与えておく

下記DBサーバは、開発用DBサーバである

````
$> cd [conkan_root]/..
$> mysql -u [管理ユーザ名] -p --host=[DBサーバ] < initializer/conkan_init.sql
Enter password:[管理パスワード]
````
1. スキーマ作成

````
$> cd [conkan_root]
$> ./script/conkan_create.pl model ConkanDB DBIC::Schema conkan::Schema create=static dbi:mysql:conkan:[DBサーバ] [管理ユーザ名] [管理パスワード] AutoCommit=1 on_connect_do='["SET NAMES utf8"]'

1. その他

- Catalyst内部での例外発生時、実際にどこで発生したかを知るには
$Carp::Verbose =1;

