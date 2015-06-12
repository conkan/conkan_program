package conkan::Controller::Program;
use Moose;
use utf8;
use Encode;
use JSON;
use String::Random qw/ random_string /;
use Try::Tiny;
use DateTime;
use namespace::autoclean;
use Data::Dumper;
use YAML;

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

=head2 add
-----------------------------------------------------------------------------
企画管理 add  : 企画登録 (Chain外)

=cut
sub add :Local {
    my ( $self, $c ) = @_;
   
    try {
        my $upload = $c->request->upload('jsoninputfile');
        my $jsonf = $upload->tempname;
        local $/ = undef;
        open( my $fh, '<:encoding(utf8)', $jsonf );
        my $json_text   = <$fh>;
        close( $fh );
        my $pginfo = from_json( $json_text );

        my $regcnf;
        my $hval;
        my $pgid;

        # $c->config->{Regist}->{RegProgram}の内容を元にpginfoの内容を登録
        ## regPgIDが未設定の場合autoincにより決定
        ## {RegProgram}のitem数は1つであり、loopmax定義はない
        $regcnf = $c->config->{Regist}->{RegProgram};
        $hval = __PACKAGE__->ParseRegist(
                        $pginfo, $regcnf->{items}->[0], undef, ''  );
        if ( ref($hval) eq 'HASH' ) {
            my $row =
                $c->model('ConkanDB::' . $regcnf->{schema})->create( $hval );
            ## $pginfo->{企画ID}の値を再設定 (autoinc対応)
            $pginfo->{'企画ID'} = $row->regpgid;
        }
        elsif ( $hval ) {
            die 'input Format Error /or/ regist.yml Format Error';
        }

        # $c->config->{Regist}->{Program}の内容を元にpginfoの内容を登録
        ## {RegProgram}のitem数は1つであり、loopmax定義はない
        $regcnf = $c->config->{Regist}->{Program};
        $hval = __PACKAGE__->ParseRegist(
                        $pginfo, $regcnf->{items}->[0], undef, ''  );
        if ( ref($hval) eq 'HASH' ) {
            my $row =
                $c->model('ConkanDB::' . $regcnf->{schema})->create( $hval );
            ## 企画内部IDの値を設定 (登録時にautoincで決定)
            $pgid = $row->pgid;
        }
        elsif ( $hval ) {
            die 'input Format Error /or/ regist.yml Format Error';
        }

        # $c->config->{Regist}->{RegCast}の内容を元にpginfoの内容を登録
        ## 同時にPgAllCastにも登録する
        ## {RegCast}のitem数は複数あり、さらにloopmax定義がある
        $regcnf = $c->config->{Regist}->{RegCast};
        foreach my $item (@{$regcnf->{items}}) {
            if ( defined($item->{loopmax}) ) {
                foreach my $cnt (1..$item->{loopmax}) {
                    $hval = __PACKAGE__->ParseRegist(
                                    $pginfo, $item, undef, $cnt );
                    if ( ref($hval) eq 'HASH' ) {
                        __PACKAGE__->AddCast( $c, $hval, $pgid );
                    }
                    elsif ( $hval ) {
                        die 'input Format Error /or/ regist.yml Format Error';
                    }
                }
            }
            else {
                $hval = __PACKAGE__->ParseRegist( $pginfo, $item, undef, '');
                if ( ref($hval) eq 'HASH' ) {
                    __PACKAGE__->AddCast( $c, $hval, $pgid );
                }
                elsif ( $hval ) {
                    die 'input Format Error /or/ regist.yml Format Error';
                }
            }
        }

        # $c->config->{Regist}->{RegEquip}の内容を元にpginfoの内容をDBに登録
        ## {RegEquip}のitem数は複数あるが、loopmax定義はない
        $regcnf = $c->config->{Regist}->{RegEquip};
        foreach my $item (@{$regcnf->{items}}) {
            $hval = __PACKAGE__->ParseRegist( $pginfo, $item, undef, '');
            if ( ref($hval) eq 'HASH' ) {
                $c->model('ConkanDB::' . $regcnf->{schema})->create( $hval )
            }
            elsif ( $hval ) {
                die 'input Format Error /or/ regist.yml Format Error';
            }
        }
    } catch {
        $c->detach( '_dberror', [ shift ] );
        return;
    };
    $c->response->redirect('/program/list');
}

