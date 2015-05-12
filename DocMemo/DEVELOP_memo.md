開発時メモ
=========

1. データベース作成

事前にmysqlのrootユーザで
データベース"conkan"を作成し、
管理ユーザにその全権を与えておく

conkanをdeployしたサーバで、データベースconkanを展開する。
下記[DBサーバ]は、開発用DBサーバである

````
$> cd [conkan_root]/..
$> mysql -u [管理ユーザ名] -p --host=[DBサーバ] < initializer/conkan_init.sql
Enter password:[管理パスワード]
````
1. スキーマ作成

conkanをdeployしたサーバで、conkan::Schema を含むモデルクラスを作成する

````
$> cd [conkan_root]
$> ./script/conkan_create.pl model ConkanDB DBIC::Schema conkan::Schema create=static dbi:mysql:conkan:[DBサーバ] [管理ユーザ名] [管理パスワード] AutoCommit=1 on_connect_do='["SET NAMES utf8"]'

1. デバッグ起動

<Dockerコンテナ内で実施>

nginxにupstreamとして開発用サーバ(下記)を利用させるため、
/etc/nginx/nginx.conf を一部修正する(コメントを付け替え、Port3000を有効にする)

~~~~
        proxy_pass http://localhost:3000;     # 開発用
        # proxy_pass http://localhost:8080;
~~~~

開発用サーバは、Catalystが作成したものを使用

````
$> cd [conkan_root]
$> ./script/conkan_server.pl -r -d
````

1. 本番サーバでのデバッグログ

本番サーバ(starman Dockerコンテナ起動と同時に起動)でデバッグログを得るには、
[conkan_root]/lib/conkan.pmを修正し、再起動する必要がある

~~~~
use Catalyst qw/
    -Debug -Log=debug <- 追加
    ConfigLoader
~~~~
本番サーバの再起動(再読み込み)はHUPシグナルを送ることで実現

````
$> pkill -HUP starman
````

1. その他

- Catalyst内部での例外発生時、実際にどこで発生したかを知るには
$Carp::Verbose =1;

- Catalystが発行するSQLを観るには
サーバ起動前に環境変数 DBIC_TRACEを1に設定する
