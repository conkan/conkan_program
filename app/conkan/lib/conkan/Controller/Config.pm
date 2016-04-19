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

    return 1 if ( $c->user->get('role') eq 'ROOT' );
    return 1 if ( $c->user->get('role') eq 'ADMIN' );

    $c->response->status(412);
    $c->stash->{template} = 'accessDeny.tt';
    return 0;
}

=head2 index

システム全体設定にgo

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->go('setting');
}

=head2 setting
-----------------------------------------------------------------------------
システム全体設定
    system_confの更新
    regist_confは別途 -> DBではなくregist.ymlに移行

=cut

sub setting :Local {
    my ( $self, $c ) = @_;

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

    if ( $c->request->method eq 'GET' ) {
        # 希望的排他処理
        $c->session->{'updtic'} = time;
        $sysconM->update_or_create( {
            pg_conf_code => 'updateflg',
            pg_conf_name => 'updateflg',
            pg_conf_value => $c->sessionid . $c->session->{'updtic'},
        });
        # 更新表示
        $c->stash->{'cnf'} = $pHconf;
    }
    else {
        # 更新実施
        my $updaterow = $sysconM->find('updateflg');
        if ( $updaterow->pg_conf_value eq
                +( $c->sessionid . $c->session->{'updtic'}) ) {
            my $param = $c->request->body_params;
            try {
                foreach my $pHwk ( @rowconf ) {
                    my $code = $pHwk->pg_conf_code;
                    next if   ( $code eq 'updateflg' )
                           || ( $code eq 'gantt_header' )
                           || ( $code eq 'gantt_back_grid' )
                           || ( $code eq 'gantt_colmnums' )
                           || ( $code eq 'gantt_scale_str' )
                           || ( $code eq 'gantt_color_str' );
                    $param->{$code} =~ s/\s+$//;
                    $pHwk->pg_conf_value( $param->{$pHwk->pg_conf_code} );
                    $pHwk->update();
                }
                # タイムテーブルガントチャート表示用固定値算出設定
                # 日付、開始時刻列、終了時刻列を修正した場合のみでよいが、
                # めったにないので毎回設定
                my $ganttStrs = $c->forward('/config/_crGntStr', [ $param, ], );
                $sysconM->update_or_create( {
                    pg_conf_code => 'gantt_header',
                    pg_conf_name => 'gantt_header(cache)',
                    pg_conf_value => $ganttStrs->[0],
                });
                $sysconM->update_or_create( {
                    pg_conf_code => 'gantt_back_grid',
                    pg_conf_name => 'gantt_back_grid(cache)',
                    pg_conf_value => $ganttStrs->[1],
                });
                $sysconM->update_or_create( {
                    pg_conf_code => 'gantt_colmnum',
                    pg_conf_name => 'gantt_colmnum(cache)',
                    pg_conf_value => $ganttStrs->[2],
                });
                $sysconM->update_or_create( {
                    pg_conf_code => 'gantt_scale_str',
                    pg_conf_name => 'gantt_scale_str(cache)',
                    pg_conf_value => $ganttStrs->[3],
                });
                $sysconM->update_or_create( {
                    pg_conf_code => 'gantt_color_str',
                    pg_conf_name => 'gantt_color_str(cache)',
                    pg_conf_value => $ganttStrs->[4],
                });

                $c->stash->{'state'} = 'success';
            } catch {
                $c->detach( '_dberror', [ shift ] );
            };
        }
        else {
            $c->stash->{'state'} = 'deny';
        }
        $c->stash->{'cnf'} = undef;
    }
}

=head2 _crGntStr

タイムテーブルガントチャート表示用固定値算出

戻り値 固定値配列参照 [0]ヘッダ [1]背景グリッド [2]カラム総数
              [3]タイムスケール表示用ハッシュ(JSON)
                    キー: 日付
                      値: [ 開始時刻(分表示), 終了時刻(分表示), 先頭カラム数 ]
              [4]ガントバー色ハッシュ(JSON)
                    キー: 実行ステータス
                      値: 色コード

=cut

sub _crGntStr :Private {
    my ( $self, $c, 
         $param,      # 設定フォームパラメータハッシュ
       ) = @_;

    my @dates  = @{from_json($param->{'dates'})};
    my @starts = @{from_json($param->{'start_hours'})};
    my @ends   = @{from_json($param->{'end_hours'})};

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
                                         $maxcolnum ];
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

    my @status = @{from_json($param->{'pg_status_vals'})};
    my @colors = @{from_json($param->{'pg_status_color'})};
    push @status, (""); # 未定分追加

    my $stcnt = scalar(@status);
    my $gantt_color = {};
    for ( my $cnt=0; $cnt<$stcnt; $cnt++ ) {
        $gantt_color->{$status[$cnt]} = $colors[$cnt];
    }
    $ganttStrs[4] = to_json($gantt_color);

    return \@ganttStrs;
}
=head2 staff
-----------------------------------------------------------------------------
スタッフ管理 staff_base  : Chainの起点