=head2 ParseRegist

Regist情報に基づく申込情報(pginfo)パース

戻り値 パース後のハッシュ(1レコード分)

=cut

sub ParseRegist {
    my ( $self,
         $pginfo,       # 入力申込情報ハッシュ
                        #   key: hashkeyの値
         $regitem,      # 登録定義情報ハッシュ配列(1レコード分)
                        #   key: 'hashkey' ['column'] 
                        #        ['validval'] ['addcnf'] ['repcnf'] ['loopmax']
         $hval,         # パース後のハッシュ undefの時、新たに確保
         $cnt           # 同一ハッシュ値繰り返しサフィックス
       ) = @_;

    my $val = $pginfo->{$regitem->{hashkey}}
           || $pginfo->{$regitem->{hashkey} . $cnt};

    if ( $regitem->{validval} ) {
        if ( $val eq $regitem->{validval} ) {
            $val = $regitem->{hashkey};
        }
        else {
            undef $val;
        }
    }
    return $hval unless ($val);

    if ( $regitem->{repcnf} ) {
        $val = $pginfo->{$regitem->{repcnf}->{hashkey}}
            if ( $val eq $regitem->{repcnf}->{repval} )
    }
    if ( $regitem->{column} ) {
        $hval = {} unless defined($hval);
        $hval->{$regitem->{column}} = $val;
    }
    if ( $regitem->{addcnf} ) {
        foreach my $item (@{$regitem->{addcnf}}) {
            $hval = __PACKAGE__->ParseRegist( $pginfo, $item, $hval, $cnt );
        }
    }        
    return $hval;
}

=head2 AddCast

出演者登録

出演者受付に加え、全出演者、出演者管理 にも登録

=cut

sub AddCast {
    my ( $self,
         $c,            # コンテキスト
         $hval,         # 登録する情報
         $pgid,         # 企画内部ID
       ) = @_;
                    
    try {
        # 出演者受付登録
        $c->model('ConkanDB::PgRegCast')->create( $hval );

        # 全出演者登録
        my $acrow = $c->model('ConkanDB::PgAllCast')->find( $hval->{'name'},
                { 'key'  => 'name_UNIQUE', },
            );
        unless ( $acrow ) {
            my $aval = {
                    'name'   => $hval->{'name'},
                    'namef'  => $hval->{'namef'},
                    'status' => '',
                    };
            if ( $hval->{'entrantregno'} =~ /^\d+$/ ) {
                $aval->{'regno'} = $hval->{'entrantregno'};
            }
            $acrow = $c->model('ConkanDB::PgAllCast')->create( $aval );
        }
        my $castid = $acrow->castid();

        # 出演者管理登録
        $c->model('ConkanDB::PgCast')->create(
            {
            'pgid'   => $pgid,
            'castid' => $castid,
            'name'   => $hval->{'name'},
            'namef'  => $hval->{'namef'},
            'status' => ( $hval->{'entrantregno'} ) ? '申込者'
                                                    : $hval->{'needreq'},
            },
        );
    } catch {
        $c->detach( '_dberror', [ shift ] );
    };
}

=head2 progress
-----------------------------------------------------------------------------
企画管理 progress  : 進捗登録 (Chain外)

=cut

