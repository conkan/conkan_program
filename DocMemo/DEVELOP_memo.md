開発時メモ
=========
1.1 ディレクトリ

稼働サーバの、git cloneでconkanをdeployしたディレクトリを[repo]
稼働サーバの、[repo]/app/conkan を[conkan_top]
コンテナの /root/app/conkan を [conkan_root]
とする

1. データベーススキーマ作成

事前にmysqlのrootユーザで
データベース"conkan"を作成し、
管理ユーザにその全権を与えておく

1.1 データベースconkanを展開する。

<稼働サーバ(conkanをdeployしたサーバ)で実施>

下記[DBサーバ]は、開発用DBサーバである

````
$> cd [repo]/app
$> mysql -u [管理ユーザ名] -p --host=[DBサーバ] < initializer/conkan_init.sql
Enter password:[管理パスワード]
````
1.1 conkan::Schema を含むモデルクラスを作成する

<稼働サーバ(conkanをdeployしたサーバ)で実施>

下記[DBサーバ]は、開発用DBサーバである

````
$> cd [conkan_top]
$> ./script/conkan_create.pl model ConkanDB DBIC::Schema conkan::Schema create=static dbi:mysql:conkan:[DBサーバ] [管理ユーザ名] [管理パスワード] AutoCommit=1 mysql_enable_utf8=1 on_connect_do='["SET NAMES utf8", "SET time_zone='"'+09:00'"'"]'
````
モデルクラス作成(更新)後、[conkan_top]/lib/conkan/Schema.pm の$VERSIONの値を
増やすのを忘れないこと
(同じ値だとupgrade対象にならない)

````
our $VERSION = '0.00xx';
````

1. デバッグ起動

デバッグ用のconkanは、コンテナを再起動することで起動

<稼働サーバ(conkanをdeployしたサーバ)で実施>

[本番用]
````
$> cd [repo]
$> ./run.sh product
````

[動作検証用]
````
$> cd [repo]
$> ./run.sh
````

[デバッグ用]
````
$> cd [repo]
$> ./run.sh debug
````

1. 本番用サーバ、動作検証用サーバでのデバッグログ

<conkan_programコンテナ内で実施>

本番用サーバ、動作検証用サーバでデバッグログを得るには、
[conkan_root]/lib/conkan.pmを修正し、再起動する必要がある

~~~~
use Catalyst qw/
    -Debug -Log=debug <- 追加
    ConfigLoader
~~~~
本番用サーバ、動作検証用サーバの再起動(再読み込み)はHUPシグナルを送ることで実現

````
$> pkill -HUP starman
````

1. CatalystデバッグTIPS

- Catalyst内部での例外発生時、実際にどこで発生したかを知るには
[conkan_root]/lib/conkan.pmを修正し、再起動する必要がある
~~~~
$Carp::Verbose =1;
~~~~

- Catalystが発行するSQLを観るには
サーバ起動前に環境変数 DBIC_TRACEを1に設定する
(run.shを修正)

````
$> cd [conkan_root]
$> export DBIC_TRACE=1;./script/conkan_server.pl -r -d
````

1. データベース 企画クリア

データベース 登録した企画をクリアするには、regprog_reset.sqlを使う

<稼働サーバ(conkanをdeployしたサーバ)で実施>

下記[DBサーバ]は、クリア対象のDBサーバ(ほぼ開発用)である

````
$> cd [repo]/app
$> mysql -u [管理ユーザ名] -p --host=[DBサーバ] [DB名] < initializer/regprog_reset.sql
Enter password:[管理パスワード]
````