=cut

sub staff_base : Chained('') : PathPart('config/staff') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # staffテーブルに対応したmodelオブジェクト取得
    $c->stash->{'M'}   = $c->model('ConkanDB::PgStaff');
}

=head2 staff/list 

スタッフ管理 staff_list  : スタッフ一覧

=cut

sub staff_list : Chained('staff_base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{'list'} = [ $c->stash->{M}
                            ->search( { 'account'  => { '!=' => 'admin' } },
                                      { 'order_by' => { '-asc' => 'staffid' } } 
                                    )
                          ];
}

=head2 staff/*

スタッフ管理 staff_show  : スタッフ情報更新のための表示起点

=cut

sub staff_show : Chained('staff_base') :PathPart('') :CaptureArgs(1) {
    my ( $self, $c, $staffid ) = @_;
    
    my $rowstaff = $c->stash->{'M'}->find($staffid);
    $c->session->{'updtic'} = time;
    $rowstaff->update( { 
        'updateflg' =>  $c->sessionid . $c->session->{'updtic'}
    } );
    $c->stash->{'rs'} = $rowstaff;
    if ( $rowstaff->otheruid ) {
        my $cybozu = decode_json( $rowstaff->otheruid );
        while ( my( $key, $val ) = each( %$cybozu )) {
            $c->stash->{'rs'}->{$key} = $val;
        }
    }
    $c->stash->{'rs'}->{'passwd'} = undef;
}

=head2 staff/*

スタッフ管理staff_detail  : スタッフ情報更新表示

=cut

sub staff_detail : Chained('staff_show') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
}

=head2 staff/*/edit

スタッフ管理staff_edit  : スタッフ情報更新

=cut

sub staff_edit : Chained('staff_show') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $staffid = $c->stash->{'rs'}->staffid;
    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/staff/' . $staffid );
    }
    else {
        # 更新実施
        my $rowstaff = $c->stash->{'M'}->find($staffid);
        if ( $rowstaff->updateflg eq 
                +( $c->sessionid . $c->session->{'updtic'}) ) {
            my $value = {};
            for my $item qw/name role ma
                            passwd staffid account telno regno
                            tname tnamef comment / {
                $value->{$item} = $c->request->body_params->{$item};
                $value->{$item} =~ s/\s+$// if defined($value->{$item});
                delete $value->{$item} if ( $value->{$item} eq '' );
            }
            $value->{'staffid'}  = $rowstaff->staffid;
            $value->{'otheruid'} = $rowstaff->otheruid;
            if ( $value->{'passwd'} ) {
                $value->{'passwd'} =
                    crypt( $value->{'passwd'}, random_string( 'cccc' ));
            }
            else {
                $value->{'passwd'}   = $rowstaff->passwd
            }
            $value->{'tname'} = $value->{'tname'} || $value->{'name'};
            try {
                $rowstaff->update( $value ); 
                $c->response->body('<FORM><H1>更新しました</H1></FORM>');
            } catch {
                $c->detach( '_dberror', [ shift ] );
            };
        }
        else {
            $c->stash->{'rs'} = undef;
            $c->response->body = '<FORM><H1>更新できませんでした</H1><BR/>他のシステム管理者が変更した可能性があります</FORM>';
        }
        $c->stash->{'rs'} = undef;
        $c->response->status(200);
    }
}

=head2 staff/*/del

スタッフ管理 staff_del   : スタッフ削除

=cut

sub staff_del : Chained('staff_show') : PathPart('del') : Args(0) {
    my ( $self, $c ) = @_;
    my $staffid = $c->stash->{'rs'}->staffid;
    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/staff/' . $staffid );
    }
    else {
        $c->detach( '_delete', [ $staffid ] );
    }
}

=head2 room
-----------------------------------------------------------------------------
部屋管理 room_base  : Chainの起点

=cut

sub room_base : Chained('') : PathPart('config/room') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # roomテーブルに対応したmodelオブジェクト取得
    $c->stash->{'M'}   = $c->model('ConkanDB::PgRoom');
}

=head2 room/list 

部屋管理 room_list  : 部屋一覧

=cut

sub room_list : Chained('room_base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{'list'} = [ $c->stash->{M}
                            ->search( { },
                                      { 'order_by' => { '-asc' => 'roomid' } } )
                          ];
}

=head2 room/*

部屋管理 room_show  : 部屋情報更新のための表示起点

=cut

sub room_show : Chained('room_base') :PathPart('') :CaptureArgs(1) {
    my ( $self, $c, $roomid ) = @_;
    
    my $rowroom;
    if ( $roomid != 0 ) {
        $rowroom = $c->stash->{'M'}->find($roomid);
        $c->session->{'updtic'} = time;
        $rowroom->update( { 
            'updateflg' =>  $c->sessionid . $c->session->{'updtic'}
        } );
    } else {
        $rowroom = {
            'roomid'        => 0,
            'name'          => '',
            'roomno'        => '',
            'max'           => 0,
            'type'          => '洋室',
            'size'          => 0,
            'tablecnt'      => 0,
            'chaircnt'      => 0,
            'equips'        => '',
            'useabletime'   => undef,
            'net'           => 'W',
            'comment'       => undef,
        };
    }
    $c->stash->{'rs'} = $rowroom;
    $c->stash->{'roomid'} = $roomid;
}

=head2 room/*

部屋管理room_detail  : 部屋情報更新表示

=cut

sub room_detail : Chained('room_show') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
}

=head2 room/*/edit

