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
    # タイムテーブルガントチャート表示用固定値
    my $M = $c->model('ConkanDB::PgSystemConf');
    my $syscon = {
        'dates'       => [ @{from_json( $M->find('dates')->pg_conf_value() )}],
        'start_hours' => [ @{from_json( $M->find('start_hours')->pg_conf_value() )}],
        'end_hours'   => [ @{from_json( $M->find('end_hours')->pg_conf_value() )}],
        'gantt_header'      => $M->find('gantt_header')->pg_conf_value(),
        'gantt_back_grid'   => $M->find('gantt_back_grid')->pg_conf_value(),
        'gantt_colmnum'     => $M->find('gantt_colmnum')->pg_conf_value(),
        'shift_hour'  => $c->config->{time_origin},
    };
    $c->stash->{'syscon'} = $syscon;
    # 未設定企画リスト
    my $unsetPgmlist =
        [ $c->model('ConkanDB::PgProgram')->search(
            [
                { 'roomid' => \'IS NULL' },
                { 'date1'  => \'IS NULL' },
                { 'stime1' => \'IS NULL' },
                { 'etime1' => \'IS NULL' }
            ],
            {
                'prefetch' => [ 'regpgid' ],
                'order_by' => { '-asc' => [ 'me.regpgid', 'me.subno'] },
            } )
        ];
    my @unsetlist = ();
    foreach my $pgm ( @$unsetPgmlist ) {
        push @unsetlist, {
            'regpgid'       => $pgm->regpgid->regpgid(),
            'pgid'          => $pgm->pgid(),
            'subno'         => $pgm->subno(),
            'sname'         => $pgm->sname() || $pgm->regpgid->name(),
        };
    }
    $c->stash->{'unsetProgram'} = \@unsetlist;
    # 部屋別企画リスト
    my $roomPgmlist =
        [ $c->model('ConkanDB::PgProgram')->search(
            { 'me.roomid' => \'IS NOT NULL',
              'date1'  => \'IS NOT NULL', 
              'stime1' => \'IS NOT NULL', 
              'etime1' => \'IS NOT NULL' 
            },
            {
                'prefetch' => [ 'roomid', 'regpgid' ],
                'order_by' => { '-asc' => [ 'me.roomid' ] },
            } )
        ];
    my @roomlist = ();
    foreach my $pgm ( @$roomPgmlist ) {
        my $doperiod = __PACKAGE__->createPeriod( $pgm );
        push @roomlist, {
            'roomid'        => $pgm->roomid->roomid(),
            'roomname'      => $pgm->roomid->name(),
            'roomno'        => $pgm->roomid->roomno(),
            'regpgid'       => $pgm->regpgid->regpgid(),
            'pgid'          => $pgm->pgid(),
            'subno'         => $pgm->subno(),
            'sname'         => $pgm->sname() || $pgm->regpgid->name(),
            'doperiod'      => $doperiod,
        };
    }
    $c->stash->{'roomProgram'} = \@roomlist;
    # 出演者別企画リスト
    my $castPgmlist =
        [ $c->model('ConkanDB::PgProgram')->search(
            { 'me.roomid' => \'IS NOT NULL',
              'date1'  => \'IS NOT NULL', 
              'stime1' => \'IS NOT NULL', 
              'etime1' => \'IS NOT NULL' 
            },
            {
                'prefetch' => [ 'pg_casts', 'regpgid', 'roomid' ],
                'order_by' => { '-asc' => [ 'pg_casts.castid' ] },
            } )
        ];
    my @castlist = ();
    foreach my $pgm ( @$castPgmlist ) {
        my $doperiod = __PACKAGE__->createPeriod( $pgm );

        foreach my $cast ( $pgm->pg_casts->all() ) {
            push @castlist, {
                'castid'        => $cast->castid->castid(),
                'castname'      => $cast->name() || $cast->castid->name(),
                'regpgid'       => $pgm->regpgid->regpgid(),
                'pgid'          => $pgm->pgid(),
                'subno'         => $pgm->subno(),
                'sname'         => $pgm->sname() || $pgm->regpgid->name(),
                'roomno'        => $pgm->roomid->roomno(),
                'roomname'      => $pgm->roomid->name(),
                'doperiod'      => $doperiod,
            };
        }
    }
    $c->stash->{'castProgram'} = \@castlist;
    # 設定フォーム選択肢
    $c->stash->{'conf'}  = $c->forward('/program/_setSysConf' );
}

=head2 createPeriod

企画実施日時を変換する

戻り値 変換した文字列

=cut
        
sub createPeriod {
    my ( $self,
         $pgm,  # DBレコードオブジェクト
       ) = @_;
    my $ret;

    my @date  = split('T', $pgm->date1());
    my @stime = split(':', $pgm->stime1());
    my @etime = split(':', $pgm->etime1());
    $ret = sprintf('%s %02d:%02d-%02d:%02d',
                    $date[0], $stime[0], $stime[1], $etime[0], $etime[1] );
    if ( $pgm->date2() ) {
        @date  = split('T', $pgm->date2());
        @stime = split(':', $pgm->stime2());
        @etime = split(':', $pgm->etime2());
        $ret .= sprintf(' %s %02d:%02d-%02d:%02d',
                        $date[0], $stime[0], $stime[1], $etime[0], $etime[1] );
    }
    return $ret;
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
