package conkan::Controller::Addroot;
use Moose;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

conkan::Controller::Addroot - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # 初期設定で選択したスタッフ登録方法に従ってジャンプ
    $c->response->redirect( 'addroot/' . $c->config->{addroot}->{type} );
}

=head2 plain

個別入力による登録

=cut

sub plain :Local {
    my ( $self, $c ) = @_;
}

=head2 cybozu

CybouzuLive情報流用登録

=cut

sub cybozu :Local {
    my ( $self, $c ) = @_;

    # サイボウズOAuth認証開始
    $Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
    $Carp::Verbose = 1;
    my $auth = $c->authenticate( { provider => 'api.cybozulive.com' },
                                 'oauth' );
    if ( $auth ) {
        $c->response->body( '<pre>' .  Dumper($c->user) . '</pre>' );
    }
}

=head2 cybozuauth

サイボウズOAuth認証機構から呼び出されるアクション(コールバック)

=cut

sub cybozuauth :Local {
    my ( $self, $c ) = @_;

}

=encoding utf8

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
