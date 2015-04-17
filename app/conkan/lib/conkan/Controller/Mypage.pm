package conkan::Controller::Mypage;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

conkan::Controller::Mypage - Catalyst Controller

=head1 DESCRIPTION

MyPageを表示する Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

}

=head2 profile

=cut

sub profile :Local {
    my ( $self, $c ) = @_;

    $c->stash->{name}  = $c->flash->{name};
    $c->stash->{email} = $c->flash->{email};
    $c->stash->{cyid}  = $c->flash->{cyid};
    $c->stash->{role}  = $c->flash->{role};

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
