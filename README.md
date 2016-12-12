conkan_program
======

汎用コンベンション運営管理システムconkan 企画管理サブシステム

各種コンベンション(主にSF大会)の、企画、機材 を管理するシステム。

実装範囲
======
conkan全体のうち、企画/機材管理機能のみ実装する

参加者(関係者)に関しては、大会参加番号で別システムconkan_stakeholderと紐付ける


事前準備
----------------
* 稼働サーバ
conkan_programのDockerコンテナを動かすサーバ
リバースプロキシとして、nginxも起動する。
nginxはホストで直接起動、Dockerコンテナとして起動 のどちらでも良い

例:Microsoft AzureのCoreOS VM でnginx Dockerコンテナとconkan_program Dockerコンテナを起動
例:AWS EC2のCentOS VMで、nginx自身とconkan_program Dockerコンテナを起動

* DBサーバ
稼働サーバ(で動かすDockerコンテナ)からアクセス可能な、mysqlサーバを用意する。
特に初期化時に多数同時接続するので、クライアント接続制限がゆるい方が望ましい。
(接続制限が4だと、初期化中にエラーになる事がある。
 時間をおけば復旧し継続できるので実害はない)

例:Microsoft AzureのCoreOS VMで、mysqlのDockerコンテナ(ex mysql:5.5)を起動
例:AWS RDSのmysqlサービス

インストール方法/初期設定
----------------

INSTALL.md 参照

EOF
