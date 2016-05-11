package conkan::Controller::Root;
use strict;
use warnings;
use utf8;
use Moose;
use namespace::autoclean;
use DBI;
use Try::Tiny;
use String::Random qw/ random_string /;
use namespace::autoclean;
use Data::Dumper;
use Encode;
use conkan::Schema;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

conkan::Controller::Root - Root Controller for conkan

=head1 DESCRIPTION

login処理と初期設定のみ組み込み。それ以外は別のコントローラ

=head1 METHODS

=head2 auto

すべてのアクションで実施する処理

=cut

sub auto :Private {
    my ( $self, $c ) = @_;

    $c->log->info(localtime()
        . ' [' . $c->request->method . ']'
        . ' [' . $c->action->reverse . ']'
        . ' userid [' 
        . +( $c->user_exists ?  $c->user->get('staffid') : 'notlogin' ) . ']'
        . ' args ['
        . join('][', @{$c->request->args} ) . ']'
    );
    # 初期化済判断
    unless (exists($c->config->{inited})) {
        $c->log->info(localtime() . ' 未初期化');
        if ( ( $c->action->reverse eq 'index'  )        ||
             ( $c->action->reverse eq 'initialize' )    ||
             ( $c->action->reverse eq 'initialprocess' )
           ) {
            return 1;
        }
        $c->stash->{template} = 'yetinit.tt';
        $c->detach( '/yetinit' );
        return 0;
    }
    else {
        # DBスキーマアップデート
        my $coninfo = $c->config->{'Model::ConkanDB'}->{connect_info};
        my $schema = conkan::Schema->connect(
            $coninfo->{'dsn'}, $coninfo->{'user'}, $coninfo->{'password'},
            {
                RaiseError        => 1,
                mysql_enable_utf8 => $coninfo->{'mysql_enable_utf8'},
                on_connect_do     => $coninfo->{'on_connect_do'},
            }
        ); 
        my $newdbv = $schema->schema_version();
        my $olddbv = $schema->get_db_version();

        if (!$olddbv) {
            $schema->deploy( { add_drop_table => 1, } );
            $c->log->info( localtime() . ' DB Update : deploy');
        } elsif ( $newdbv != $olddbv ) {
            $schema->create_ddl_dir( 'MySQL', $newdbv, './sql', $olddbv );
            $schema->upgrade();
            $c->log->info( localtime() . ' DB Update : upgrade ['
                             . $schema->get_db_version() . ']');
        }
    }
    $c->config->{time_origin} = 0 unless (exists($c->config->{time_origin}));
    # login->login ループ回避
    if ( $c->action->reverse eq 'login' ) {
        return 1;
    }
    # addstaffはlogin不要
    if ( $c->action->reverse =~ /^addstaff/ ) {
        return 1;
    }
    # 強制login処理
    unless ( $c->user_exists ) {
        $c->log->info( localtime() . ' force login' );
        $c->visit( '/login' );
    }
    return 1;
}

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->go( '/initialize' ) unless (exists($c->config->{inited}));

    $c->response->redirect( '/mypage/list' );
}

=head2 yetinit

custum 404 error page (初期化していない)

=cut

sub yetinit :Local {
    my ( $self, $c ) = @_;
    $c->response->status(404);
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;

    my $action = $c->request->path();
    my $liid =  ($action eq 'timetable')      ? 'timetable'
              : ($action eq 'config/cast/list')       ? 'config_cast'
              : ($action eq 'config/equip/list')      ? 'config_equip'
              : 'mypage';
    $c->log->debug('>>> ' . localtime() . ' action : [' . $action . ']');
    $c->log->debug('>>> ' . localtime() . ' liid   : [' . $liid   . ']');
    $c->response->status(404);
    $c->stash->{self_li_id} = $liid;
    $c->stash->{template} = 'underconstract.tt';
}

=head2 login

login

=cut

sub login :Local {
    my ( $self, $c ) = @_;

    my $account = $c->request->body_params->{account};
    my $passwd  = $c->request->body_params->{passwd};
    my $realm   = $c->request->body_params->{realm};
    my $userinfo;

    if ( ( !defined($c->session->{'role'})
          || ( $c->session->{'role'} ne 'initial' ) )
       && ( $c->user_exists ) ) {
        return;
    }
    # session->{init_role} は引き継ぐ
    # session->{init_role} が空の時は、req->bodyparam->{init_role}を設定
    # (bodyparam->{init_role}は、initialprocessでのみ設定)
    my $init_role = $c->session->{init_role} ||
                    $c->request->body_params->{init_role};
    $c->delete_session('login') if ( $c->request->method eq 'POST' );
    $c->session->{init_role} = $init_role;
    my @r = $c->model('ConkanDB::PgStaff')->search({account=>{'!='=>'admin'}});
    if ( scalar @r ) {
        $c->stash->{'canaddstaff'} = 1;
    }
    if ( !$realm ) {
        return;
    }
    elsif ( $realm eq 'passwd' ) {
        if ( $c->authenticate( { account => $account, passwd => $passwd },
                               $realm ) ) {
            unless ( scalar @r ) {
                $c->session->{init_role} = 'addroot';
            }
            else {
                $c->session->{init_role} = undef;
            }
            if ( $c->user->get('passwd') && !$c->user->get('rmdate') ) {
                __PACKAGE__->LoginLogging( $c );
                if ( $c->action->reverse eq 'login' ) {
                    $c->response->redirect( '/mypage' );
                }
                return;
            }
        }
        $c->logout;
        $c->stash->{errmsg} = '認証失敗 再度loginしてください';
    }
    else {
        $c->error('Fatal access at '. scalar localtime );
    }
}