sub progress :Local {
    my ( $self, $c ) = @_;

    my $param   = $c->request->body_params;
    my $pgid    = $param->{'pgid'};
    my $regpgid = $param->{'regpgid'};

    if ( $param->{'progress'} ) {
        try {
            $c->model('ConkanDB::PgProgress')->create(
                {
                'regpgid'       => $regpgid,
                'staffid'       => $c->user->get('staffid'),
                'repdatetime'   => \'NOW()',
                'report'        => $param->{'progress'},
                },
            );
        } catch {
            $c->detach( '_dberror', [ shift ] );
            return;
        };
    }
    $c->response->redirect('/program/' . $pgid );
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
                'prefetch' => [ 'regpgid', 'staffid' ],
                'order_by' => { '-asc' => [ 'me.regpgid', 'me.subno'] },
            } )
        ];
    my $prglist =
        [ $c->model('ConkanDB::PgProgress')->search( { },
            {
                'group_by' => [ 'regpgid' ],
                'select'   => [ 'regpgid', { MAX => 'repdatetime'} ], 
                'as'       => [ 'regpgid', 'lastprg' ],
            } )
        ];
    my $lastprgs = {};
    foreach my $prg ( @$prglist ) {
        $lastprgs->{$prg->get_column('regpgid')} = $prg->get_column('lastprg');
    }

    my @list = ();
    foreach my $pgm ( @$pgmlist ) {
        my $regpgid = $pgm->regpgid->regpgid();
        push @list, {
            'regpgid'       => $regpgid,
            'pgid'          => $pgm->pgid(),
            'subno'         => $pgm->subno(),
            'name'          => $pgm->regpgid->name(),
            'staff'         => $pgm->staffid ? $pgm->staffid->name() : '',
            'status'        => $pgm->status(),
            'repdatetime'   => $lastprgs->{$regpgid},
        };
    }
    $c->stash->{'list'} = \@list;
}

=head2 program/*

企画管理 program_show  : 詳細表示起点

=cut

sub program_show : Chained('program_base') :PathPart('') :CaptureArgs(1) {
    my ( $self, $c, $pgid ) = @_;
    $c->stash->{'Program'}  =
        $c->model('ConkanDB::PgProgram')->find($pgid, 
                        {
                            'prefetch' => [ 'regpgid', 'staffid', 'roomid' ],
                        },
                    );
    my $regpgid = $c->stash->{'Program'}->regpgid->regpgid();
    $c->stash->{'RegProgram'} =
        $c->model('ConkanDB::PgRegProgram')->find($regpgid);
    $c->stash->{'RegCasts'} =
        [ $c->model('ConkanDB::PgRegCast')->search(
                        { regpgid => $regpgid },
                        {
                            'order_by' => { '-asc' => 'id' },
                        }
                    ) ];
    $c->stash->{'RegEquips'} =
        [ $c->model('ConkanDB::PgRegEquip')->search(
                        { regpgid => $regpgid },
                        {
                            'order_by' => { '-asc' => 'id' },
                        }
                    ) ];
    $c->stash->{'Progress'}  =
        [ $c->model('ConkanDB::PgProgress')->search(
                        { regpgid => $regpgid },
                        {
                            'prefetch' => [ 'staffid' ],
                            'order_by' => { '-desc' => 'repdatetime' },
                        }
                    ) ];
    $c->stash->{'Casts'} =
        [ $c->model('ConkanDB::PgCast')->search(
                        { pgid => $pgid },
                        {
                            'prefetch' => [ 'castid' ],
                            'order_by' => { '-asc' => 'id' },
                        }
                    ) ];
    $c->stash->{'Equips'} =
        [ $c->model('ConkanDB::PgEquip')->search(
                        { pgid => $pgid },
                        {
                            'prefetch' => [ 'equipid' ],
                            'order_by' => { '-asc' => 'id' },
                        }
                    ) ];
    $c->stash->{'pgid'}     = $pgid;
    $c->stash->{'regpgid'}  = $regpgid;
    $c->stash->{'subno'}    = $c->stash->{'Program'}->subno();
    $c->stash->{'pgname'}   = $c->stash->{'RegProgram'}->name();
};

=head2 program/*

企画管理program_detail  : 企画情報更新表示

=cut

sub program_detail : Chained('program_show') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
}

=head2 program/*/regprogram

企画管理 pgup_regprog   : 企画更新(受付分)

=cut
sub pgup_regprog : Chained('program_show') : PathPart('regprogram') : Args(0) {
    my ( $self, $c ) = @_;
    my $up_items = [ qw/
                    name namef regma regno telno faxno celno
                    type place layout date classlen expmaxcnt
                    content contentpub realpub afterpub avoiddup
                    experience comment
                    / ];
    my $regpgid = $c->stash->{'regpgid'};
    $c->stash->{'M'} = $c->model('ConkanDB::PgRegProgram');
    my $rowprof;
    try {
        $rowprof = $c->stash->{'M'}->find($regpgid);
    } catch {
        $c->detach( '_dberror', [ shift ] );
        return;
    };
    $c->detach( '_pgupdate', [ $rowprof, $up_items ] );
}

