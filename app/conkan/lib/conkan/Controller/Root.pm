package conkan::Controller::Root;
use strict;
use warnings;
use utf8;
use Moose;
use namespace::autoclean;
use DBI;
use Try::Tiny;
use String::Random qw/ random_string /;

use Data::Dumper;
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

    $c->log->debug('>>>>アクション内部パス:[' . $c->action->reverse . ']' );
    # 初期化済判断
    unless (exists($c->config->{inited})) {
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
    # login->login ループ回避
    if ( $c->action->reverse eq 'login' ) {
        return 1;
    }
    # 強制login処理
    unless ( $c->user_exists ) {
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

    $c->response->redirect( '/mypage' );
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
    $c->response->body( '<H1>Page not found</H1>(開発中)' );
    $c->response->status(404);
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

    if ( ( $c->session->{role} ne 'initial' ) && ( $c->user_exists ) ) {
        return;
    }
    # session->{init_role} は引き継ぐ
    # session->{init_role} が空の時は、req->bodyparam->{init_role}を設定
    # (bodyparam->{init_role}は、initialprocessでのみ設定)
    my $init_role = $c->session->{init_role} ||
                    $c->request->body_params->{init_role};
    $c->delete_session('login');
    $c->session->{init_role} = $init_role;
    if ( !$realm ) {
        return;
    }
    elsif ( $realm eq 'passwd' ) {
        if ( $c->authenticate( { account => $account, passwd => $passwd },
                               $realm ) ) {
            my @r = $c->model('ConkanDB::PgStaff')->search({account=>{'!='=>'admin'}});
            unless ( scalar @r ) {
                $c->session->{init_role} = 'addroot';
            }
            else {
                $c->session->{init_role} = undef;
            }
            $c->response->redirect( '/mypage' );
        } else {
            $c->stash->{errmsg} = '認証失敗 再度loginしてください';
        }
    }
    else {
        $c->error('Fatal access at '. scalar localtime );
    }
}

=head2 logout

logout

=cut

sub logout :Local {
    my ( $self, $c ) = @_;
    $c->logout;
    $c->response->redirect( '/login' );
}

=head2 initialize

Initialize

=cut

sub initialize :Private {
    my ( $self, $c ) = @_;
    # 初期化セッション開始
    $c->delete_session('initialize');
    $c->session->{role} = 'initial';
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

    if ( $c->session->{role} ne 'initial' ) {
        $c->response->status(405);
        $c->response->body( 'Cannot Initialize (Direct Access)' );
        return;
    }

    my $adpw = $c->request->body_params->{adpw};
    my $dbnm = $c->request->body_params->{dbnm};
    my $dbsv = $c->request->body_params->{dbsv};
    my $dbus = $c->request->body_params->{dbus};
    my $dbpw = $c->request->body_params->{dbpw};
    my $adrt = $c->request->body_params->{addroot};
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
                  $adrt, $oakey, $oasec, $cygr ],
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
        $schema->deploy( { add_drop_table => 1, } );

        # 規定値一括登録
        $dbh->do( 'SET NAMES utf8' );

        # pg_system_conf と pg_regist_conf を登録
        my $system_conf_f = $c->config->{home} . '/../initializer/system_conf.csv';
        my $regist_conf_f = $c->config->{home} . '/../initializer/regist_conf.csv';
        $dbh->do( "LOAD DATA LOCAL INFILE '$system_conf_f' " .
                    'INTO TABLE pg_system_conf ' .
                    "FIELDS TERMINATED BY ',' ENCLOSED BY '\"';" );
        $dbh->do( 'SET FOREIGN_KEY_CHECKS=0;' );
        $dbh->do( "LOAD DATA LOCAL INFILE '$regist_conf_f' " .
                    'INTO TABLE pg_regist_conf ' .
                    "FIELDS TERMINATED BY ',' ENCLOSED BY '\"';" );
        $dbh->do( 'SET FOREIGN_KEY_CHECKS=1;' );
        # adminレコード登録
        $schema->resultset('PgStaff')->create({
            'name'      => 'admin',
            'account'   => 'admin',
            'passwd'    => crypt( $adpw, random_string( 'cccc' ) ),
            'role'      => 'ROOT',
        });
        $dbh->disconnect;

        # config設定
        $c->config->{'Model::ConkanDB'}->{schema_class} = 'conkan::Schema';
        $c->config->{'Model::ConkanDB'}->{connect_info} =
            {
                dsn      => $dsn,
                user     => $dbus,
                password => $dbpw,
                mysql_enable_utf8 => 1,
                on_connect_do => ["SET NAMES utf8"],
            };

        # conkan.ymlを書き出す(必要な物だけ)
        my $conkan_yml_f = $c->config->{home} . '/conkan.yml';
        my $conkan_yml = {
            'name' => 'conkan',
            'inited' => 1,
            'addroot' => {
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
            $conkan_yml->{'addroot'}->{'group'} = $cygr;
            $ymlwk = $conkan_yml->{'Plugin::Authentication'}->{'oauth'}
                    ->{'credential'}->{'providers'}->{'api.cybozulive.com'};
            $ymlwk->{'consumer_key'} = $oakey;
            $ymlwk->{'consumer_secret'} = $oasec;
        }
        YAML::DumpFile( $conkan_yml_f, $conkan_yml );
        # サーバ再起動
        # これにより、$c->config->{inited} が設定される
        unless ( 0 == system('/usr/bin/pkill starman') ) {
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
