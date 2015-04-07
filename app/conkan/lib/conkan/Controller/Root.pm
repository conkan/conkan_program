package conkan::Controller::Root;
use strict;
use warnings;
use utf8;
use Moose;
use namespace::autoclean;

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
    # Do Nothing;
}

=head2 initialprocess

Initial process

=cut

sub initialprocess :Path {
    my ( $self, $c ) = @_;

    $c->response->body( "Already Initialized" )
        if (exists($c->config->{inited}));

    my $adpw = $c->request->body_params->{adpw};
    my $dbnm = $c->request->body_params->{dbnm};
    my $dbsv = $c->request->body_params->{dbsv};
    my $dbus = $c->request->body_params->{dbus};
    my $dbpw = $c->request->body_params->{dbpw};
    my $dsn  = "dbi:mysql:$dbnm:$dbsv";

    # DBスキーマをdeploy
    my $schema = conkan::Schema->connect(
        $dsn, $dbus, $dbpw,
        {
            mysql_enable_utf8 => 1,
            on_connect_do => ["SET NAMES utf8"],
        }
    );
    $schema->deploy( { add_drop_table => 1, } );

    # 規定値一括登録
    my $dbh = DBI->connect( $dsn, $dbus, $dbpw, { mysql_enable_utf8 => 1,} );
    $dbh->do( 'SET NAMES utf8' );

    # pg_system_conf と pg_regist_info を登録
    my $system_conf_f = $c->config->{home} . '/../initializer/system_conf.csv';
    my $regist_info_f = $c->config->{home} . '/../initializer/regist_info.csv';
    $dbh->do( "LOAD DATA LOCAL INFILE '$system_conf_f' " .
                "INTO TABLE pg_system_conf " .
                "FIELDS TERMINATED BY ',' ENCLOSED BY '\"';" );
    $dbh->do( "LOAD DATA LOCAL INFILE '$regist_info_f' " .
                "INTO TABLE pg_regist_info" .
                "FIELDS TERMINATED BY ',' ENCLOSED BY '\"';" );

    # config設定
    $c->config->{adpw} = $adpw;
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

    # conkan.ymlを書き出す(必要な物だけ)
    # 
    # もしかしたらサーバ再起動が必要かも・・・pkill starman
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Stadio REM

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
