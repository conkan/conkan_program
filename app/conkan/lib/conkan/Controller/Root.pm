package conkan::Controller::Root;
use strict;
use warnings;
use utf8;
use Moose;
use namespace::autoclean;
use DBI;
use Try::Tiny;

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

初期設定のみ組み込み。それ以外は別のコントローラ

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->go( '/initialize' ) unless (exists($c->config->{inited}));

    # Hello World
    $c->response->body( $c->welcome_message );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 initialize

Initialize

=cut

sub initialize :Private {
    my ( $self, $c ) = @_;
    # 初期化セッション開始
    $c->session->{roll} = 'initial';
}

=head2 initialprocess

Initial process

=cut

sub initialprocess :Path {
    my ( $self, $c ) = @_;

    if (exists($c->config->{inited})) {
        $c->response->body( 'Already Initialized' );
        return;
    }

    if ( $c->session->{roll} ne 'initial' ) {
        $c->response->body( 'Cannot Initialize (Direct Access)' );
        return;
    }

    my $adpw = $c->request->body_params->{adpw};
    my $dbnm = $c->request->body_params->{dbnm};
    my $dbsv = $c->request->body_params->{dbsv};
    my $dbus = $c->request->body_params->{dbus};
    my $dbpw = $c->request->body_params->{dbpw};
    my $oakey= $c->request->body_params->{oakey};
    my $oasec= $c->request->body_params->{oasec};
    my $dsn  = "dbi:mysql:$dbnm:$dbsv";

    # 接続可否確認
    # 初期化処理
    my $dbh = DBI->connect( $dsn, $dbus, $dbpw, { mysql_enable_utf8 => 1, } );
    unless ( $dbh ) {
        $c->stash->{template} = 'wrongParam.tt';
        return;
    }
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
        $dbh->disconnect;

        # config設定
        $c->config->{inited} =1;
        $c->config->{'Model::ConkanDB'}->{schema_class} = 'conkan::Schema';
        $c->config->{'Model::ConkanDB'}->{connect_info} =
            {
                dsn      => $dsn,
                user     => $dbus,
                password => $dbpw,
                mysql_enable_utf8 => 1,
                on_connect_do => ["SET NAMES utf8"],
            };

        # 初期登録専用パスワード
        $c->session->{adpw} = $adpw;
        # conkan.ymlを書き出す(必要な物だけ)
        my $conkan_yml_f = $c->config->{home} . '/conkan.yml';
        my $conkan_yml = {
            'name' => 'conkan',
            'inited' => 1,
            'Model::ConkanDB' => $c->config->{'Model::ConkanDB'},
            'Plugin::Authentication' => $c->config->{'Plugin::Authentication'},
        };
        my $ymlwk = $conkan_yml->{'Model::ConkanDB'}->{'connect_info'};
        $ymlwk->{'dsn'} = $dsn;
        $ymlwk->{'user'} = $dbus;
        $ymlwk->{'password'} = $dbpw;
        $ymlwk = $conkan_yml->{'Plugin::Authentication'}->{'oauth'}->{'credential'}->{'providers'}->{'api.cybozulive.com'};
        $ymlwk->{'consumer_key'} = $oakey;
        $ymlwk->{'consumer_secret'} = $oasec;
        YAML::DumpFile( $conkan_yml_f, $conkan_yml );
        # サーバ再起動
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
