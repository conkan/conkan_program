package conkan::Controller::Config;
use Moose;
use utf8;
use JSON;
use String::Random qw/ random_string /;
use Try::Tiny;
use namespace::autoclean;
use Data::Dumper;
use YAML;
use Encode;
use DateTime;
use POSIX qw/ strftime /;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

conkan::Controller::Config - Catalyst Controller

=head1 DESCRIPTION

管理者専用各種設定

=head1 METHODS

=head2 auto

管理者権限確認

=cut

sub auto :Private {
    my ( $self, $c ) = @_;

    return 1 if ( $c->action->reverse eq 'config/confget' );
    return 1 if ( $c->user->get('role') eq 'ROOT' );
    return 1 if ( $c->user->get('role') eq 'PG' );
    return 1 if ( $c->user->get('role') eq 'ADMIN' );
    return 1 if ( $c->action->reverse =~ qr(^config/staff) );

    $c->response->status(412);
    $c->stash->{template} = 'accessDeny.tt';
    return 0;
}

=head2 index

マイページにgo

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->go('/mypage/list');
}

=head2 setting
-----------------------------------------------------------------------------
システム全体設定

内部計算する固定設定値ハッシュ
    キー: 設定値名
    値: _crGntStr戻り値の配列添え字

=cut

my %GantConfHash = (
    'gantt_header'      => 0,
    'gantt_back_grid'   => 1,
    'gantt_colmnum'     => 2,
    'gantt_scale_str'   => 3,
    'gantt_color_str'   => 4,
);

=head2

system_confの更新

=cut

