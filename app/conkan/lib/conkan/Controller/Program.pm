package conkan::Controller::Program;
use Moose;
use utf8;
use YAML;
use String::Random qw/ random_string /;
use Try::Tiny;
use DateTime;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

conkan::Controller::Program - Catalyst Controller

=head1 DESCRIPTION

企画管理

=head1 METHODS

=cut


=head2 index

企画一覧にgo
=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->go('program_list');
}

=head2 program
-----------------------------------------------------------------------------
企画管理 program_base  : Chainの起点

=cut

sub program_base : Chained('') : PathPart('program') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

=head2 program/list 

企画管理 program_list  : 企画一覧

=cut

sub program_list : Chained('program_base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;

    my $pgmlist =
        [ $c->model('ConkanDB::PgProgram')->search( { },
            {
                'prefetch' => [ 'pgid', 'staffid' ],
                'order_by' => { '-asc' => 'me.pgid' },
            } )
        ];
    my $prglist =
        [ $c->model('ConkanDB::PgProgress')->search( { },
            {
                'group_by' => [ 'pgid' ],
                'select'   => [ 'pgid', { MAX => 'repDateTime'} ], 
                'as'       => [ 'pgid', 'lastprg' ],
                'order_by' => { '-asc' => 'pgid' },
            } )
        ];
    my $list = {};

    foreach my $pgm ( @$pgmlist ) {
        my $pgid = $pgm->pgid();
        $list->{$pgid} = { 'name'  => $pgm->pgid->name(),
                           'staff' => $pgm->staffid->name(),
                           'status' => $pgm->status(),
                         };
    }
    foreach my $prg ( @$prglist ) {
        my $pgid = $prg->pgid();
        $list->{$pgid}->{'repdatetime'} = $prg->get_column('lastprg');
    }
    $c->stash->{'list'} = $list;
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
