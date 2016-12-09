インストール手順
====

データベース設定
====

1. データベースおよび管理ユーザ作成

Azureなどクラウドサービスが提供するmysqlを使用する場合には、
それぞれのサービスで割り当てられるDB名、管理ユーザ名、パスワードを控えておく

＊管理ユーザに、DBに対する全権限と、全てに対するreload権限を与えること

もちろん、AzureなどのクラウドサービスのVM上に、
Dockerコンテナとしてmysqlを動かす(手動でデータベース作成)してもよい

手動でデータベースを作成する場合には、以下の処理をmysqlのrootユーザで実行
(DB名、管理ユーザ名、パスワードは、任意の値)


````
mysql> create database [DB名] default character set utf8;
mysql> grant all on [DB名].* to [管理ユーザ名] identified by '[パスワード]';
mysql> grant reload on *.* to [管理ユーザ名];
mysql> flush privileges;
mysql> exit;
````

DB名、管理ユーザ名、パスワードは、conkan初期化処理時に使用するので控えておくこと。
また、セキュリティ上これらの値は秘匿すべきである。
＊ reload権限は、バックアップのために必要

CybozuLive アプリケーション登録
====

1. デベロッパーアカウント登録 (未登録の場合)

https://developer.cybozulive.com にて登録

1. アプリケーションの登録

デベロッパセンターにログインしたら上メニューの「Myアプリケーション」をクリック
(通常、ログイン後初期表示)
「アプリケーションを登録する」をクリックし、conkanを登録する
以下の項目を入力

項目名                  | 設定する値
----------------------- | ---------------------------
アプリケーション名 | 任意の値
アプリケーションの種類 | ウェブブラウザ
コールバックURL | https://<conkanトップURL>/addstaff/cybozu
アクセスレベル | レベルA

登録すると、ConsumerKey と ConsumerSecret が表示される。

これらの値は、初期化処理時に使用するので控えておくこと。
また、セキュリティ上これらの値は秘匿すべきである。

conkan_program 開発環境構築
====

1. 稼働サーバ条件

- dockerのイメージ生成と、コンテナ起動ができる環境であること
- nginxはサーバ上で直接起動している方が良い

以下、稼働サーバを<稼働サーバ>と表記する

1. デプロイ

GitHub https://github.com/conkan/conkan_program のdevelopブランチを
稼働サーバに展開する

$> git clone git://github.com/conkan/conkan_program <repo>

以下、展開したディレクトリを<repo>と表記する

1. 稼働サーバの設定ファイル展開

<repo>/baseconf/ 下に、
稼働サーバで使用する設定ファイルが存在するので、個々に配置する。

<repo>/baseconf/base/HOME 下のものは、常時配置
    _bashrc                 =>  ~/.bashrc   (0644)
    _cshrc                  =>  ~/.cshrc    (0644)
    _my.cnf                 =>  ~/.my.cnf   (0644)
    _tcshrc                 =>  ~/.tcshrc   (0644)
    _vimrc                  =>  ~/.vimrc    (0644)

1.1 logrotate, cron設定 (centOS6)

<repo>/baseconf/conkan/ETC 下のものを、下記のように配置
    conkan_logrotate        =>  /etc/logrotate.d/conkan_program (0644)
    conkandbbackup          =>  /etc/cron.daily/conkandbbackup (0755)

1.1 systemd設定 (coreOS, centOS7)

<repo>/baseconf/conkan/SYSTEM 下のものを、下記のように配置
    conkan.service          =>  /etc/systemd/system/conkan.service
    conkandbbackup.service  =>  /etc/systemd/system/conkandbbackup.service
    conkandbbackup.timer    =>  /etc/systemd/system/conkandbbackup.timer
    conkanlogrotate.service =>  /etc/systemd/system/conkanlogrotate.service
    conkanlogrotate.timer   =>  /etc/systemd/system/conkanlogrotate.timer

systemd利用開始処理として、以下のコマンドを実施

稼働サーバ > sudo systemctl enable conkan.service
稼働サーバ > sudo systemctl start conkan.service
稼働サーバ > sudo systemctl start conkandbbackup.timer
稼働サーバ > sudo systemctl start conkanlogrotate.timer

※ 何らかの理由で設定ファイル(service, timer)を書き換えたら、
    稼働サーバ > sudo systemctl daemon-reload
を実施