=head2 program/*/program

企画管理 pgup_program  : 企画更新(管理分)

=cut
sub pgup_program : Chained('program_show') : PathPart('program') : Args(0) {
    my ( $self, $c ) = @_;
    my $up_items = [ qw/
                    staffid status memo
                    date1 stime1 etime1 date2 stime2 etime2
                    roomid layerno progressprp
                    / ];
    my $pgid = $c->stash->{'pgid'};
    $c->stash->{'M'} = $c->model('ConkanDB::PgProgram');
    my $rowprof;
    try {
        $rowprof = $c->stash->{'M'}->find( $pgid,
                     { 'prefetch' => [ 'regpgid', 'staffid', 'roomid' ], } );
        if ( $c->request->method eq 'GET' ) {
            $c->stash->{'stafflist'} = [
                { 'id' => '', 'val' => '' },
                map +{ 'id' => $_->staffid(), 'val' => $_->tname() }, 
                    $c->model('ConkanDB::PgStaff')->search(
                        { staffid => { '!=' =>  1 } } )
                ];
            # staffid == 1 は adminなので排除
            $c->stash->{'roomlist'}  = [
                { 'id' => '', 'val' => '' },
                map +{ 'id'  => $_->roomid(),
                       'val' => $_->name() . '(' . $_->roomno() . ')' },
                    $c->model('ConkanDB::PgRoom')->all()
                ];
            my $conf  = {};
            my $M = $c->model('ConkanDB::PgSystemConf');
            $conf->{'dates'}   = [
                { 'id' => '', 'val' => '' },
                map +{ 'id' => $_, 'val' => $_ },
                    @{from_json( $M->find('dates')->pg_conf_value() )}
                ];
            $conf->{'s_times'} = [
                { 'id' => '', 'val' => '' },
                map +{ 'id' => $_, 'val' => $_ },
                   ( @{from_json( $M->find('start_times1')->pg_conf_value() )},
                     @{from_json( $M->find('start_times2')->pg_conf_value() )} )
                ];
            $conf->{'e_times'} = [
                { 'id' => '', 'val' => '' },
                map +{ 'id' => $_, 'val' => $_ },
                    ( @{from_json( $M->find('end_times1')->pg_conf_value() )},
                      @{from_json( $M->find('end_times2')->pg_conf_value() )} )
                ];
            $conf->{'status'}  = [
                { 'id' => '', 'val' => '' },
                map +{ 'id' => $_, 'val' => $_ },
                    @{from_json( $M->find('pg_status_vals')->pg_conf_value() )}
                ];
            $conf->{'nos'}     = [
                  map +{ 'id' => $_, 'val' => $_ }, qw/ 0 1 2 3 4 /
                ];
            $c->stash->{'conf'}  = $conf;
        }
    } catch {
        $c->detach( '_dberror', [ shift ] );
        return;
    };
    $c->detach( '_pgupdate', [ $rowprof, $up_items ] );
}

=head2 program/*/equip/*

企画管理 pgup_equip  : 決定機材追加/更新

=cut
sub pgup_equip : Chained('program_show') : PathPart('equip') : Args(1) {
    my ( $self, $c, $id ) = @_;

    my $up_items = [ qw/
                    equipid
                    / ];
    $c->stash->{'M'} = $c->model('ConkanDB::PgEquip');
    my $rowprof = undef;
    try {
        if ( $id == 0 ) {   # 追加
            push @$up_items, qw/pgid/;
        }
        else {              # 更新
            $rowprof = $c->stash->{'M'}->find( $id,
                { 'prefetch' => [ 'pgid', 'equipid' ], } );
        }
        if ( $c->request->method eq 'GET' ) {
            $c->stash->{'equiplist'} = [ 
                { 'id' => '', 'val' => '' },
                map +{ 'id' => $_->equipid,
                       'val' => $_->name . '(' . $_->equipno . ')' }, 
                    $c->model('ConkanDB::PgAllEquip')->all()
                ];
            $c->stash->{'nos'}     = [
                map +{ 'id' => $_, 'val' => $_ }, qw/ 0 1 2 3 4 5 6 7 8 9/
                ];
        }
    } catch {
        $c->detach( '_dberror', [ shift ] );
        return;
    };
    $c->detach( '_pgupdate', [ $rowprof, $up_items ] );
}

=head2 program/*/cast/*

企画管理 pgup_cast  : 決定出演者追加/更新

=cut
sub pgup_cast : Chained('program_show') : PathPart('cast') : Args(1) {
    my ( $self, $c, $id ) = @_;
    my $up_items = [ qw/
                    castid status memo name namef title
                    / ];
    $c->stash->{'M'} = $c->model('ConkanDB::PgCast');
    my $rowprof = undef;
    try {
        if ( $id == 0 ) {   # 追加
            push @$up_items, qw/pgid/;
        }
        else {              # 更新
            $rowprof = $c->stash->{'M'}->find( $id,
                { 'prefetch' => [ 'pgid', 'castid' ], } )
        }
        if ( $c->request->method eq 'GET' ) {
            $c->stash->{'castlist'} = [ 
                { 'id' => '', 'val' => '' },
                map +{ 'id' => $_->castid, 'val' => $_->name }, 
                    $c->model('ConkanDB::PgAllCast')->all()
                ];
            my $M = $c->model('ConkanDB::PgSystemConf');
            $c->stash->{'statlist'}  = [
                { 'id' => '', 'val' => '' },
                map +{ 'id' => $_, 'val' => $_ },
                   @{from_json( $M->find('cast_status_vals')->pg_conf_value() )}
                ];
        }
    } catch {
        $c->detach( '_dberror', [ shift ] );
        return;
    };
    $c->detach( '_pgupdate', [ $rowprof, $up_items ] );
}

=head2 _pgupdate

企画更新実施

=cut

sub _pgupdate :Private {
    my ( $self, $c, 
         $rowprof,      # 対象データベース行
         $up_items,     # 対象列名配列
       ) = @_;

    try {
        if ( $c->request->method eq 'GET' ) {
            # 更新表示
            if ( defined( $rowprof ) ) {
                $c->session->{'updtic'} = time;
                $rowprof->update( { 
                    'updateflg' =>  $c->sessionid . $c->session->{'updtic'}
                } );
            }
            $c->stash->{'rs'} = $rowprof;
        }
        else {
            my $value = {};
            for my $item (@{$up_items}) {
                $value->{$item} = $c->request->body_params->{$item};
                $value->{$item} =~ s/\s+$// if defined($value->{$item});
                delete $value->{$item} if ( $value->{$item} eq '' );
            }
            if ( defined( $rowprof ) ) {
                # 更新実施
                if ( $rowprof->updateflg eq 
                        +( $c->sessionid . $c->session->{'updtic'}) ) {
                        $rowprof->update( $value ); 
                        $c->response->body(
                            '<FORM><H1>更新しました</H1></FORM>');
                }
                else {
                    $c->stash->{'rs'} = undef;
                    $c->response->body =
                        '<FORM><H1>更新できませんでした</H1><BR/>' .
                        '他スタッフが変更した可能性があります</FORM>';
                }
            }
            else {
                # 追加
                $c->stash->{'M'}->create( $value ); 
                $c->response->body('<FORM><H1>追加しました</H1></FORM>');
            }
            $c->stash->{'rs'} = undef;
            $c->response->status(200);
        }
    } catch {
        $c->detach( '_dberror', [ shift ] );
    };
}

=head2 _dberror

DBエラー表示

=cut

sub _dberror :Private {
    my ( $self, $c, $e) = @_; 
    $c->log->error('>>> ' . localtime() . ' dbexp : ' . Dump($e) );
    $c->clear_errors();
    my $body = $c->response->body() || Dump( $e );
    $c->response->body('<FORM>更新失敗<br/><pre>' . $body . '</pre></FORM>');
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
