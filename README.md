# conkan_program

汎用コンベンション運営管理システムconkan 企画管理サブシステム

各種コンベンション(主にSF大会)の、企画、機材 を管理するシステム。

# 実装範囲

conkan全体のうち、企画/機材管理機能のみ実装する

参加者(関係者)に関しては、大会参加番号で別システムconkan_stakeholderと紐付ける

また、企画登録フロントエンドとして、prog_registを使用する。
prog_regist向けにWebAPIを提供する。
WebAPIの詳細は、DocMemo/pgreg_WebAPI.md を参照

## バージョンについて

conkan_programのバージョンは、以下の形式とする
    M.N.J
        M: メジャーバージョン
        N: 次期メジャーバージョン
            開発版   M+1
            stable版 0
        J: マイナーバージョン
            開発版   バグフィックスによりインクリメント
            stable版 随時インクリメント

企画登録WebAPIのバージョンは以下の形式とし、'WebAPI_VERSION'の値として使用する。
    K.L
        K: 対象conkan_programメジャーバージョン
            開発版   上記N
            stable版 上記M
        L: 原則として 0
なお、conkan_program 1.0.0のWebAPIには、バージョン指定が存在しない

## 事前準備

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

## インストール方法/初期設定

INSTALL.md 参照

EOF
