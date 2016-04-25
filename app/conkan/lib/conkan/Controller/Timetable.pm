package conkan::Controller::Timetable;
use Moose;
use utf8;
use JSON;
use String::Random qw/ random_string /;
use Try::Tiny;
use namespace::autoclean;
use Data::Dumper;
use POSIX qw/ strftime /;

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
        'gantt_header'      => $M->find('gantt_header')->pg_conf_value(),
        'gantt_back_grid'   => $M->find('gantt_back_grid')->pg_conf_value(),
        'gantt_colmnum'     => $M->find('gantt_colmnum')->pg_conf_value(),
        'gantt_scale_str'   => $M->find('gantt_scale_str')->pg_conf_value(),
        'gantt_color_str'   => $M->find('gantt_color_str')->pg_conf_value(),
        'shift_hour'        => $c->config->{time_origin},
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
        my $doperiod = $c->forward('/timetable/createPeriod', [ $pgm, ], );
        push @roomlist, {
            'roomid'        => $pgm->roomid->roomid(),
            'roomname'      => $pgm->roomid->name(),
            'roomno'        => $pgm->roomid->roomno(),
            'regpgid'       => $pgm->regpgid->regpgid(),
            'pgid'          => $pgm->pgid(),
            'subno'         => $pgm->subno(),
            'sname'         => $pgm->sname() || $pgm->regpgid->name(),
            'doperiod'      => $doperiod,
            'status'        => $pgm->status(),
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
        my $doperiod = $c->forward('/timetable/createPeriod', [ $pgm, ], );

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
                'status'        => $pgm->status(),
            };
        }
    }
    $c->stash->{'castProgram'} = \@castlist;
}

=head2 createPeriod

企画実施日時を変換する

戻り値 変換した文字列

=cut
        
sub createPeriod :Private {
    my ( $self, $c,
         $pgm,  # DBレコードオブジェクト
       ) = @_;
    my $ret;

    my @date  = split('T', $pgm->date1());
    $date[0] =~ s[-][/]g;
    $c->forward('/program/_trnSEtime', [ $pgm, ], );
    $ret = sprintf('%s %02d:%02d-%02d:%02d',
                    $date[0], $pgm->{'shour1'}, $pgm->{'smin1'},
                              $pgm->{'ehour1'}, $pgm->{'emin1'} );
    if ( $pgm->date2() ) {
        @date  = split('T', $pgm->date2());
        $date[0] =~ s[-][/]g;
        $ret .= sprintf(' %s %02d:%02d-%02d:%02d',
                    $date[0], $pgm->{'shour2'}, $pgm->{'smin2'},
                              $pgm->{'ehour2'}, $pgm->{'emin2'} );
    }
    return $ret;
}

=head2 csvdownload
タイムテーブル csvdownload : CSVダウンロード

=cut

sub csvdownload :Local {
    my ( $self, $c ) = @_;

$c->log->debug('>>> ' . 'csvdownload' );

    my $rowconf = $c->model('ConkanDB::PgSystemConf')->find('pg_active_status');
    my $pact_status = [
        map +{ 'status' => $_ }, @{from_json( $rowconf->pg_conf_value() )}
    ];
    # 実施日時、開始時刻、終了時刻、実施場所が設定済
    # 実行ステータスが有効
    my $rows =
        [ $c->model('ConkanDB::PgProgram')->search(
            { 'me.roomid' => \'IS NOT NULL',
              'date1'  => \'IS NOT NULL', 
              'stime1' => \'IS NOT NULL', 
              'etime1' => \'IS NOT NULL',
              -nest    => $pact_status,
            },
            {
                'prefetch' => [ 'regpgid', 'roomid' ],
                'order_by' => { '-asc' => [ 'me.regpgid' ] },
            } )
        ];

    my @data;
    foreach my $row ( @$rows ) {
        # 実施日付は YYYY/MM/DD、開始終了時刻は HH:MM (いずれも0サフィックス)
        my @dates  = undef;
        my @stms = undef;
        my @etms = undef;
        my @date  = split('T', $row->date1());
        $date[0] =~ s[-][/]g;
        @date = split('/', $date[0]);
        $c->forward('/program/_trnSEtime', [ $row, ], );
        $dates[0] = sprintf('%04d/%02d/%02d', @date);
        $stms[0] = sprintf('%02d:%02d', $row->{'shour1'}, $row->{'smin1'});
        $etms[0] = sprintf('%02d:%02d', $row->{'ehour1'}, $row->{'emin1'});
        if ( $row->date2() ) {
            @date  = split('T', $row->date2());
            $date[0] =~ s[-][/]g;
            @date = split('/', $date[0]);
            $dates[1] = sprintf('%04d/%02d/%02d', @date);
            $stms[1] = sprintf('%02d:%02d', $row->{'shour2'}, $row->{'smin2'});
            $etms[1] = sprintf('%02d:%02d', $row->{'ehour2'}, $row->{'emin2'});
        }
        push ( @data, [
            $row->regpgid->regpgid(),       # 企画ID,
            $row->regpgid->name(),          # 企画名称,
            $row->status(),                 # 実行ステータス,
            $row->memo(),                   # 実行ステータス補足,
            $row->roomid->roomno(),         # 部屋番号,
            $row->roomid->name(),           # 実施場所,
            $dates[0], $stms[0], $etms[0],  # 実施日付1,開始時刻1,終了時刻1,
            $dates[1], $stms[1], $etms[1],  # 実施日付2,開始時刻2,終了時刻2,
        ]);
    }

$c->log->debug('>>> ' . 'rowdata : ' . Dumper( \@data ) );

    $c->stash->{'csv'} = \@data;
    $c->response->header( 'Content-Disposition' =>
        'attachment; filename=' .
            strftime("%Y%m%d%H%M%S", localtime()) . '_timetable.csv' );

    $c->forward('conkan::View::Download::CSV');
}

