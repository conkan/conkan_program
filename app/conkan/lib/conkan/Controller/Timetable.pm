package conkan::Controller::Timetable;
use Moose;
use JSON;
use String::Random qw/ random_string /;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

conkan::Controller::Timetable - Catalyst Controller

=head1 DESCRIPTION

Timetableを表示する Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $uid = $c->user->get('staffid');
    # 未設定企画一覧
    my $pgmlist =
        [ $c->model('ConkanDB::PgProgram')->search(
            [
                { 'roomid' }, { 'date1' }, { 'stime1' }, { 'etime1' }
            ],
            {
                'prefetch' => [ 'regpgid' ],
                'order_by' => { '-asc' => [ 'me.regpgid', 'me.subno'] },
            } )
        ];
    my @list = ();
    foreach my $pgm ( @$pgmlist ) {
        my $regpgid = 
        push @list, {
            'pgid'          => $pgm->pgid(),
            'regpgid'       => $pgm->regpgid->regpgid(),
            'subno'         => $pgm->subno(),
            'sname'         => $pgm->sname() || $pgm->regpgid->name(),
        };
    }
    $c->stash->{'Program'} = \@list;
    # 設定フォーム選択肢
    my $conf  = {};
    my $M = $c->model('ConkanDB::PgSystemConf');
    my $time_origin = $c->config->{time_origin};
    $conf->{'dates'}   = [
          map +{ 'id' => $_ , 'val' => $_ },
            @{from_json( $M->find('dates')->pg_conf_value() )}
        ];
    $conf->{'s_hours'} = [
          map +{ 'id' => sprintf('%02d', $_), 'val' => sprintf('%02d', $_) },
            ( $time_origin .. $time_origin+23 )
        ];
    $conf->{'s_mins'} = [
          map +{ 'id' => sprintf('%02d', $_*5),
                 'val' => sprintf('%02d', $_*5) },
            ( 0 .. 11 )
        ];
    $conf->{'e_hours'} = [
          map +{ 'id' => sprintf('%02d', $_), 'val' => sprintf('%02d', $_) },
            ( $time_origin .. $time_origin+23 )
        ];
    $conf->{'e_mins'} = [
          map +{ 'id' => sprintf('%02d', $_*5),
                 'val' => sprintf('%02d', $_*5) },
            ( 0 .. 11 )
        ];
    $conf->{'status'}  = [
          map +{ 'id' => $_, 'val' => $_ },
            @{from_json( $M->find('pg_status_vals')->pg_conf_value() )}
        ];
    $conf->{'nos'}     = [
          map +{ 'id' => $_, 'val' => $_ }, qw/ 0 1 2 3 4 /
        ];
    $conf->{'roomlist'}  = [
          map +{ 'id'  => $_->roomid(),
                 'val' => $_->name() . '(' . $_->roomno() . ')' },
            $c->model('ConkanDB::PgRoom')->all()
        ];
    $c->stash->{'conf'}  = $conf;
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
