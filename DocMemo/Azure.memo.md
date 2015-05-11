Microsoft Azure 特有のメモ
==========================

1. 稼働サーバ用VM作成

Azure Portalで、CoreOSを選択してVMを作成すれば良い
(docker環境を含んでいる)

注意点:
- デフォルトだとアクセスURLにランダムな文字が付け加わるので、ちゃんと指定すること
- HTTPSアクセスポイントを作成するのを忘れないように
- SSHアクセスポイントは自動で作成するが、外部ポート番号が22ではないので、一旦削除して再作成したほうが良い
- docker-enterはないので、自分で作成する
    作成方法後述

1. DBサーバ

Microsoft Azureが用意しているmysqlサーバ(clearDB)は、
無料の火星コースでは、同時接続クライアント数が4に制限されているなど、少々使いづらい。
(BizSparkサブスクリプションでは、火星コースしか使えないらしい)

問題となるのは初期化時のみと思われるが、同時利用者が増えると問題になるかもしれないので、独自にmysqlサーバを立てる(dockerコンテナとして)

  1. Azure Portalで、CoreOSを選択してVMを作成(docker環境を含んでいる)
    Docker環境作成にあたっての注意事項は、稼働サーバと同じ
    (HTTPSアクセスポイントではなく、MYSQLアクセスポイント(3306)を作成)

  1. Docker公式の mysql Dockerイメージを利用
    ''''
    docker> docker pull mysql:5.5
    ''''
  1. コンテナの起動
    rootのパスワードは、起動時に環境変数 MYSQL_ROOT_PASSWORD で設定
    mysqlのポート番号は、ホスト:コンテナ とも3306にする
    ''''
    docker> docker run --name mysql -e MYSQL_ROOT_PASSWORD=xxxx -d -p 3306:3306 mysql:5.5
    ''''
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