部屋管理room_edit  : 部屋情報更新

=cut

sub room_edit : Chained('room_show') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $roomid = $c->stash->{'roomid'};

    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/room/' . $roomid );
    }
    else {
        my $items = [ qw/
                        name roomno max type size tablecnt
                        chaircnt equips useabletime net comment
                        / ];
        $c->detach( '_updatecreate', [ $roomid, $items ] );
    }
}

=head2 room/*/del

部屋管理 room_del   : 部屋削除

=cut

sub room_del : Chained('room_show') : PathPart('del') : Args(0) {
    my ( $self, $c ) = @_;
    my $roomid = $c->stash->{'rs'}->{'roomid'};
    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/room/' . $roomid );
    }
    else {
        $c->detach( '_delete', [ $roomid ] );
    }
}

=head2 cast
-----------------------------------------------------------------------------
出演者管理 cast_base  : Chainの起点

=cut

sub cast_base : Chained('') : PathPart('config/cast') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # allcastテーブルに対応したmodelオブジェクト取得
    $c->stash->{'M'}   = $c->model('ConkanDB::PgAllCast');
}

=head2 cast/list 

出演者管理 cast_list  : 出演者一覧

=cut

sub cast_list : Chained('cast_base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{'list'} = [ $c->stash->{M}
                            ->search( { },
                                      { 'order_by' => { '-asc' => 'castid' } } )
                          ];
}

=head2 cast/*

出演者管理 cast_show  : 出演者情報更新のための表示起点

=cut

sub cast_show : Chained('cast_base') :PathPart('') :CaptureArgs(1) {
    my ( $self, $c, $castid ) = @_;
    
    my $rowcast;
    if ( $castid != 0 ) {
        $rowcast = $c->stash->{'M'}->find($castid);
        $c->session->{'updtic'} = time;
        $rowcast->update( { 
            'updateflg' =>  $c->sessionid . $c->session->{'updtic'}
        } );
    }
    else {
        $rowcast = {
            'castid'    => 0,
        };
    }
    if ( $c->request->method eq 'GET' ) {
        my $M = $c->model('ConkanDB::PgSystemConf');
        $c->stash->{'statlist'}  = [
            { 'id' => '', 'val' => '' },
            map +{ 'id' => $_, 'val' => $_ },
               @{from_json( $M->find('contact_status_vals')->pg_conf_value() )}
            ];
    }
    $c->stash->{'rs'} = $rowcast;
    $c->stash->{'castid'} = $castid;
}

=head2 cast/*

出演者管理cast_detail  : 出演者情報更新表示

=cut

sub cast_detail : Chained('cast_show') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
}

=head2 cast/*/edit

出演者管理cast_edit  : 出演者情報更新

=cut

sub cast_edit : Chained('cast_show') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $castid = $c->stash->{'castid'};

    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/cast/' . $castid );
    }
    else {
        my $items = [ qw/ regno name namef status memo restdate / ];
        $c->detach( '_updatecreate', [ $castid, $items ] );
    }
}

=head2 equip
-----------------------------------------------------------------------------
機材管理 equip_base  : Chainの起点

=cut

sub equip_base : Chained('') : PathPart('config/equip') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # equipテーブルに対応したmodelオブジェクト取得
    $c->stash->{'M'}   = $c->model('ConkanDB::PgAllEquip');
}

=head2 equip/list 

機材管理 equip_list  : 機材一覧

=cut

sub equip_list : Chained('equip_base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{'list'} = [ $c->stash->{'M'}
                            ->search( { },
                                      { 'order_by' => { '-asc' => 'equipid' } } )
                          ];
}

