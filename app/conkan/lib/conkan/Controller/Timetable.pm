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
    # タイムテーブルガントチャート表示用固定値
    my $M = $c->model('ConkanDB::PgSystemConf');
    try {
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
            my $pgname = $pgm->sname() || $pgm->regpgid->name();
$c->log->debug('>>>> pgname: [' . $pgname . ']') if ( $pgname =~ /[\n\r]/ );
            $pgname =~ s/[\n\r]//g;

            push @unsetlist, {
                'regpgid'       => $pgm->regpgid->regpgid(),
                'pgid'          => $pgm->pgid(),
                'subno'         => $pgm->subno(),
                'sname'         => $pgname,
                'status'        => $pgm->status(),
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
            my $pgname = $pgm->sname() || $pgm->regpgid->name();
            $pgname =~ s/\n//g;
            push @roomlist, {
                'roomid'        => $pgm->roomid->roomid(),
                'roomname'      => $pgm->roomid->name(),
                'roomno'        => $pgm->roomid->roomno(),
                'regpgid'       => $pgm->regpgid->regpgid(),
                'pgid'          => $pgm->pgid(),
                'subno'         => $pgm->subno(),
                'sname'         => $pgname,
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
            my $pgname = $pgm->sname() || $pgm->regpgid->name();
            $pgname =~ s/\n//g;
            foreach my $cast ( $pgm->pg_casts->all() ) {
                push @castlist, {
                    'regno'         => $cast->castid->regno(),
                    'castname'      => $cast->name() || $cast->castid->name(),
                    'regpgid'       => $pgm->regpgid->regpgid(),
                    'pgid'          => $pgm->pgid(),
                    'subno'         => $pgm->subno(),
                    'sname'         => $pgname,
                    'roomno'        => $pgm->roomid->roomno(),
                    'roomname'      => $pgm->roomid->name(),
                    'doperiod'      => $doperiod,
                    'status'        => $pgm->status(),
                };
            }
        }
        $c->stash->{'castProgram'} = \@castlist;
    } catch {
        $c->detach( '_dberror', [ shift ] );
    };
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

    my $rowconf = $c->model('ConkanDB::PgSystemConf')->find('pg_active_status');
    # 実施日時、開始時刻、終了時刻、実施場所が設定済
    # & 有効な実行ステータスで抽出
    my $rows =
        [ $c->model('ConkanDB::PgProgram')->search(
            { 'me.roomid' => \'IS NOT NULL',
              'date1'  => \'IS NOT NULL', 
              'stime1' => \'IS NOT NULL', 
              'etime1' => \'IS NOT NULL',
              'status' => from_json( $rowconf->pg_conf_value() ),
            },
            {
                'prefetch' => [ 'regpgid', 'roomid' ],
                'order_by' => { '-asc' => [ 'me.regpgid', 'me.subno' ] },
            } )
        ];

    my @data = (
        [
            '企画ID',
            '企画名',
            '実行ステータス',
            '実行ステータス補足',
            '部屋番号',
            '実施場所',
            '実施日付1',
            '開始時刻1',
            '終了時刻1',
            '実施日付2',
            '開始時刻2',
            '終了時刻2',
        ]
    );
    foreach my $row ( @$rows ) {
        # 実施日付は YYYY/MM/DD、開始終了時刻は HH:MM (いずれも0サフィックス)
        my $datmHash =  $c->forward('/program/_trnDateTime4csv', [ $row, ], );
        my $pgname = $row->sname() || $row->regpgid->name();
        $pgname =~ s/\n//g;
        push ( @data, [
            $row->regpgid->regpgid(),   # 企画ID,
            $pgname,                    # 企画名,
            $row->status(),             # 実行ステータス,
            $row->memo(),               # 実行ステータス補足,
            $row->roomid->roomno(),     # 部屋番号,
            $row->roomid->name(),       # 実施場所,
            $datmHash->{'dates'}->[0],  # 実施日付1,
            $datmHash->{'stms'}->[0],   # 開始時刻1,
            $datmHash->{'etms'}->[0],   # 終了時刻1,
            $datmHash->{'dates'}->[1],  # 実施日付2,
            $datmHash->{'stms'}->[1],   # 開始時刻2,
            $datmHash->{'etms'}->[1],   # 終了時刻2,
        ]);
    }

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
            my $prog = {};
            # 更新表示
            $prog->{'regpgid'}  = $regpgid;
            $prog->{'subno'}    = $row->subno();
            $prog->{'pgid'}     = $row->pgid();
            $prog->{'sname'}    = $row->sname();
            $prog->{'name'}     = $row->regpgid->name() if ( $regpgid );
            $c->forward('/program/_trnSEtime', [ $row, ], );
            if ( $row->date1() ) {
                my @date  = split('T', $row->date1());
                $date[0] =~ s[-][/]g;
                $prog->{'date1'}    = $date[0];
                $prog->{'shour1'}   = "$row->{'shour1'}";
                $prog->{'smin1'}    = "$row->{'smin1'}";
                $prog->{'ehour1'}   = "$row->{'ehour1'}";
                $prog->{'emin1'}    = "$row->{'emin1'}";
            }
            if ( $row->date2() ) {
                my @date  = split('T', $row->date2());
                $date[0] =~ s[-][/]g;
                $prog->{'date2'}    = $date[0];
                $prog->{'shour2'}   = "$row->{'shour2'}";
                $prog->{'smin2'}    = "$row->{'smin2'}";
                $prog->{'ehour2'}   = "$row->{'ehour2'}";
                $prog->{'emin2'}    = "$row->{'emin2'}";
            }
            $prog->{'status'}   = $row->status();
            $prog->{'layerno'}  = $row->layerno();
            $prog->{'staffid'}  = $row->staffid->staffid()
                if ( $row->staffid() );
            $prog->{'roomid'}   = $row->roomid->roomid()
                if ( $row->roomid() );
            $prog->{'memo'}     = $row->memo();
            $prog->{'progressprp'} = $row->progressprp();
            $prog->{'csid'} = $c->user->get('staffid');
            $prog->{'crole'} = $c->user->get('role');
            if (  ( $prog->{'crole'} eq 'ROOT' )
               || ( $prog->{'crole'} eq 'PG'   )
               || ( $prog->{'staffid'} eq $prog->{'csid'} )
              ) {
               # システム管理者/企画管理者/担当企画の場合、更新可能
                $c->session->{'updtic'} = time;
                $row->update( {
                    'updateflg' => $c->sessionid . $c->session->{'updtic'}
                } );
            }
            $c->stash->{'json'} = $prog;
            $c->stash->{'status'} = 'ok';
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
                $c->forward('/program/_autoProgress', [ $regpgid, 'program', $items, $row, $value ] );
                $row->update( $value ); 
                $c->stash->{'status'} = 'update';
            }
            else {
                $c->log->info('updateflg: db: ' . $row->updateflg);
                $c->log->info('updateflg: cu: ' . $c->sessionid);
                $c->log->info('                   ' . $c->session->{'updtic'} );
                $c->stash->{'status'} = 'fail';
            }
        }
    } catch {
        my $e = shift;
        $c->log->error('timetable_get error ' . localtime() .
            ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->log->info( localtime() . ' status:' . $c->stash->{'status'} );
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 _dberror

DBエラー表示

=cut

sub _dberror :Private {
    my ( $self, $c, $e) = @_; 
    $c->log->error('>>> ' . localtime() . ' Timetable:dbexp : ' . Dumper($e) );
    $c->clear_errors();
    my $body = $c->response->body() || Dumper( $e );
    $c->response->body('<FORM>DBエラー<br/><pre>' . $body . '</pre></FORM>');
    $c->response->status(200);
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