=head2 LoginLogging
                
ログイン履歴保存

スタッフテーブルの最終ログイン日時更新 & ログイン履歴レコード追加

=cut

sub LoginLogging {
    my ( $self,
         $c,            # コンテキスト
       ) = @_;

    try {
        my $staffid = $c->user->get('staffid');
        my $rowstaff = $c->model('ConkanDB::PgStaff')->find($staffid);
        $rowstaff->update(
            { 
                'lastlogin' =>  \'NOW()',
            },
        );
        $rowstaff = $c->model('ConkanDB::PgStaff')->find($staffid);
        my $logintime = $rowstaff->lastlogin();
        $c->model('ConkanDB::LoginLog')->create(
            {
                'staffid'       => $staffid,
                'login_date'    => $logintime,
            },
        );
    } catch {
        $c->detach( '_dberror', [ shift ] );
    };
}

=head2 _dberror

DBエラー表示

=cut

sub _dberror :Private {
    my ( $self, $c, $e) = @_; 
    $c->log->error('>>> ' . localtime() . ' dbexp : ' . Dumper($e) );
    $c->clear_errors();
    my $body = $c->response->body() || Dumper( $e );
    $c->response->body('<FORM>更新失敗<br/><pre>' . $body . '</pre></FORM>');
    $c->response->status(200);
}

=head2 logout

logout

=cut

sub logout :Local {
    my ( $self, $c ) = @_;
    $c->logout;
    $c->delete_session('logout');
    $c->response->redirect( '/login' );
}

=head2 initialize

Initialize

=cut

sub initialize :Private {
    my ( $self, $c ) = @_;
    # 初期化セッション開始
    $c->delete_session('initialize');
    $c->session->{'role'} = 'initial';
}

=head2 initialprocess

Initial process

=cut

sub initialprocess :Local {
    my ( $self, $c ) = @_;

    if (exists($c->config->{inited})) {
        $c->response->status(409);
        $c->response->body( 'Already Initialized' );
        return;
    }

    if (  !defined($c->session->{'role'})
       || ( $c->session->{'role'} ne 'initial' ) ) {
        $c->response->status(405);
        $c->response->body( 'Cannot Initialize (Direct Access)' );
        return;
    }

    my $adpw = $c->request->body_params->{adpw};
    my $dbnm = $c->request->body_params->{dbnm};
    my $dbsv = $c->request->body_params->{dbsv};
    my $dbus = $c->request->body_params->{dbus};
    my $dbpw = $c->request->body_params->{dbpw};
    my $adrt = $c->request->body_params->{addstaff};
    my $torg = $c->request->body_params->{torg} || 0;
    my $oakey= $c->request->body_params->{oakey};
    my $oasec= $c->request->body_params->{oasec};
    my $cygr = $c->request->body_params->{cygr};

    if ( ( !$adpw || !$dbnm || !$dbsv || !$dbus || !$dbpw ) ||
         ( ( $adrt eq 'cybozu' ) && ( !$oakey || !$oasec || !$cygr ) ) ) {
        $c->stash->{wrongtype} = 'param';
        $c->stash->{template} = 'wrongParam.tt';
        return;
    }

    $c->detach( '/_doInitialProc',
                [ $adpw, $dbnm, $dbsv, $dbus, $dbpw,
                  $adrt, $torg, $oakey, $oasec, $cygr ],
              );
}

=head2 _doInitialproc

Doing Initialize

=cut