sub setting :Local {
    my ( $self, $c ) = @_;

    if ( $c->user->get('role') ne 'ROOT' ) {
        $c->stash->{'status'} = 'accessdeny';
        $c->component('View::JSON')->{expose_stash} = [ 'status' ];
        $c->forward('conkan::View::JSON');
        return;
    }
    try {
        my $sysconM = $c->model('ConkanDB::PgSystemConf');
        my @rowconf = $sysconM->all;
        my $pHconf = {};
        foreach my $pHwk ( @rowconf ) {
            $pHconf->{$pHwk->pg_conf_code} = {
                    pg_conf_name => $pHwk->pg_conf_name,
                    pg_conf_value => $pHwk->pg_conf_value,
                };
            $pHconf->{$pHwk->pg_conf_code}->{pg_conf_value} =~ s/\s+$//;
        }
            
        $c->stash->{'json'} = {}; 
        if ( $c->request->method eq 'GET' ) {
            # 希望的排他処理
            $c->session->{'updtic'} = time;
            $sysconM->update_or_create( {
                pg_conf_code => 'updateflg',
                pg_conf_name => 'updateflg',
                pg_conf_value => $c->sessionid . $c->session->{'updtic'},
            });
            # 更新表示
            my @items = qw/
                dates               start_hours         end_hours
                pg_status_vals      pg_status_color     pg_active_status
                cast_status_vals    contact_status_vals
            /;
            foreach my $item ( @items ) {
                $c->stash->{'json'}->{$item} = $pHconf->{$item};
            }
            $c->stash->{'status'} = 'ok';
        }
        else {
            # 更新実施
            my $updaterow = $sysconM->find('updateflg');
            if ( $updaterow->pg_conf_value eq
                    +( $c->sessionid . $c->session->{'updtic'}) ) {
                my $param = $c->request->body_params;
                
                foreach my $pHwk ( @rowconf ) {
                    my $code = $pHwk->pg_conf_code();
                    next if   ( $code eq 'updateflg' );
                    next if exists( $GantConfHash{$code} );
                    my $val = $param->{$code . '[pg_conf_value]'};
                    $val =~ s/\s+$//;
                    $pHwk->pg_conf_value( $val );
$c->log->debug('>>> ' . 'code : ' . $code . ' val : ' . $pHwk->pg_conf_value() );
                    $pHwk->update();
                }
                # タイムテーブルガントチャート表示用固定値算出設定
                # 日付、開始時刻列、終了時刻列を修正した場合のみでよいが、
                # めったにないので毎回設定
                my $ganttStrs = $c->forward('/config/_crGntStr', [ $param, ], );
                while ( my ( $key, $val ) = each( %GantConfHash ) ) {
$c->log->debug('>>> ' . 'key : ' . $key . ' val : ' . $val );
$c->log->debug('>>> ' . 'value : ' . $ganttStrs->[0] );
$c->log->debug('>>> ' . 'value : ' . $ganttStrs->[$val] );
                    $sysconM->update_or_create( {
                        pg_conf_code => $key,
                        pg_conf_name => $key . '(cache)',
                        pg_conf_value => $ganttStrs->[$val],
                    });
                };
                $c->stash->{'status'} = 'update';
            }
            else {
                $c->stash->{'status'} = 'fail';
            }
        }
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/setting' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 _crGntStr

タイムテーブルガントチャート表示用固定値算出

戻り値 固定値配列参照
[0]ヘッダ
[1]背景グリッド
[2]カラム総数
[3]タイムスケール表示用ハッシュ(JSON)
    キー: 日付
    値: [ 開始時刻(分表示), 終了時刻(分表示), 先頭カラム数,
          開始時刻(時),     終了時刻(時) ]
[4]ガントバー色ハッシュ(JSON)
    キー: 実行ステータス
    値: 色コード

=cut

sub _crGntStr :Private {
    my ( $self, $c, 
         $param,      # 設定フォームパラメータハッシュ
       ) = @_;

    my @dates  = @{from_json($param->{'dates[pg_conf_value]'})};
    my @starts = @{from_json($param->{'start_hours[pg_conf_value]'})};
    my @ends   = @{from_json($param->{'end_hours[pg_conf_value]'})};

    my $daycnt = scalar(@dates);
    my @colnum = ();
    my $maxcolnum = 0;

    my @shours;
    my $gantt_scale = {};
    for ( my $cnt=0; $cnt<$daycnt; $cnt++ ) {
        my @swk = split( /:/, $starts[$cnt] );
        my @ewk = split( /:/, $ends[$cnt] );
        $gantt_scale->{$dates[$cnt]} = [ ( ($swk[0] * 60) + $swk[1] ),
                                         ( ($ewk[0] * 60) + $ewk[1] ),
                                         $maxcolnum, $swk[0], $ewk[0] ];
        $ewk[0] += 1 if $ewk[1] > 0;
        $colnum[$cnt] = $ewk[0] - $swk[0];
        $shours[$cnt] = $swk[0];
        $maxcolnum += $colnum[$cnt];
    }

    my @ganttStrs = ();
    $ganttStrs[0] = "<table class=ganttHead><tr>";
    for ( my $cnt=0; $cnt<$daycnt; $cnt++ ) {
        $ganttStrs[0] .= "<th colspan=$colnum[$cnt]>$dates[$cnt]</th>";
    }
    $ganttStrs[0] .= "</tr><tr>";
    for ( my $cnt=0; $cnt<$daycnt; $cnt++ ) {
        for ( my $hcnt=0; $hcnt<$colnum[$cnt]; $hcnt++ ) {
            my $wkhstr = sprintf( '%02d', $shours[$cnt] + $hcnt );
            $ganttStrs[0] .= "<td class=ganttCell>$wkhstr</td>";
        }
    }
    $ganttStrs[0] .= "</tr></table>";

    $ganttStrs[1] = "<table class=ganttRowBack><tr class=ui-grid-row>";
    for ( my $cnt=0; $cnt<$daycnt; $cnt++ ) {
        for ( my $hcnt=0; $hcnt<$colnum[$cnt]; $hcnt++ ) {
            $ganttStrs[1] .= "<td class=ganttCell></td>";
        }
    }
    $ganttStrs[1] .= "</tr></table>";

    $ganttStrs[2] = $maxcolnum;

    $ganttStrs[3] = to_json($gantt_scale);

    my @status = @{from_json($param->{'pg_status_vals[pg_conf_value]'})};
    my @colors = @{from_json($param->{'pg_status_color[pg_conf_value]'})};
    push @status, (""); # 未定分追加

    my $stcnt = scalar(@status);
    my $gantt_color = {};
    for ( my $cnt=0; $cnt<$stcnt; $cnt++ ) {
        $gantt_color->{$status[$cnt]} = $colors[$cnt];
    }
    $ganttStrs[4] = to_json($gantt_color);

    return \@ganttStrs;
}

=head2 confget

confget  : システム設定値、スタッフ一覧、部屋一覧 取得(有効なもの)

=cut

sub confget :Local {
    my ( $self, $c ) = @_;

    try {
        my @rowconf = $c->model('ConkanDB::PgSystemConf')->all;
        my @rowroom = $c->model('ConkanDB::PgRoom')->search(
                        { 'rmdate' => \'IS NULL' },
                        { 'order_by' => { '-asc' => 'roomno' } }
                    );
        my @rowstaff = $c->model('ConkanDB::PgStaff')->search(
                        { 'staffid' => { '!=' =>  1 },
                          'rmdate' => \'IS NULL' },
                        { 'order_by' => { '-asc' => 'staffid' } }
                    );
        my $data = {};
        foreach my $row ( @rowconf ) {
            $data->{$row->pg_conf_code()} = $row->pg_conf_value();
        }

        my $rl = [ map +{ 'id'  => $_->roomid(),
                          'val' => $_->roomno() . ' ' . $_->name() },
                                @rowroom ];
        my $sl = [ map +{ 'id' => $_->staffid(), 'val' => $_->tname() }, 
                                @rowstaff ];
        $data->{'roomlist'} = to_json( $rl );
        $data->{'stafflist'} = to_json( $sl );
        $data->{'time_origin'} = $c->config->{'time_origin'};
        $c->stash->{'json'} = $data;
        $c->stash->{'status'} = 'ok';
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/confget' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 staff
-----------------------------------------------------------------------------
スタッフ管理 staff_base  : Chainの起点

=cut

sub staff_base : Chained('') : PathPart('config/staff') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

=head2 staff/list 

スタッフ管理 staff_list  : スタッフ一覧

=cut

sub staff_list : Chained('staff_base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
}

=head2 staff/listget

スタッフ管理 staff_listget  : スタッフ一覧取得

=cut

sub staff_listget : Chained('staff_base') : PathPart('listget') : Args(0) {
    my ( $self, $c ) = @_;

    try {
        my @data;
        my $rows = [
            $c->model('ConkanDB::PgStaff')->search(
                { 'account'  => { '!=' => 'admin' } },
                {
                  'join'     => 'pg_programs',
                  'distinct' => 1,
                  '+select'  => [ { count => 'pg_programs.staffid' } ],
                  '+as'      => [qw/pgcnt/],
                  'order_by' => { '-asc' => 'staffid' },
                },
            )
        ];
        for my $row (@$rows) {
            my $ll  = $row->lastlogin();
            my $rm  = $row->rmdate();
            push ( @data, {
                'rmdate'   => +( defined( $rm ) ? $rm->strftime('%F %T') : '' ),
                'name'     => $row->name(),
                'role'     => $row->role(),
                'tname'    => $row->tname(),
                'llogin'   => +( defined( $ll ) ? $ll->strftime('%F %T') : '' ),
                'staffid'  => $row->staffid(),
                'pgcnt'    => $row->get_column('pgcnt'),
            } );
        }
        $c->stash->{'json'} = \@data;
        $c->stash->{'status'} = 'ok';
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/staff/listget' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 staff/*

スタッフ管理 staff_show  : スタッフ情報更新のための表示起点

=cut

sub staff_show : Chained('staff_base') :PathPart('') :CaptureArgs(1) {
    my ( $self, $c, $staffid ) = @_;
    if (  ( $c->user->get('role') eq 'ROOT' )
       || ( $c->user->get('role') eq 'PG' )
       || ( $c->user->get('role') eq 'ADMIN' )
       || ( $c->user->get('staffid') eq $staffid ) ) {
        $c->forward( '_showCommon', [ $staffid, 'staffid', 'PgStaff', ] );
    }
    else {
        $c->stash->{'status'} = 'accessdeny';
        $c->component('View::JSON')->{expose_stash} = [ 'status' ];
        $c->forward('conkan::View::JSON');
        return;
    }
}

=head2 staff/*

スタッフ管理staff_detail  : スタッフ情報更新表示

=cut

sub staff_detail : Chained('staff_show') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    if ( $c->stash->{'status'} eq 'accessdeny' ) {
        $c->component('View::JSON')->{expose_stash} = [ 'status' ];
        $c->forward('conkan::View::JSON');
        return;
    }
    try {
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
        my $rs = $c->stash->{'rs'};
        $c->session->{'updtic'} = time;
        $rs->update( { 
            'updateflg' =>  $c->sessionid . $c->session->{'updtic'}
        } );
        my $ll = $rs->lastlogin();
        my $ma = $rs->ma();
        $ma =~ s/\s+$//;
        $c->stash->{'json'} = {
            staffid     => $rs->staffid(),
            name        => $rs->name(),
            account     => $rs->account(),
            lastlogin   => $ll ? $ll->strftime('%F %T') : '',
            role        => $rs->role(),
            ma          => $ma,
            telno       => $rs->telno(),
            regno       => $rs->regno(),
            tname       => $rs->tname(),
            tnamef      => $rs->tnamef(),
            comment     => $rs->comment(),
        };
        my $otheruidstr = $rs->otheruid();
        unless ( $otheruidstr eq '' ) {
            my $otheruid = decode_json( $otheruidstr );
            while ( my( $key, $val ) = each( %$otheruid )) {
                $c->stash->{'json'}->{$key} = $val;
            }
        }
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/staff' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 staff/*/edit

スタッフ管理staff_edit  : スタッフ情報更新

=cut

sub staff_edit : Chained('staff_show') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $staffid = $c->stash->{'staffid'};
    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/staff/' . $staffid ); # goなので帰ってこない
    }
    try {
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
        # 更新実施 パスワード処理があるため、__updatecreate は使えない
        my $rs = $c->stash->{'rs'};
        if ( $rs->updateflg eq 
                +( $c->sessionid . $c->session->{'updtic'}) ) {
            my $value = {};
            for my $item qw/name role ma
                            passwd staffid account telno regno
                            tname tnamef comment / {
                $value->{$item} = $c->request->body_params->{$item};
                $value->{$item} =~ s/\s+$// if defined($value->{$item});
            }
            $value->{'staffid'}  = $rs->staffid;
            $value->{'otheruid'} = $rs->otheruid;
            if ( $value->{'passwd'} ) {
                $value->{'passwd'} =
                    crypt( $value->{'passwd'}, random_string( 'cccc' ));
            }
            else {
                $value->{'passwd'}   = $rs->passwd
            }
            $value->{'tname'} = $value->{'tname'} || $value->{'name'};
                $rs->update( $value ); 
                $c->stash->{'status'} = 'update';
        }
        else {
            $c->stash->{'status'} = 'fail';
        }
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/staff/' . $staffid . '/edit' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 staff/*/del

スタッフ管理 staff_del   : スタッフ削除

=cut

sub staff_del : Chained('staff_show') : PathPart('del') : Args(0) {
    my ( $self, $c ) = @_;
    my $staffid = $c->stash->{'staffid'};
    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/staff/' . $staffid ); # goなので帰ってこない
    }
    try {
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
        $c->forward( '_delete', [ $staffid, 'PgProgram', 'staffid' ] );
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/staff/' . $staffid . '/del' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 staffcsvdownload
スタッフ管理 staffcsvdownload : CSVダウンロード

=cut

my %RoleTrn = (
    'NORM'  => '企画スタッフ',
    'PG'    => '企画管理スタッフ',
    'ROOT'  => 'システム管理者',
);

sub staffcsvdownload :Local {
    my ( $self, $c ) = @_;

    # adminでなく、無効でない
    my $rows =
        [ $c->model('ConkanDB::PgStaff')->search(
            {
                'account'  => { '!=' => 'admin' },
                'rmdate' => \'IS NULL',
            },
            { 'order_by' => { '-asc' => [ 'staffid' ] }, }
        ) ];
    my @data = (
        [
            '名前',
            'アカウント',
            '役割',
            'メールアドレス',
            '電話番号',
            '大会登録番号',
            '担当名',
            '担当名フリガナ',
            '備考',
        ]
    );
    foreach my $row ( @$rows ) {
        push ( @data, [
            $row->name(),                   # 名前,
            $row->account(),                # アカウント,
            $RoleTrn{$row->role()},         # 役割,
            $row->ma(),                     # メールアドレス,
            $row->telno(),                  # 電話番号,
            $row->regno(),                  # 大会登録番号,
            $row->tname(),                  # 担当名,
            $row->tnamef(),                 # 担当名フリガナ,
            $row->comment(),                # 備考,
        ]);
    }

    $c->stash->{'csv'} = \@data;
    $c->response->header( 'Content-Disposition' =>
        'attachment; filename=' .
            strftime("%Y%m%d%H%M%S", localtime()) . '_stafflist.csv' );

    $c->forward('conkan::View::Download::CSV');
}

=head2 room
-----------------------------------------------------------------------------
部屋管理 room_base  : Chainの起点

=cut

sub room_base : Chained('') : PathPart('config/room') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

=head2 room/list 

部屋管理 room_list  : 部屋一覧

=cut

sub room_list : Chained('room_base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
}

=head2 room/listget

部屋管理 room_listget  : 部屋一覧取得

=cut

sub room_listget : Chained('room_base') : PathPart('listget') : Args(0) {
    my ( $self, $c ) = @_;

    try {
        my @data;
        my $rows = [ $c->model('ConkanDB::PgRoom')->search(
                        { },
                        { 'order_by' => { '-asc' => 'roomno' } }
                    )
                ];
        for my $row (@$rows) {
            my $rm  = $row->rmdate();
            push ( @data, {
                'name'     => $row->name(),
                'roomno'   => $row->roomno(),
                'type'     => $row->type(),
                'size'     => $row->size(),
                'roomid'   => $row->roomid(),
                'rmdate'   => +( defined( $rm ) ? $rm->strftime('%F %T') : '' ),
            } );
        }
        $c->stash->{'json'} = \@data;
        $c->stash->{'status'} = 'ok';
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'room/listget' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 room/*

部屋管理 room_show  : 部屋情報更新のための表示起点

=cut

sub room_show : Chained('room_base') :PathPart('') :CaptureArgs(1) {
    my ( $self, $c, $roomid ) = @_;
    $c->forward( '_showCommon', [ $roomid, 'roomid', 'PgRoom' ] );
}

=head2 room/*

部屋管理room_detail  : 部屋情報更新表示

=cut

sub room_detail : Chained('room_show') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    my $roomid = $c->stash->{'roomid'};
    try {
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
        my $rs = $c->stash->{'rs'};
        if ( $roomid != 0 ) {
            $c->session->{'updtic'} = time;
            $rs->update( { 
                'updateflg' =>  $c->sessionid . $c->session->{'updtic'}
            } );
            $c->stash->{'json'} = {
                roomid      => $roomid,
                name        => $rs->name(),
                roomno      => $rs->roomno(),
                max         => $rs->max(),
                type        => $rs->type(),
                size        => $rs->size(),
                tablecnt    => $rs->tablecnt(),
                chaircnt    => $rs->chaircnt(),
                equips      => $rs->equips(),
                useabletime => $rs->useabletime(),
                net         => $rs->net(),
                comment     => $rs->comment(),
            };
        }
        else {
            $c->stash->{'json'} = {
                roomid      => 0,
                type        => '洋室',
                net         => 'W',
            };
        }
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/room/' . $roomid ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 room/*/edit

部屋管理room_edit  : 部屋情報更新

=cut

sub room_edit : Chained('room_show') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $roomid = $c->stash->{'roomid'};

    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/room/' . $roomid ); # goなので帰ってこない
    }
    try {
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
        my $items = [ qw/
                        name roomno max type size tablecnt
                        chaircnt equips useabletime net comment
                        / ];
        $c->forward( '_updatecreate', [ $roomid, $items ] );
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/room/' . $roomid . '/edit' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 room/*/del

部屋管理 room_del   : 部屋削除

=cut

sub room_del : Chained('room_show') : PathPart('del') : Args(0) {
    my ( $self, $c ) = @_;
    my $roomid = $c->stash->{'roomid'};
    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/room/' . $roomid ); # goなので帰ってこない
    }
    try {
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
        $c->forward( '_delete', [ $roomid, 'PgProgram', 'roomid' ] );
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/room/' . $roomid . '/del' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 roomcsvdownload
部屋管理 roomcsvdownload : CSVダウンロード

=cut

my %NetTrn = (
    'NORM'  => '無',
    'W'     => '無線',
    'E'     => '有線',
);

sub roomcsvdownload :Local {
    my ( $self, $c ) = @_;

    # 無効でない
    my $rows =
        [ $c->model('ConkanDB::PgRoom')->search(
            { 'rmdate' => \'IS NULL' },
            { 'order_by' => { '-asc' => [ 'roomno' ] }, }
        ) ];
    my @data = (
        [
            '部屋番号',
            '名前',
            '定員',
            '形式',
            '面積',
            '利用可能時間',
            '机数',
            'イス数',
            '附属設備',
            'インタネット回線',
            '備考',
        ]
    );
    foreach my $row ( @$rows ) {
        push ( @data, [
            $row->roomno(),                 # 部屋番号
            $row->name(),                   # 名前
            $row->max(),                    # 定員
            $row->type(),                   # 形式
            $row->size(),                   # 面積
            $row->useabletime(),            # 利用可能時間
            $row->tablecnt(),               # 机数
            $row->chaircnt(),               # イス数
            $row->equips(),                 # 附属設備
            $NetTrn{$row->net()},           # インタネット回線
            $row->comment(),                # 備考
        ]);
    }

    $c->stash->{'csv'} = \@data;
    $c->response->header( 'Content-Disposition' =>
        'attachment; filename=' .
            strftime("%Y%m%d%H%M%S", localtime()) . '_roomlist.csv' );

    $c->forward('conkan::View::Download::CSV');
}

=head2 cast
-----------------------------------------------------------------------------
出演者管理 cast_base  : Chainの起点

=cut

sub cast_base : Chained('') : PathPart('config/cast') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

=head2 cast/list 

出演者管理 cast_list  : 出演者一覧

=cut

sub cast_list : Chained('cast_base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
}

=head2 cast/listget

出演者管理 cast_listget  : 出演者一覧取得

=cut

sub cast_listget : Chained('cast_base') : PathPart('listget') : Args(0) {
    my ( $self, $c ) = @_;

    try {
        my @data;
        my $rows = [
            $c->model('ConkanDB::PgAllCast')->search(
                { },
                {
                  'join'     => 'pg_casts',
                  'distinct' => 1,
                  '+select'  => [ { count => 'pg_casts.castid' } ],
                  '+as'      => [qw/pgcnt/],
                  'order_by' => { '-asc' => 'castid' }
                }
            )
        ];
        for my $row (@$rows) {
            my $rm  = $row->rmdate();
            push ( @data, {
                'regno'    => $row->regno(),
                'name'     => $row->name(),
                'namef'    => $row->namef(),
                'status'   => $row->status(),
                'memo'     => $row->memo(),
                'restdate' => $row->restdate(),
                'castid'   => $row->castid(),
                'rmdate'   => +( defined( $rm ) ? $rm->strftime('%F %T') : '' ),
                'pgcnt'    => $row->get_column('pgcnt'),
            } );
        }
        $c->stash->{'json'} = \@data;
        $c->stash->{'status'} = 'ok';
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'cast/listget' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 cast/*

出演者管理 cast_show  : 出演者情報更新のための表示起点

=cut

sub cast_show : Chained('cast_base') :PathPart('') :CaptureArgs(1) {
    my ( $self, $c, $castid ) = @_;
    $c->forward( '_showCommon', [ $castid, 'castid', 'PgAllCast' ] );
}

=head2 cast/*

出演者管理cast_detail  : 出演者情報更新表示

=cut

sub cast_detail : Chained('cast_show') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    my $castid = $c->stash->{'castid'};
    try {
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
        my $rs = $c->stash->{'rs'};
        if ( $castid != 0 ) {
            $c->session->{'updtic'} = time;
            $rs->update( { 
                'updateflg' =>  $c->sessionid . $c->session->{'updtic'}
            } );
            $c->stash->{'json'} = {
                castid      => $castid,
                regno       => $rs->regno(),
                name        => $rs->name(),
                namef       => $rs->namef(),
                status      => $rs->status(),
                memo        => $rs->memo(),
                restdate    => $rs->restdate(),
                rmdate      => $rs->rmdate(),
            };
        }
        else {
            $c->stash->{'json'} = {
                castid => 0,
            };
        }
        my $statlistval = $c->model('ConkanDB::PgSystemConf')
                            ->find('contact_status_vals')->pg_conf_value();
        my $statlist = [
                map +{ 'id' => $_, 'val' => $_ }, @{from_json( $statlistval ) }
        ];
        $c->stash->{'json'}->{'statlist'} = $statlist;
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/cast/' . $castid ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 cast/*/edit

出演者管理cast_edit  : 出演者情報更新

=cut

sub cast_edit : Chained('cast_show') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $castid = $c->stash->{'castid'};

    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/cast/' . $castid ); # goなので帰ってこない
    }
    try {
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
        my $items = [ qw/ regno name namef status memo restdate / ];
        $c->forward( '_updatecreate', [ $castid, $items ] );
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/cast/' . $castid . '/edit' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 cast/*/del

出演者管理 cast_del   : 出演者削除

=cut

sub cast_del : Chained('cast_show') : PathPart('del') : Args(0) {
    my ( $self, $c ) = @_;
    my $castid = $c->stash->{'castid'};
    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/cast/' . $castid ); # goなので帰ってこない
    }
    try {
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
        $c->forward( '_delete', [ $castid, 'PgCast', 'castid' ] );
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/cast/' . $castid . '/del' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 castcsvdownload
部屋管理 castcsvdownload : CSVダウンロード

=cut

sub castcsvdownload :Local {
    my ( $self, $c ) = @_;

    # 無効でない
    my $rows =
        [ $c->model('ConkanDB::PgAllCast')->search(
            { 'rmdate' => \'IS NULL' },
            { 'order_by' => { '-asc' => [ 'regno' ] }, }
        ) ];
    my @data = (
        [
            '大会登録番号',
            '名前',
            'フリガナ',
            'コンタクトステータス',
            '備考(連絡先)',
            '備考(制限事項)',
        ]
    );
    foreach my $row ( @$rows ) {
        push ( @data, [
            $row->regno(),                  # 大会登録番号
            $row->name(),                   # 名前
            $row->namef(),                  # フリガナ
            $row->status(),                 # コンタクトステータス
            $row->memo(),                   # 備考(連絡先)
            $row->restdate(),               # 備考(制限事項)
        ]);
    }

    $c->stash->{'csv'} = \@data;
    $c->response->header( 'Content-Disposition' =>
        'attachment; filename=' .
            strftime("%Y%m%d%H%M%S", localtime()) . '_castlist.csv' );

    $c->forward('conkan::View::Download::CSV');
}

=head2 equip
-----------------------------------------------------------------------------
機材管理 equip_base  : Chainの起点

=cut

sub equip_base : Chained('') : PathPart('config/equip') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

=head2 equip/list 

機材管理 equip_list  : 機材一覧

=cut

sub equip_list : Chained('equip_base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
}

=head2 equip/listget

機材管理 equip_listget  : 機材一覧取得

=cut

sub equip_listget : Chained('equip_base') : PathPart('listget') : Args(0) {
    my ( $self, $c ) = @_;

    try {
        my @data;
        my $rows = [ $c->model('ConkanDB::PgAllEquip')->search(
                        { },
                        { 'order_by' => { '-asc' => 'equipno' } }
                    )
                ];
        for my $row (@$rows) {
            my $equipno = $row->equipno();
            next if (   ( $equipno eq 'bring-AV' )
                     || ( $equipno eq 'bring-PC' )
            );
            my $rm  = $row->rmdate();
            push ( @data, {
                'name'     => $row->name(),
                'equipno'  => $equipno,
                'spec'     => $row->spec(),
                'equipid'  => $row->equipid(),
                'rmdate'   => +( defined( $rm ) ? $rm->strftime('%F %T') : '' ),
            } );
        }
        $c->stash->{'json'} = \@data;
        $c->stash->{'status'} = 'ok';
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'equip/listget' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 equip/*

機材管理 equip_show  : 機材情報更新のための表示起点

=cut

sub equip_show : Chained('equip_base') :PathPart('') :CaptureArgs(1) {
    my ( $self, $c, $equipid ) = @_;
    $c->forward( '_showCommon', [ $equipid, 'equipid', 'PgAllEquip' ] );
}

=head2 equip/*

機材管理equip_detail  : 機材情報更新表示

=cut

sub equip_detail : Chained('equip_show') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    my $equipid = $c->stash->{'equipid'};
    try {
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
        my $rs = $c->stash->{'rs'};
        if ( $equipid != 0 ) {
            $c->session->{'updtic'} = time;
            $rs->update( { 
                'updateflg' =>  $c->sessionid . $c->session->{'updtic'}
            } );
            $c->stash->{'json'} = {
                equipid => $equipid,
                name    => $rs->name(),
                equipno => $rs->equipno(),
                spec    => $rs->spec(),
                comment => $rs->comment(),
                rmdate  => $rs->rmdate(),
            };
        }
        else {
            $c->stash->{'json'} = {
                equipid => 0,
            };
        }
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/equip/' . $equipid ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 equip/*/edit

機材管理equip_edit  : 機材情報更新

=cut

sub equip_edit : Chained('equip_show') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $equipid = $c->stash->{'equipid'};

    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/equip/' . $equipid ); # goなので帰ってこない
    }
    try {
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
        my $items = [ qw/
                        name equipno spec comment
                        / ];
        $c->forward( '_updatecreate', [ $equipid, $items ] );
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/equip/' . $equipid . '/edit' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 equip/*/del

機材管理 equip_del   : 機材削除

=cut

sub equip_del : Chained('equip_show') : PathPart('del') : Args(0) {
    my ( $self, $c ) = @_;
    my $equipid = $c->stash->{'equipid'};
    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/equip/' . $equipid ); # goなので帰ってこない
    }
    try {
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
        $c->forward( '_delete', [ $equipid, 'PgEquip', 'equipid' ] );
        die $c->stash->{'dbexp'} if ( $c->stash->{'status'} eq 'dbfail' );
    } catch {
        my $e = shift;
        $c->forward( '_dberror', [ $e, 'config/equip/' . $equipid . '/del' ] );
    };
    $c->component('View::JSON')->{expose_stash} = [ 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 equipcsvdownload
機材管理 equipcsvdownload : CSVダウンロード

=cut

sub equipcsvdownload :Local {
    my ( $self, $c ) = @_;

    # 無効でない
    my $rows =
        [ $c->model('ConkanDB::PgAllEquip')->search(
            { 'rmdate' => \'IS NULL' },
            { 'order_by' => { '-asc' => 'equipno' } }
        ) ];
    my @data = (
        [
            '機材番号',
            '名前',
            '仕様',
            '備考',
        ]
    );
    foreach my $row ( @$rows ) {
        push ( @data, [
            $row->equipno(),                # 機材番号
            $row->name(),                   # 名前
            $row->spec(),                   # 仕様
            $row->comment(),                # 備考
        ]);
    }

    $c->stash->{'csv'} = \@data;
    $c->response->header( 'Content-Disposition' =>
        'attachment; filename=' .
            strftime("%Y%m%d%H%M%S", localtime()) . '_equiplist.csv' );

    $c->forward('conkan::View::Download::CSV');
}

=head2 更新削除共通

=head2 _showCommon

情報更新のための表示起点共通

=cut

sub _showCommon : Private {
    my ( $self, $c, 
         $id,       # 対象ID
         $idstr,    # 対象IDの名前
         $table,    # 対象テーブル名
       ) = @_;

    # 対象テーブルに対応したmodelオブジェクト取得
    $c->stash->{'M'}   = $c->model('ConkanDB::' . $table);
    $c->stash->{'json'} = {};
    try {
        my $row;
        if ( $id != 0 ) {
            $row = $c->stash->{'M'}->find($id);
        }
        else {
            $row = {
                $idstr => 0,
            };
        }
        $c->stash->{'rs'} = $row;
        $c->stash->{$idstr} = $id;
        $c->stash->{'status'} = 'ok';
    } catch {
        my $e = shift;
        $c->stash->{'status'} = 'dbfail';
        $c->stash->{'dbexp'} = $e;
    };
}

=head2 _updatecreate

部屋、出演者、機材 更新追加実施

=cut

sub _updatecreate :Private {
    my ( $self, $c, 
         $id,           # 対象ID
         $items,        # 対象列名配列
       ) = @_;

    my $value = {};
    for my $item (@{$items}) {
        $value->{$item} = $c->request->body_params->{$item};
        if ( defined($value->{$item}) ) {
            $value->{$item} =~ s/\s+$//;
            delete $value->{$item} if ($value->{$item} eq '');
        }
    }
$c->log->debug('>>>> _updatecreate value ' . Dumper( $value ) );
    try {
        if ( $id != 0 ) { # 更新
            my $row = $c->stash->{'rs'};
            if ( $row->updateflg eq 
                    +( $c->sessionid . $c->session->{'updtic'}) ) {
                $row->update( $value ); 
                $c->stash->{'status'} = 'update';
            }
            else {
                $c->stash->{'status'} = 'fail';
            }
        }
        else { # 新規登録
            $c->stash->{'M'}->create( $value );
            $c->stash->{'status'} = 'add';
        }
    } catch {
        my $e = shift;
        $c->stash->{'status'} = 'dbfail';
        $c->stash->{'dbexp'} = $e;
    };
}

=head2 _delete

スタッフ、部屋、機材、出演者 削除実施

=cut

sub _delete :Private {
    my ( $self, $c, 
         $id,           # 対象ID
         $ckTable,      # 使用中チェックテーブル名
         $ckkey,        # 使用中チェック項目名
       ) = @_;

    try {
        my $row = $c->stash->{'rs'};
        if ( $row->updateflg eq 
            +( $c->sessionid . $c->session->{'updtic'}) ) {
            # 対象IDを使用中でないか確認
            my $usecnt = $c->model('ConkanDB::' . $ckTable)->search(
                            { $ckkey => $id } )->count;
            if ( $usecnt > 0 ) {
                $c->stash->{'status'} = 'inuse';
            }
            else {
                $row->update( { 'rmdate'   => \'NOW()', } );
                $c->stash->{'status'} = 'del';
            }
        }
        else {
            $c->stash->{'status'} = 'delfail';
        }
    } catch {
        my $e = shift;
        $c->stash->{'status'} = 'dbfail';
        $c->stash->{'dbexp'} = $e;
    };
}

=head2 loginlog
-----------------------------------------------------------------------------
ログイン履歴表示

=cut

sub loginlog :Local {
    my ( $self, $c ) = @_;
}

=head2 loginlogget

ログイン履歴取得

=cut

sub loginlogget :Local {
    my ( $self, $c ) = @_;
    try {
        my @data;
        my $rows = [
            $c->model('ConkanDB::LoginLog')->search( {},
                {
                    'prefetch' => [ 'staffid' ],
                    'order_by' => { -desc => 'login_date' },
                }
            )
        ];
        foreach my $row ( @$rows ) {
            my $login_date = $row->login_date();
            my $logdatestr = defined( $login_date )
                    ? $login_date->strftime('%F %T')
                    : '';
            push ( @data, {
                'staffname'  => $row->staffid->name(),
                'login_date' => $logdatestr,
            } );
        }
        $c->stash->{'json'} = \@data;
        $c->stash->{'status'} = 'ok';
    } catch {
        my $e = shift;
        $c->log->error('timetable_get error ' . localtime() .
            ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 csvout
-----------------------------------------------------------------------------
CSV出力用定数設定

=cut

my $__NOTSETSTR__ = '____未設定____';
my $__DEARSTR__   = ' 様';
my $__PGNAMESTR__ = '【企画名称】';
my $__PGDTMSTR__  = ' <企画時間>';
my $__ROOMSTR__   = ' <企画場所>';
my $__CNAMESTR__  = ' <出演名>';
my $QR_GUEST   = qr/^ゲスト参加.*/;
my $QR_SYUTUEN = qr/^出演.*/;
my $QR_URAKATA = qr/^裏方.*/;
my $QR_KYAKSKI = qr/^客席.*/;
my $QR_TRANCE  = qr/^通訳.*/;

=head2 csvout

CSV出力ラウンチページ

=cut


sub csvout :Local {
    my ( $self, $c ) = @_;

    my $M = $c->model('ConkanDB::PgSystemConf');
    my $conf = {};
    $conf->{'act_status_str'} = $M->find('pg_active_status')->pg_conf_value();
    $conf->{'act_status'} = from_json($conf->{'act_status_str'});
    $conf->{'pg_status'} = from_json($M->find('pg_status_vals')->pg_conf_value());
    $conf->{'ct_status'} = from_json($M->find('contact_status_vals')->pg_conf_value());
    $conf->{'cast_status'} = from_json($M->find('cast_status_vals')->pg_conf_value());
    $conf->{'func_is_guest'} = sub { return $_[0] =~ $QR_GUEST };
    $conf->{'func_need_plate'} = sub { return (
                $_[0] =~ $QR_SYUTUEN
             || $_[0] =~ $QR_URAKATA
             || $_[0] =~ $QR_KYAKSKI
             || $_[0] =~ $QR_TRANCE
         )};
    $c->stash->{'conf'} = $conf;
}

=head2 csvdownload
-----------------------------------------------------------------------------
差しこみデータダウンロード csvdl_base  : Chainの起点

=cut

sub csvdl_base : Chained('') : PathPart('config/csvdownload') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

=head2 csvdownload/invitate

差しこみデータダウンロード invitate  : 企画案内書用

CSV: 氏名, 企画案内(企画名称, 実施日時と場所)...

=cut

sub invitate : Chained('csvdl_base') : PathPart('invitate') : Args(0) {
    my ( $self, $c ) = @_;
              
    my $condval = $c->request->body_params->{'ct_status'};
    my $get_status = ( ref($condval) eq 'ARRAY' ) ? $condval : [ $condval ];
    push ( @$get_status, \'IS NULL' )
        if exists( $c->request->body_params->{'ct_null_stat'} );
    # 指定のコンタクトステータスで抽出
    my $rows = [
        $c->model('ConkanDB::PgAllCast')->search(
            { 'me.status' => $get_status },
            {
              'join'     => 'pg_casts',
              'distinct' => 1,
              '+select'  => [ { count => 'pg_casts.castid' } ],
              '+as'      => [qw/pgcnt/],
              'order_by' => { '-asc' => 'castid' }
            }
        )
    ];
$c->log->debug('>>> ' . 'cast cnt : ' . scalar(@$rows) );

    my @data = (
        [
            '氏名',
            '企画名称',
            '実施日時と場所',
            '...',
        ]
    );
    # 企画絞込用(有効な実行ステータス)
    my $actpgsts = from_json(
        $c->model('ConkanDB::PgSystemConf')->find('pg_active_status')
            ->pg_conf_value()
    );
    for my $row (@$rows) {
       next unless  $row->get_column('pgcnt'),

       my $castname = $row->name();
       my $castid   = $row->castid();
       # 出演する有効な企画のみ抽出
       my $castrows = [
           $c->model('ConkanDB::PgCast')->search(
               {
                 'me.castid'    => $castid,
                 'pgid.status'  => $actpgsts,
               },
               {
                 'prefetch'     => [ { 'pgid' => 'roomid' },
                                     { 'pgid' => 'regpgid' },],
                 'order_by'     => { '-asc' => 'pgid.regpgid' }
               }
           )
        ];
        next unless scalar(@$castrows);

        my @onedata = ( $castname . $__DEARSTR__ );
        for my $castrow (@$castrows) {
            my $pgname = $__PGNAMESTR__
                        . $castrow->pgid->regpgid->regpgid() . ' '
                        . $castrow->pgid->regpgid->name();
            my $pgdata = $__PGDTMSTR__;
            my $dtmHash = $c->forward('/program/_trnDateTime4csv',
                    [ $castrow->pgid, ], );
            if ( $dtmHash->{'dates'} ) {
                for ( my $idx=0; $idx<scalar(@{$dtmHash->{'dates'}}); $idx++ ) {
                    $pgdata .= ' '
                            .  $dtmHash->{'dates'}->[$idx] . ' '
                            . +( $dtmHash->{'stms'}->[$idx] || $__NOTSETSTR__)
                            . '-'
                            . +($dtmHash->{'etms'}->[$idx] || $__NOTSETSTR__);
                }
            }
            else {
                $pgdata .= $__NOTSETSTR__;
            }
            $pgdata .= $__ROOMSTR__;
            $pgdata .= $castrow->pgid->roomid
                        ? $castrow->pgid->roomid->name()
                        : $__NOTSETSTR__;
            $pgdata .= $__CNAMESTR__ . $castrow->name()
                if ( $castrow->name()
                    && ( $castrow->name() ne $castname ) );
            my $cast_stat = $castrow->status();
            $pgdata .= '(' . $castrow->status() . ')'
                if ( $cast_stat && !( $cast_stat =~ $QR_SYUTUEN ) );
            push ( @onedata, $pgname, $pgdata );
        }
       push ( @data, \@onedata );
    }
 
    $c->stash->{'csv'} = \@data;
    $c->stash->{'csvenc'} = 'cp932';
    $c->response->header( 'Content-Disposition' =>
        'attachment; filename=' .
            strftime("%Y%m%d%H%M%S", localtime()) . '_invitate.csv' );
    $c->forward('conkan::View::Download::CSV');
}

=head2 csvdownload/forroom

差しこみデータダウンロード forroom  : 企画部屋紙用

CSV: 企画名, 企画番号, 実施日, 開始時刻, 場所名

=cut

sub forroom : Chained('csvdl_base') : PathPart('forroom') : Args(0) {
    my ( $self, $c ) = @_;

    my $rowconf = $c->model('ConkanDB::PgSystemConf')->find('pg_active_status');
    # 有効な実行ステータスで抽出
    my $rows = [
        $c->model('ConkanDB::PgProgram')->search(
            { 
              'me.status' => from_json( $rowconf->pg_conf_value() ),
            },
            {
              'prefetch' => [ 'regpgid', 'roomid' ],
              'order_by' => { '-asc' => [ 'me.regpgid', 'me.subno' ] },
            }
        )
    ];
$c->log->debug('>>> ' . 'program cnt : ' . scalar(@$rows) );

    my @data = (
        [
            '企画名',
            '企画番号',
            '実施日',
            '開始時刻',
            '場所名',
        ]
    );
    for my $row (@$rows) {
        my $dtmHash =  $c->forward('/program/_trnDateTime4csv', [ $row, ], );
        my $roomname =  $row->roomid ? $row->roomid->name() : $__NOTSETSTR__;
        if ( $dtmHash->{'dates'} ) {
            for ( my $idx=0; $idx<scalar(@{$dtmHash->{'dates'}}); $idx++ ) {
                push ( @data, [
                    $row->regpgid->name(),          # 企画名,
                    $row->regpgid->regpgid(),       # 企画番号,
                    $dtmHash->{'dates'}->[$idx],    # 実施日
                    $dtmHash->{'stms'}->[$idx] || $__NOTSETSTR__,     # 開始時刻,
                    $roomname,                      # 場所名,
                ]);
            }
        }
        else {
            push ( @data, [
                $row->regpgid->name(),          # 企画名,
                $row->regpgid->regpgid(),       # 企画番号,
                $__NOTSETSTR__,                 # 実施日
                $__NOTSETSTR__,                 # 開始時刻,
                $roomname,                      # 場所名,
            ]);
        }
    }

    $c->stash->{'csv'} = \@data;
    $c->stash->{'csvenc'} = 'cp932';
    $c->response->header( 'Content-Disposition' =>
        'attachment; filename=' .
            strftime("%Y%m%d%H%M%S", localtime()) . '_forroom.csv' );
    $c->forward('conkan::View::Download::CSV');
}

=head2 csvdownload/forcast

差しこみデータダウンロード forcast  : 出演者前垂用

CSV: 氏名, 企画名, 部屋名, 企画番号, 実施日, 開始時刻
=cut

sub forcast : Chained('csvdl_base') : PathPart('forcast') : Args(0) {
    my ( $self, $c ) = @_;
    my $rowconf = $c->model('ConkanDB::PgSystemConf')->find('pg_active_status');
    # 有効な実行ステータスで抽出
    my $rows = [
        $c->model('ConkanDB::PgProgram')->search(
            { 
              'me.status' => from_json( $rowconf->pg_conf_value() ),
            },
            {
              'prefetch' => [ 'regpgid', 'roomid' ],
              'order_by' => { '-asc' => [ 'me.regpgid', 'me.subno' ] },
            }
        )
    ];
$c->log->debug('>>> ' . 'program cnt : ' . scalar(@$rows) );

    my @data = (
        [
            '氏名',
            '企画名',
            '部屋名',
            '企画番号',
            '実施日',
            '開始時刻',
        ]
    );
    for my $row (@$rows) {
        my $pgname = $row->regpgid->name();
        my $roomname =  $row->roomid ? $row->roomid->name() : $__NOTSETSTR__;
        my $regpgid = $row->regpgid->regpgid();
        my $dtmHash =  $c->forward('/program/_trnDateTime4csv', [ $row, ], );

        my $condval = $c->request->body_params->{'cast_status'};
        my $get_status = ( ref($condval) eq 'ARRAY' ) ? $condval : [ $condval ];
        push ( @$get_status, \'IS NULL' )
            if exists( $c->request->body_params->{'cast_null_stat'} );
        # 指定の出演ステータスで抽出
        my $castrows = [
            $c->model('ConkanDB::PgCast')->search(
               {
                 'me.pgid'    => $row->pgid(),
                 'me.status'  => $get_status,
               },
               {
                 'prefetch'     => 'castid',
                 'order_by'     => { '-asc' => 'me.id' }
               }
           )
        ];
        next unless ( scalar(@$castrows) );

$c->log->debug('>>> ' . 'cast cnt : ' . scalar(@$castrows) );
        for my $castrow (@$castrows) {
            my $cname =  $castrow->name() || $castrow->castid->name();
            if ( $dtmHash->{'dates'} ) {
                for ( my $idx=0; $idx<scalar(@{$dtmHash->{'dates'}}); $idx++ ) {
                    push ( @data, [
                        $cname,                         # 氏名
                        $pgname,                        # 企画名,
                        $roomname,                      # 場所名,
                        $regpgid,                       # 企画番号,
                        $dtmHash->{'dates'}->[$idx],    # 実施日
                        $dtmHash->{'stms'}->[$idx] || $__NOTSETSTR__,     # 開始時刻,
                    ]);
                }
            }
            else {
                push ( @data, [
                    $cname,                         # 氏名
                    $pgname,                        # 企画名,
                    $roomname,                      # 場所名,
                    $regpgid,                       # 企画番号,
                    $__NOTSETSTR__,                 # 実施日
                    $__NOTSETSTR__,                 # 開始時刻,
                ]);
            }
        }
    }

    $c->stash->{'csv'} = \@data;
    $c->stash->{'csvenc'} = 'cp932';
    $c->response->header( 'Content-Disposition' =>
        'attachment; filename=' .
            strftime("%Y%m%d%H%M%S", localtime()) . '_forcast.csv' );
    $c->forward('conkan::View::Download::CSV');
}

=head2 csvdownload/memcnt

差しこみデータダウンロード memcnt  : 企画別人数用
    
CSV:  企画名 企画番号, 実施日, 開始時刻, 部屋名, 内線番号, 出演人数, 裏方人数, 客席人数, 通訳人数

=cut

sub memcnt : Chained('csvdl_base') : PathPart('memcnt') : Args(0) {
    my ( $self, $c ) = @_;
    my $rowconf = $c->model('ConkanDB::PgSystemConf')->find('pg_active_status');
    # 有効な実行ステータスで抽出
    my $rows = [
        $c->model('ConkanDB::PgProgram')->search(
            { 
              'me.status' => from_json( $rowconf->pg_conf_value() ),
            },
            {
              'prefetch' => [ 'regpgid', 'roomid' ],
              'order_by' => { '-asc' => [ 'me.regpgid', 'me.subno' ] },
            }
        )
    ];
$c->log->debug('>>> ' . 'program cnt : ' . scalar(@$rows) );

    my @data = (
        [
            '企画名',
            '企画番号',
            '実施日',
            '開始時刻',
            '部屋名',
            '内線番号',
            '出演人数',
            '裏方人数',
            '客席人数',
            '通訳人数',
        ]
    );
    for my $row (@$rows) {
        my $pgname = $row->regpgid->name();
        my $regpgid = $row->regpgid->regpgid();
        my $dtmHash =  $c->forward('/program/_trnDateTime4csv', [ $row, ], );
        my $roomname =  $row->roomid ? $row->roomid->name() : $__NOTSETSTR__;

        # 指定の企画内部IDで抽出
        my $castrows = [
            $c->model('ConkanDB::PgCast')->search(
               {
                 'pgid'    => $row->pgid(),
               },
               {
                 '+select'  => [ { count => 'status' } ],
                 '+as'      => [qw/stcnt/],
                 'group_by' => 'status',
               }
           )
        ];
        my $syutuen_cnt=0;
        my $ura_cnt=0;
        my $kyaku_cnt=0;
        my $trn_cnt=0;
        for my $castrow (@$castrows) {
            my $cast_stat = $castrow->status();
            next unless ( $cast_stat );
            if ( $cast_stat =~ $QR_SYUTUEN ) {
                $syutuen_cnt += $castrow->get_column('stcnt');
            }
            elsif ( $cast_stat =~ $QR_URAKATA ) {
                $ura_cnt += $castrow->get_column('stcnt');
            }
            elsif ( $cast_stat =~ $QR_KYAKSKI ) {
                $kyaku_cnt += $castrow->get_column('stcnt');
            }
            elsif ( $cast_stat =~ $QR_TRANCE ) {
                $trn_cnt += $castrow->get_column('stcnt');
            }
        }
        my $sum_cnt = $syutuen_cnt + $ura_cnt + $kyaku_cnt + $trn_cnt;
        next unless ( $sum_cnt );

$c->log->debug('>>> ' . 'sum cnt : ' . $sum_cnt );
        if ( $dtmHash->{'dates'} ) {
            for ( my $idx=0; $idx<scalar(@{$dtmHash->{'dates'}}); $idx++ ) {
                push ( @data, [
                    $pgname,                        # 企画名,
                    $regpgid,                       # 企画番号,
                    $dtmHash->{'dates'}->[$idx],    # 実施日
                    $dtmHash->{'stms'}->[$idx] || $__NOTSETSTR__,     # 開始時刻,
                    $roomname,                      # 場所名,
                    '',                             # 内線番号
                    $syutuen_cnt,                   # 出演人数
                    $ura_cnt,                       # 裏方人数
                    $kyaku_cnt,                     # 客席人数
                    $trn_cnt,                       # 通訳人数
                ]);
            }
        }
        else {
            push ( @data, [
                $pgname,                        # 企画名,
                $regpgid,                       # 企画番号,
                $__NOTSETSTR__,                 # 実施日
                $__NOTSETSTR__,                 # 開始時刻,
                $roomname,                      # 場所名,
                '',                             # 内線番号
                $syutuen_cnt,                   # 出演人数
                $ura_cnt,                       # 裏方人数
                $kyaku_cnt,                     # 客席人数
                $trn_cnt,                       # 通訳人数
            ]);
        }
    }

    $c->stash->{'csv'} = \@data;
    $c->stash->{'csvenc'} = 'cp932';
    $c->response->header( 'Content-Disposition' =>
        'attachment; filename=' .
            strftime("%Y%m%d%H%M%S", localtime()) . '_memcnt.csv' );
    $c->forward('conkan::View::Download::CSV');
}

=head2 csvdownload/castbyprg

差しこみデータダウンロード castbyprg  : 企画別出演者用

CSV: 企画名, 企画番号, 実施日, 開始時刻, 部屋名, 内線番号, 出演者<ステータス>

=cut

sub castbyprg : Chained('csvdl_base') : PathPart('castbyprg') : Args(0) {
    my ( $self, $c ) = @_;
    my $rowconf = $c->model('ConkanDB::PgSystemConf')->find('pg_active_status');
    # 有効な実行ステータスで抽出
    my $rows = [
        $c->model('ConkanDB::PgProgram')->search(
            { 
              'me.status' => from_json( $rowconf->pg_conf_value() ),
            },
            {
              'prefetch' => [ 'regpgid', 'roomid' ],
              'order_by' => { '-asc' => [ 'me.regpgid', 'me.subno' ] },
            }
        )
    ];
$c->log->debug('>>> ' . 'program cnt : ' . scalar(@$rows) );

    my @data = (
        [
            '企画名',
            '企画番号',
            '実施日',
            '開始時刻',
            '部屋名',
            '内線番号',
            '出演者<ステータス>',
        ]
    );
    for my $row (@$rows) {
        my $pgname = $row->regpgid->name();
        my $regpgid = $row->regpgid->regpgid();
        my $dtmHash =  $c->forward('/program/_trnDateTime4csv', [ $row, ], );
        my $roomname =  $row->roomid ? $row->roomid->name() : $__NOTSETSTR__;

        # 指定の企画内部IDで抽出
        my $castrows = [
            $c->model('ConkanDB::PgCast')->search(
               {
                 'pgid'    => $row->pgid(),
               },
               {
                 'prefetch'     => 'castid',
                 'order_by'     => { '-asc' => 'me.id' }
               }
           )
        ];
        my $castdata = '';
        for my $castrow (@$castrows) {
            my $cast_name = $castrow->name() || $castrow->castid->name();
            my $cast_stat = $castrow->status();
            next unless ( $cast_stat );
            if (    $cast_stat =~ $QR_SYUTUEN
                ||  $cast_stat =~ $QR_URAKATA
                ||  $cast_stat =~ $QR_KYAKSKI
                ||  $cast_stat =~ $QR_TRANCE ) {
                $castdata .= "\r\n" if ( $castdata );
                $castdata .= $cast_name . '<' . $cast_stat . '>';
            }
        }

        if ( $dtmHash->{'dates'} ) {
            for ( my $idx=0; $idx<scalar(@{$dtmHash->{'dates'}}); $idx++ ) {
                push ( @data, [
                    $pgname,                        # 企画名,
                    $regpgid,                       # 企画番号,
                    $dtmHash->{'dates'}->[$idx],    # 実施日
                    $dtmHash->{'stms'}->[$idx] || $__NOTSETSTR__,     # 開始時刻,
                    $roomname,                      # 場所名,
                    '',                             # 内線番号
                    $castdata,                      # 出演者<ステータス>
                ]);
            }
        }
        else {
            push ( @data, [
                $pgname,                        # 企画名,
                $regpgid,                       # 企画番号,
                $__NOTSETSTR__,                 # 実施日
                $__NOTSETSTR__,                 # 開始時刻,
                $roomname,                      # 場所名,
                '',                             # 内線番号
                $castdata,                      # 出演者<ステータス>
            ]);
        }
    }

    $c->stash->{'csv'} = \@data;
    $c->stash->{'csvenc'} = 'cp932';
    $c->response->header( 'Content-Disposition' =>
        'attachment; filename=' .
            strftime("%Y%m%d%H%M%S", localtime()) . '_castbyprg.csv' );
    $c->forward('conkan::View::Download::CSV');
}

=head2 _dberror

DBエラー表示

=cut

sub _dberror :Private {
    my ( $self, $c,
         $e,        # エラーオブジェクト
         $logstr,   # ログ出力文字列
        ) = @_; 

    my @str = split(/\s/, $e);
    $c->clear_errors();
    if ( $str[6] eq 'Duplicate' ) {
        $c->log->error( localtime() . ' ' . $logstr . ' error dupl: ' . 
            $str[11] . 'val ' . decode('UTF-8', $str[8] ) );
        $c->stash->{'status'} = 'dupl';
        $str[11] =~ s/_UNIQUE//;
        $c->stash->{'json'} = {
            dupkey => $str[11],
            dupval => $str[8],
        };
    }
    else {
        $c->log->error( localtime() . $logstr . 'error dbexp: ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    }
}

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
