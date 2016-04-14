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
- docker-enterはないので、自分で作成する
    作成方法後述

1. DBサーバ

Microsoft Azureが用意しているmysqlサーバ(clearDB)は、
無料の火星コースでは、同時接続クライアント数が4に制限されているなど、少々使いづらい。
(BizSparkサブスクリプションでは、火星コースしか使えないらしい)

問題となるのは初期化時のみと思われるが、同時利用者が増えると問題になるかもしれないので、独自にmysqlサーバを立てる(dockerコンテナとして)
コストパフォーマンスの問題から、稼働サーバで mysql としてコンテナを立ち上げる

  1. 外部から使用しないので、アクセスポイントを作成する必要はない

  1. Docker公式の mysql Dockerイメージを利用

''''
docker> docker pull mysql:5.5
''''

  1. コンテナの起動
    rootのパスワードは、起動時に環境変数 MYSQL_ROOT_PASSWORD で設定
    mysqlのポート番号は、ホスト:コンテナ とも3306にする
    DBディレクトリは、稼働サーバの実ディレクトリにマップする
    
    稼働サーバのユーザホームディレクトリに、下記内容のShellスクリプトを置き、
    起動するのが望ましい ex ~/DB/run.sh

''''
#!/bin/bash
if [ "$1" ]; then
    MRPW=$1
else
    echo 'Usage: run.sh <MYSQL_ROOT_PASSWD>'
    exit
fi
docker stop mysql
docker rm mysql
docker run  -d --restart='always' --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=$MRPW -e HOSTNAME=mysql -v `pwd`/mysql:/var/lib/mysql mysql:5.5
''''

★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
1. systemdを利用して、常にconkan/mysql を起動するよう設定
    ※ daemontoolsと冗長でもあったほうがいいでしょう

1.1. 稼働サーバ (conkan)
 - /etc/systemd/system/conkan.service として、下記ファイルを作成

''''
[Unit]
Description=conkan
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/docker start conkan

[Install]
WantedBy=multi-user.target
''''
 - ファイルの登録と実行

下記コマンドを実行
````
VM> sudo systemctl enable /etc/systemd/system/conkan.service
````
※ sudo systemctl enable conkan.service でいいかも

1.1. DBサーバ(mysql)
 - /etc/systemd/system/mysqld.service として、下記ファイルを作成

''''
[Unit]
Description=mysqld
After=docker.service
Requires=docker.service
#After/Requiresはそのサービスが起動後に実行される

[Service]
ExecStart=/usr/bin/docker start mysql

[Install]
WantedBy=multi-user.target
''''
 - ファイルの登録と実行

下記コマンドを実行
````
VM> sudo systemctl enable /etc/systemd/system/mysqld.service
````
※ sudo systemctl enable mysqld.service でいいかも

★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
1. systemdを利用して、DBバックアップとログローテーションを実施
    ※ daemontoolsは冗長なので止めたほうが良いでしょう

1.1.【稼働サーバ】

1.1.1 DBバックアップ

  下記の2つのファイルを作成

 - /etc/systemd/system/conkandbbackup.service

''''
[Unit]
Description=conkan db backup
Requires=docker.service

[Service]
ExecStart=docker exec conkan /root/app/conkan/script/conkan_dbbackup.pl /root/app/conkan/conkan.yml /root/app/backup
Type=oneshot
''''

 - /etc/systemd/system/conkandbbackup.timer

''''
[Unit]
Description=daily conkan db backup

[Timer]
OnCalendar=*-*-* 05:00:00    # 毎日朝05:00に実施
Unit=conkandbbackup.service  # 名称が同じなので省略可能

[Install]
WantedBy=timers.target
''''

 - ファイルの登録と実行

下記コマンドを実行
````
VM> sudo systemctl enable conkandbbackup.service # 必要か?
VM> sudo systemctl enable conkandbbackup.timer   # 必要か?
VM> sudo systemctl daemon-reload
VM> sudo systemctl start conkandbbackup.timer
````

1.1.1 log lotation

  下記の2つのファイルを作成

 - /etc/systemd/system/loglotate.service