=head2 timetable
-----------------------------------------------------------------------------
タイムテーブル timetable_base  : Chainの起点

=cut

sub timetable_base : Chained('') : PathPart('timetable') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

=head2 timetable/detail/*
タイムテーブル timetable_detail  : 個別詳細へジャンプ

=cut

sub timetable_detail : Chained('timetable_base') :PathPart('detail') :Args(1) {
    my ( $self, $c, $pgid ) = @_;

    $c->stash->{'self_li_id'} = 'timetable';
    $c->go('/program/program_detail/', [ $pgid ], [] );
}

=head2 timetable/*
タイムテーブル timetable_get  : 個別詳細情報返却/更新

=cut

sub timetable_get : Chained('timetable_base') :PathPart('') :Args(1) {
    my ( $self, $c, $pgid ) = @_;

    try {
        my $row =
            $c->model('ConkanDB::PgProgram')->find($pgid, 
                            {
                                'prefetch' => [ 'regpgid', 'roomid' ],
                            },
                        );
        my $regpgid = $row->regpgid->regpgid();
        if ( $c->request->method eq 'GET' ) {
            # 更新表示
            $c->stash->{'regpgid'}  = $regpgid;
            $c->stash->{'subno'}    = $row->subno();
            $c->stash->{'pgid'}     = $row->pgid();
            $c->stash->{'sname'}    = $row->sname();
            $c->stash->{'name'}     = $row->regpgid->name() if ( $regpgid );
            $c->forward('/program/_trnSEtime', [ $row, ], );
            if ( $row->date1() ) {
                my @date  = split('T', $row->date1());
                $date[0] =~ s[-][/]g;
                $c->stash->{'date1'}    = $date[0];
                $c->stash->{'shour1'}   = "$row->{'shour1'}";
                $c->stash->{'smin1'}    = "$row->{'smin1'}";
                $c->stash->{'ehour1'}   = "$row->{'ehour1'}";
                $c->stash->{'emin1'}    = "$row->{'emin1'}";
            }
            if ( $row->date2() ) {
                my @date  = split('T', $row->date2());
                $date[0] =~ s[-][/]g;
                $c->stash->{'date2'}    = $date[0];
                $c->stash->{'shour2'}   = "$row->{'shour2'}";
                $c->stash->{'smin2'}    = "$row->{'smin2'}";
                $c->stash->{'ehour2'}   = "$row->{'ehour2'}";
                $c->stash->{'emin2'}    = "$row->{'emin2'}";
            }
            $c->stash->{'status'}   = $row->status();
            $c->stash->{'layerno'}  = $row->layerno();
            $c->stash->{'staffid'}  = $row->staffid->staffid()
                if ( $row->staffid() );
            $c->stash->{'roomid'}   = $row->roomid->roomid()
                if ( $row->roomid() );
            $c->stash->{'memo'}     = $row->memo();
            $c->stash->{'progressprp'} = $row->progressprp();
            if (  ( $c->user->get('role') eq 'ROOT' )
               || ( $c->user->get('role') eq 'PG'   ) ) {
               # システム管理者/企画管理者の場合、更新可能
                $c->session->{'updtic'} = time;
                $row->update( {
                    'updateflg' => $c->sessionid . $c->session->{'updtic'}
                } );
            }
        }
        else {
            # 更新実施
            if ( $row->updateflg eq 
                    +( $c->sessionid . $c->session->{'updtic'}) ) {
                my $items = [ qw/
                                sname staffid status memo
                                date1 stime1 etime1 date2 stime2 etime2
                                roomid layerno progressprp
                            / ];
                my $value = $c->forward('/program/_trnReq2Hash', [ $items ] );
                $c->forward('/program/_autoProgress', [ $regpgid, $items, $row, $value ] );
                $row->update( $value ); 
                $c->stash->{'status'} = 'update';
            }
            else {
                $c->stash->{'status'} = 'fail';
            }
        }
        $c->component('View::JSON')->{expose_stash} = undef;
$c->log->debug('>>> program_progressget expose_stash:' . Dumper($c->component('View::JSON')->{expose_stash}));
    } catch {
        my $e = shift;
        $c->log->error('timetable_get error ' . localtime() .
            ' dbexp : ' . Dumper($e) );
    };
    $c->forward('conkan::View::JSON');
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
