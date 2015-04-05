package conkan::Controller::Root;
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

=head2 initialsetup

Initial setup

=cut

sub initialsetup :Path {
    my ( $self, $c ) = @_;

    $c->response->body( "Already Initialized" )
        if (exists($c->config->{inited}));

    # パラメータをconfigに設定する
    # $adpw -> conkan->config( adpw )
    # $dbsv $dbus $dbpw $dbnm
    #   -> conkan::Model::ConkanDB->config( connect_infoa )

    # deployだとどうしても日本語がうまくいかないので、mysqlを叩く

    # conkan_init.sql の DB名を $dbnm に置き換えて、
    # /usr/bin/mysql -u $dbus -p $dbpw --host=$dbsv < app/initializer/conkan_init.sql

    # deploy,
    # ↓でいいはずなんだがなあ
    # my $schema = conkan::Schema->connect(
    #     'dbi:mysql:conkan:192.168.24.22', 'conkan', 'conkan',
    #     {
    #         mysql_enable_utf8 => 1,
    #         on_connect_do => ['SET NAMES utf8'],
    #     }
    # );
    # $schema->deploy;

    # $c->config->{inited} を設定して、
    # 書き出す
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