=head2 equip/*

機材管理 equip_show  : 機材情報更新のための表示起点

=cut

sub equip_show : Chained('equip_base') :PathPart('') :CaptureArgs(1) {
    my ( $self, $c, $equipid ) = @_;
    
    my $rowequip;
    if ( $equipid != 0 ) {
        $rowequip = $c->stash->{'M'}->find($equipid);
        $c->session->{'updtic'} = time;
        $rowequip->update( { 
            'updateflg' =>  $c->sessionid . $c->session->{'updtic'}
        } );
    } else {
        $rowequip = {
            'equipid'       => 0,
        };
    }
    $c->stash->{'rs'} = $rowequip;
    $c->stash->{'equipid'} = $equipid;
}

=head2 equip/*

機材管理equip_detail  : 機材情報更新表示

=cut

sub equip_detail : Chained('equip_show') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
}

=head2 equip/*/edit

機材管理equip_edit  : 機材情報更新

=cut

sub equip_edit : Chained('equip_show') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $equipid = $c->stash->{'equipid'};

    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/equip/' . $equipid );
    }
    else {
        my $items = [ qw/
                        name equipno spec comment
                        / ];
        $c->detach( '_updatecreate', [ $equipid, $items ] );
    }
}

=head2 equip/*/del

機材管理 equip_del   : 機材削除

=cut

sub equip_del : Chained('equip_show') : PathPart('del') : Args(0) {
    my ( $self, $c ) = @_;
    my $equipid = $c->stash->{'equipid'};
    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/equip/' . $equipid );
    }
    else {
        $c->detach( '_delete', [ $equipid ] );
    }
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
        $value->{$item} =~ s/\s+$// if defined($value->{$item});
        delete $value->{$item} if ( $value->{$item} eq '' );
    }
    try {
        if ( $id != 0 ) { # 更新
            my $row = $c->stash->{'M'}->find($id);
            if ( $row->updateflg eq 
                    +( $c->sessionid . $c->session->{'updtic'}) ) {
                $row->update( $value ); 
                $c->response->body('<FORM><H1>更新しました</H1></FORM>');
            }
            else {
                $c->response->body =
                        '<FORM><H1>更新できませんでした</H1><BR/>' .
                        '他のシステム管理者が変更した可能性があります</FORM>';
            }
        }
        else { # 新規登録
            $c->stash->{'M'}->create( $value );
            $c->response->body('<FORM><H1>登録しました</H1></FORM>');
        }
    } catch {
        $c->detach( '_dberror', [ shift ] );
    };
    $c->stash->{'rs'} = undef;
    $c->response->status(200);
}

=head2 _delete

スタッフ、部屋、機材 削除実施

=cut

sub _delete :Private {
    my ( $self, $c, 
         $id,           # 対象ID
       ) = @_;

    my $row = $c->stash->{'M'}->find($id);
    if ( $row->updateflg eq 
            +( $c->sessionid . $c->session->{'updtic'}) ) {
        try {
            $row->update( { 'rmdate'   => \'NOW()', } );
            $c->response->body('<FORM><H1>削除しました</H1></FORM>');
        } catch {
            $c->detach( '_dberror', [ shift ] );
        };
    }
    else {
        $c->response->body =
                    '<FORM><H1>削除できませんでした</H1><BR/>' .
                    '他のシステム管理者が変更した可能性があります</FORM>';
    }
    $c->stash->{'rs'} = undef;
    $c->response->status(200);
}

=head2 loginlog
-----------------------------------------------------------------------------
ログイン履歴表示

=cut

sub loginlog :Local {
    my ( $self, $c ) = @_;
}

=head2 loginlogget
-----------------------------------------------------------------------------
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
        $c->log->debug('loginlog data ' . Dumper( \@data ));
        $c->stash->{'json'} = \@data;
    } catch {
        my $e = shift;
        $c->log->error('timetable_get error ' . localtime() .
            ' dbexp : ' . Dump($e) );
    };
    $c->forward('conkan::View::JSON');
}

=head2 _dberror

DBエラー表示

=cut

sub _dberror :Private {
    my ( $self, $c, $e) = @_; 

    my %dictbl = (
        "'name_UNIQUE'"     => '名前',
        "'roomNo_UNIQUE'"   => '部屋番号',
        "'equipNo_UNIQUE'"  => '機材番号',
        "'regno_UNIQUE'"    => '大会登録番号',
    );

    my @str = split(/\s/, $e);
    if ( $str[6] eq 'Duplicate' ) {
        $c->response->body(
            '<FORM><H1>登録/更新失敗しました</H1><BR/>' .
            '[' . $dictbl{$str[11]} . '] の値 ' .
                        decode('UTF-8', $str[8] ) .
            ' は、既に登録されています' .
            '</FORM>');
    }
    else {
        $c->log->error( localtime() . " dbexp : \n" . Dumper($e) );
        $c->clear_errors();
        my $body = $c->response->body() || Dumper( $e );
        $c->response->body(
            '<FORM>更新失敗<br/><pre>' . $body . '</pre></FORM>');
        $c->response->status(200);
    }
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
