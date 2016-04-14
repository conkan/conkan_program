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

conkanインストールと起動
====

1. 稼働サーバ条件

- dockerのイメージ生成と、コンテナ起動ができる環境であること

以下、稼働サーバを<稼働サーバ>と表記する

1. デプロイ

GitHub https://github.com/conkan/conkan_program のmastarブランチを
稼働サーバに展開する
(zipをダウンロードして展開してもよいが、update時の手間を考慮するとcloneしたほうが良い)

$> git clone git://github.com/conkan/conkan_program <Dockerホーム>

以下、展開したディレクトリを<Dockerホーム>と表記する

1. 稼働サーバの設定ファイル展開

<Dockerホーム>/baseconf/ 下に、
稼働サーバで使用する設定ファイルが存在するので、個々に配置する。

<Dockerホーム>/baseconf/base/HOME 下のものは、常時配置
    _bashrc                 =>  ~/.bashrc   (0644)
    _cshrc                  =>  ~/.cshrc    (0644)
    _my.cnf                 =>  ~/.my.cnf   (0644)
    _tcshrc                 =>  ~/.tcshrc   (0644)
    _vimrc                  =>  ~/.vimrc    (0644)

<Dockerホーム>/baseconf/base/OPTBIN 下のものは、常時配置
    docker-enter            =>  /opt/bin/docker-enter   (755)

<Dockerホーム>/baseconf/conkan/SYSTEM 下のものは、systemd利用時に配置
  ※coreOS上で動かす場合必須
    conkan.service          =>  /etc/systemd/system/conkan.service
    conkandbbackup.service  =>  /etc/systemd/system/conkandbbackup.service
    conkandbbackup.timer    =>  /etc/systemd/system/conkandbbackup.timer
    conkanloglotate.service =>  /etc/systemd/system/conkanloglotate.service
    conkanloglotate.timer   =>  /etc/systemd/system/conkanloglotate.timer

systemd利用開始処理として、以下のコマンドを実施

稼働サーバ > sudo systemctl enable conkan.service           ★★★
稼働サーバ > sudo systemctl enable conkandbbackup.service   ★★★
稼働サーバ > sudo systemctl enable conkanloglotate.service  ★★★
稼働サーバ > sudo systemctl daemon-reload
稼働サーバ > sudo systemctl start conkandbbackup.timer
稼働サーバ > sudo systemctl start conkanloglotate.timer

1.1 Docker利用TIPS

 - 一般ユーザでdockerを利用可能にする方法

    dockerグループに対象ユーザを追加しておく

    稼働サーバ > sudo vigr
    稼働サーバ > sudo vigr -s

 - dockerの動作ログ参照方法

    稼働サーバ > sudo journalctl -u docker

1. サーバ証明書の生成

<稼働サーバ>で実施

稼働サーバ > cd <Dockerホーム>
稼働サーバ > sudo ./cert.sh <conkanトップURLのFQDN>

ここで生成したサーバ証明書は、dockerコンテナ起動時(nginx起動時)に読み込む

1. ダミー設定ファイル作成

<稼働サーバ>で実施

稼働サーバ > cd <Dockerホーム>/app/conkan
稼働サーバ > cp conkan.yml_default conkan.yml

1. dockerイメージの取得

<稼働サーバ>で実施

稼働サーバ > docker pull srem/conkan

1. dockerコンテナの起動

<稼働サーバ>で実施

稼働サーバ > cd <Dockerホーム>
稼働サーバ > ./run.sh product

引数 product を指定しなかった場合、外部(The Internet)からのconkanへのアクセスポートは
  HTTP  30080
  HTTPS 30443
となるので注意

dockerコンテナの起動により、nginx,conkan自体も自動的に起動する。

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
DB側の同時接続数が4だと、login表示のタイミングでエラー(接続数オーバー)になる
ことがある
その場合は、しばらく時間を置いてから画面をリロードすれば良い
(同時接続数を増やせばよいのだが、Azureが用意しているmysqlサーバ(cleanDB)の
 無料プランでは、接続数は4固定。
 有料プランはBizParkサブスクリプションでは購入できないっぽい)

1. 最初の管理者登録

admin としてlogin後、タブ「管理者登録」をクリックする。
必要に応じて、CybozuLive認証画面を経由し、
【管理者登録ページ】が表示されるので、必要な項目を入力し、登録する。

<<EOF>>