1.1 Docker利用TIPS

 - 一般ユーザでdockerを利用可能にする方法

    dockerグループに対象ユーザを追加しておく

    稼働サーバ > sudo vigr
    稼働サーバ > sudo vigr -s

 - dockerの動作ログ参照方法

    稼働サーバ > sudo journalctl -u docker

1.1 自己証明サーバ証明書の生成

有効なサーバ証明書を保有しておらず、自己証明サーバ証明書を利用する場合には、
<稼働サーバ>で実施して作成する。

稼働サーバ > cd <repo>
稼働サーバ > sudo ./cert.sh <conkanトップURLのFQDN>

ここで生成したサーバ証明書は、nginx.confに指定する

1.1 nginxのリバースプロキシ設定

nginxの起動方法はここでは記述しない
conkan_programのリバースプロキシ設定部分のみ記述する

https://<サービスホストFQDN>/conkan_program でconkan_programにアクセスし、
conkan_program内でのリクエストが正しく処理されるよう、
/etc/nginx/nginx.conf に、以下のように設定する

+----
   <前略>
|http {
   <中略>
|   # redirect http to https
|   server {
|       listen      80;
|       server_name "";
|       return 301 https://$host$request_uri;
|   }
|
|# Settings for a TLS enabled server.
|   server {
|       listen      443 ssl default_server;
    <サーバ名、SSL設定省略>
|       # For conkan_program
|       location /conkan_program {
|           proxy_pass http://localhost:9002;
|           proxy_redirect / /conkan_program/; # レスポンスヘッダの置き換え
|       }
|
|       location / {
|           # Refererがconkan_programだったら、URIを書き換える
|           if ( $http_Referer ~ ^https://[^/]+/conkan_program/ ) {
|               rewrite ^/(.+) /conkan_program/$1;
|               set $rewriten 1;
|           }
|           # POSTの時は続けてそのURIの処理(上位サーバに渡す)
|           if ( $request_method ~* (post) ) {
|               rewrite ^/(.+) /$1 last;
|           }
|           # GETでURIを書き換えていた時はリダイレクト
|           if ( $rewriten ) {
|               rewrite ^/(.+) /$1 redirect;
|           }
|
|           root    /usr/share/nginx/html;
|       }
    <後略>
+----


1. dockerイメージの生成

<稼働サーバ>で実施

稼働サーバ > cd <repo>
稼働サーバ > ./build.sh

1. dockerコンテナの起動

<稼働サーバ>で実施

稼働サーバ > cd <repo>
稼働サーバ > ./run.sh

conkan_program は、9002ポートにてHTTPプロトコルを受け付ける

なお、./run.sh product と起動した場合、
稼働サーバのconkan_program本体(<repo>/app)ではなく、
conkan_programコンテナイメージ内のconkan_program本体(./build.sh時の<repo>/app)を使用する。

conkan初期化処理
====

1. 初期化アクセス

https://<conkanトップURL>/ にアクセスする。
初回のみ、【conkan初期化ページ】 が表示される。

すべての値を設定し、「初期化実行」をクリックすると、conkan初期化処理を実施する。

項目名                  | 設定する値
----------------------- | ---------------------------
adminパスワード | 初期化時の管理者登録にのみ使うアカウント adminのパスワード
DBサーバ | データベースサーバのFQDNまたはIPアドレス
DB名 | データベース設定で使用した DB名
DBユーザ | データベース設定で使用した 管理ユーザ名
DBパスワード | データベース設定で使用した パスワード
コンシュマートークンキー | CybozuLiveアプリケーション登録 で取得した ConsumerKey
コンシュマーシークレット | CybozuLiveアプリケーション登録 で取得した ConsumerSecret
グループ | 登録可否を判断するCybozuLiveグループ名

1. adminとして再login

初期化完了後、【conkan初期化完了>>管理者登録ページ】が表示される。
「管理者login」をクリックして、改めて admin としてloginする。
(loginする際のパスワードは、<<初期化アクセス>>で指定したもの

**注意**
初期deploy時、DBに複数の接続を実施することになり、
DB側の同時接続数が4以下だと、login表示のタイミングでエラー(接続数オーバー)になる
ことがある
その場合は、しばらく時間を置いてから画面をリロードすれば良い

1. 最初の管理者登録

admin としてlogin後、タブ「管理者登録」をクリックする。
必要に応じて、CybozuLive認証画面を経由し、
【管理者登録ページ】が表示されるので、必要な項目を入力し、登録する。

<<EOF>>
