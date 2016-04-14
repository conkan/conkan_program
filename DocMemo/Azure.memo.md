Microsoft Azure 特有のメモ
==========================

1. 稼働サーバ用VM作成

Azure Portalで、CoreOSを選択してVMを作成すれば良い
(docker環境を含んでいる)

注意点:
- CoreOSのstableを使うこと(AlphaやBetaでは、git,dockerが入っていないことがある)
- デフォルトだとアクセスURLにランダムな文字が付け加わるので、ちゃんと指定すること
- HTTPSアクセスポイント(443)を作成するのを忘れないように
- SSHアクセスポイントは自動で作成するが、外部ポート番号が22ではないので、一旦削除して再作成したほうが良い

1. DBサーバ

Microsoft Azureが用意しているmysqlサーバ(clearDB)は、
無料の火星コースでは、同時接続クライアント数が4に制限されているなど、少々使いづらい。
(BizSparkサブスクリプションでは、火星コースしか使えないらしい)

問題となるのは初期化時のみと思われるが、同時利用者が増えると問題になるかもしれないので、独自にmysqlサーバを立てる(dockerコンテナとして)
コストパフォーマンスの問題から、稼働サーバで mysql としてコンテナを立ち上げる

1.1 外部から使用しないので、アクセスポイントを作成する必要はない

1.1 Docker公式の mysql Dockerイメージを利用

''''
docker> docker pull mysql:5.5
''''

1.1  DBサーバの設定ファイル展開

※以下<Dockerホーム>は、
  GitHub https://github.com/conkan/conkan_program のmastarブランチを
  展開したディレクトリである

<Dockerホーム>/baseconf/下に、
DBサーバで使用する設定ファイルが存在するので、個々に配置する。
# coreOS上のDockerコンテナで動かす場合、すべて配置する

<Dockerホーム>/baseconf/mysql/HOME 下のものは、常時配置
    run.sh                  =>  ~/DB/run.sh (0755)

<Dockerホーム>/baseconf/mysql/SYSTEM 下のものは、systemd利用時に配置
  ※coreOS上で動かす場合必須
    mysqld.service          =>  /etc/systemd/system/mysqld.service
    mysqlloglotate.service  =>  /etc/systemd/system/mysqlloglotate.service
    mysqlloglotate.timer    =>  /etc/systemd/system/mysqlloglotate.timer

稼働サーバとDBサーバが同じVMの場合、以下は既に展開済み
<Dockerホーム>/baseconf/base/HOME 下のものは、常時配置
    _bashrc                 =>  ~/.bashrc   (0644)
    _cshrc                  =>  ~/.cshrc    (0644)
    _my.cnf                 =>  ~/.my.cnf   (0644)
    _tcshrc                 =>  ~/.tcshrc   (0644)
    _vimrc                  =>  ~/.vimrc    (0644)

<Dockerホーム>/baseconf/base/OPTBIN 下のものは、常時配置
    docker-enter            =>  /opt/bin/docker-enter   (755)

systemd利用開始処理として、以下のコマンドを実施

DBサーバ > sudo systemctl enable mysqld.service           ★★★
DBサーバ > sudo systemctl enable mysqlloglotate.service   ★★★
DBサーバ > sudo systemctl daemon-reload
DBサーバ > sudo systemctl start mysqlloglotate.timer


1.1. コンテナの起動
    rootのパスワードは、起動時に環境変数 MYSQL_ROOT_PASSWORD で設定
    mysqlのポート番号は、ホスト:コンテナ とも3306にする
    DBディレクトリは、DBサーバの実ディレクトリ(例:~/DB/mysql)にマップする
    
    DBサーバの設定ファイル展開で配置した
        ~/DB/run.sh
    が上記を実施するスクリプトである

1.1  コンテナの設定ファイル展開

コンテナで使用する設定ファイルが存在するので、個々に配置する。
※<Dockerホーム>の内容は直接コンテナから参照できないので、
  事前にコンテナが参照する実ディレクトリなどにコピーしておく。

<Dockerホーム>/baseconf/mysql/CONHOME 下のものは、常時配置
    _bashrc                 =>  <コンテナROOT>/.bashrc   (0644)
    _my.cnf                 =>  <コンテナROOT>/.my.cnf   (0644)

EOF