''''
[Unit]
Description=conkan log lotate
Requires=docker.service

[Service]
ExecStart=docker exec conkan /etc/cron.daily/logrotate
Type=oneshot
''''

 - /etc/systemd/system/loglotate.timer

''''
[Unit]
Description=daily conkan log lotate

[Timer]
OnCalendar=*-*-* 05:00:00   # 毎日朝05:00に実施
Unit=loglotate.service      # 名称が同じなので省略可能

[Install]
WantedBy=timers.target
''''

 - ファイルの登録と実行

下記コマンドを実行
````
VM> sudo systemctl enable loglotate.service # 必要か?
VM> sudo systemctl enable loglotate.timer   # 必要か?
VM> sudo systemctl daemon-reload
VM> sudo systemctl start loglotate.timer
````

1.1.【DBサーバ】

1.1.1 log lotation

 - /etc/systemd/system/loglotate.serviceとして、下記ファイルを作成

必要なloglotation

''''
[Unit]
Description=mysql loglotation
Requires=docker.service

[Service]
ExecStart=docker exec mysql /etc/cron.daily/logrotate
Type=oneshot
''''

loglotate.timer

''''
[Unit]
Description=daily mysql loglotation

[Timer]
OnCalendar=*-*-* 05:00:00   # 毎日朝05:00に実施
Unit=loglotate.service      # 名称が同じなので省略可能

[Install]
WantedBy=default.target
''''

 - ファイルの登録と実行

下記コマンドを実行
````
VM> sudo systemctl enable loglotate.service # 必要か?
VM> sudo systemctl enable loglotate.timer   # 必要か?
VM> sudo systemctl daemon-reload
VM> sudo systemctl start loglotate.timer
````

★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★

1. dockerの動作ログ参照方法

````
VM> sudo journalctl -u docker
````

1. docker-enter作成方法

稼働サーバの/opt/bin下に作成する。

````
docker> sudo mkdir -p /opt/bin
docker> sudo vi /opt/bin/docker-enter
docker> sudo chmod 0755 /opt/bin/docker-enter
````

docker-enterの中身は下記の通り
~~~~
#!/bin/sh

if [ -e $(dirname "$0")/nsenter ]; then
    # with boot2docker, nsenter is not in the PATH but it is in the same folder
    NSENTER=$(dirname "$0")/nsenter
else
    NSENTER=nsenter
fi

if [ -z "$1" ]; then
    echo "Usage: `basename "$0"` CONTAINER [COMMAND [ARG]...]"
    echo ""
    echo "Enters the Docker CONTAINER and executes the specified COMMAND."
    echo "If COMMAND is not specified, runs an interactive shell in CONTAINER."
else
    PID=$(docker inspect --format "{{.State.Pid}}" "$1")
    [ -z "$PID" ] && exit 1
    shift

    if [ "$(id -u)" -ne "0" ]; then
        which sudo > /dev/null
        if [ "$?" -eq "0" ]; then
          LAZY_SUDO="sudo "
        else
          echo "Warning: Cannot find sudo; Invoking nsenter as the user $USER." >&2
        fi
    fi
    
    # Get environment variables from the container's root process  '

    ENV=$($LAZY_SUDO cat /proc/$PID/environ | xargs -0 | grep =)

    # Prepare nsenter flags
    OPTS="--target $PID --mount --uts --ipc --net --pid --"

    # env is to clear all host environment variables and set then anew
    if [ $# -lt 1 ]; then
	# No arguments, default to `su` which executes the default login shell
        $LAZY_SUDO "$NSENTER" $OPTS env -i - $ENV su -m root
    else
        # Has command
        # "$@" is magic in bash, and needs to be in the invocation
        $LAZY_SUDO "$NSENTER" $OPTS env -i - $ENV "$@"
    fi
fi
~~~~
1. 一般ユーザでdockerを利用可能にする方法(Azureとは直接関係ない)

dockerグループに対象ユーザを追加する

docker > sudo vigr
docker > sudo vigr -s


EOF