sub _doInitialProc :Private {
    my ( $self, $c, 
         $adpw,     # adminパスワード
         $dbnm,     # DB名
         $dbsv,     # DBサーバ
         $dbus,     # DBユーザ
         $dbpw,     # DBユーザパスワード
         $adrt,     # スタッフ登録方法 plain | cybozu
         $torg,     # 時刻切り替え基準時
         $oakey,    # CybozuLive oAuthキー
         $oasec,    # CybozuLive oAuthシークレット
         $cygr,     # CybozuLive 参照グループ名
       ) = @_;

    my $dsn  = "dbi:mysql:$dbnm:$dbsv";

    # 接続可否確認
    my $dbh = DBI->connect( $dsn, $dbus, $dbpw, { mysql_enable_utf8 => 1, } );
    unless ( $dbh ) {
        $c->stash->{wrongtype} = 'connect';
        $c->stash->{template} = 'wrongParam.tt';
        return;
    }
    # 初期化処理
    try {
        # DBスキーマをdeploy
        my $schema = conkan::Schema->connect(
            $dsn, $dbus, $dbpw,
            {
                RaiseError => 1,
                mysql_enable_utf8 => 1,
                on_connect_do => ["SET NAMES utf8"],
            }
        );
        if ($schema->get_db_version()) {
            $dbh->do( 'DROP TABLE dbix_class_schema_versions' );
        }
        $schema->deploy( { add_drop_table => 1, } );
        $c->log->info( localtime() . ' Initial : deploy');

        # 規定値一括登録
        $dbh->do( 'SET NAMES utf8' );

        # pg_system_conf を登録
        my $system_conf_f = $c->config->{home} . '/../initializer/system_conf.csv';
        $dbh->do( "LOAD DATA LOCAL INFILE '$system_conf_f' " .
                    'INTO TABLE pg_system_conf ' .
                    "FIELDS TERMINATED BY ',' ENCLOSED BY '\"';" );
        # 時刻シフト
        if ( $torg != 0 ) {
            $dbh->do( 'UPDATE pg_system_conf SET pg_conf_value="[' .
                        sprintf( '%02d,%02d', $torg, $torg ) .
                        ']" WHERE pg_conf_code="start_hours";' );
            $dbh->do( 'UPDATE pg_system_conf SET pg_conf_value="[' .
                        sprintf( '%02d,%02d', $torg+24, $torg+24 ) .
                        ']" WHERE pg_conf_code="end_hours";' );
        }
        # adminレコード登録
        $schema->resultset('PgStaff')->create({
            'name'      => 'admin',
            'account'   => 'admin',
            'passwd'    => crypt( $adpw, random_string( 'cccc' ) ),
            'role'      => 'ADMIN',
        });
        $dbh->disconnect;

        # config設定
        $c->config->{'Model::ConkanDB'}->{schema_class} = 'conkan::Schema';
        $c->config->{'Model::ConkanDB'}->{connect_info} =
            {
                dsn      => $dsn,
                user     => $dbus,
                password => $dbpw,
                AutoCommit => q{1},
                mysql_enable_utf8 => 1,
                on_connect_do => ["SET NAMES utf8", "SET time_zone='+09:00'", ],
            };

        # conkan.ymlを書き出す(必要な物だけ)
        my $conkan_yml_f = $c->config->{home} . '/conkan.yml';
        my $conkan_yml = {
            'name' => 'conkan',
            'inited' => 1,
            'disable_component_resolution_regex_fallback' => 1,
            'enable_catalyst_header' => 1,
            'default_model' => 'conkanDB',
            'default_view'  => 'TT',
            'time_origin' => $torg,
            'addstaff' => {
                'type' => $adrt,
            },
            'Model::ConkanDB' => $c->config->{'Model::ConkanDB'},
            'Plugin::Authentication' => $c->config->{'Plugin::Authentication'},
        };
        my $ymlwk = $conkan_yml->{'Model::ConkanDB'}->{'connect_info'};
        $ymlwk->{'dsn'} = $dsn;
        $ymlwk->{'user'} = $dbus;
        $ymlwk->{'password'} = $dbpw;
        if ( $adrt eq 'cybozu' ) {
            $conkan_yml->{'addstaff'}->{'group'} = $cygr;
            $ymlwk = $conkan_yml->{'Plugin::Authentication'}->{'oauth'}
                    ->{'credential'}->{'providers'}->{'api.cybozulive.com'};
            $ymlwk->{'consumer_key'} = $oakey;
            $ymlwk->{'consumer_secret'} = $oasec;
        }
        YAML::DumpFile( $conkan_yml_f, $conkan_yml );
        # サーバ再起動
        # これにより、$c->config->{inited} が設定される
        unless ( 0 == system('/usr/bin/pkill -HUP starman') ) {
            $c->error('conkan再起動失敗 at ' . scalar localtime );
        }
    } catch {
        my $e = shift;
        $c->log->error($e);
        if ( scalar @{ $c->error } ) {
            foreach my $err (@{ $c->error }) {
                $c->log->error($err);
            }
            $c->clear_errors();
        }
        $c->error('conkan初期化失敗 at ' . scalar localtime );
    };
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;
    # エラー発生時のみ実施
    if ( scalar @{ $c->error } ) {
        $c->response->status(500);
        $c->stash->{errors}   = $c->error;
        $c->stash->{template} = 'error.tt';
        $c->clear_errors();
    }
}

=head1 AUTHOR

Stadio REM

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
