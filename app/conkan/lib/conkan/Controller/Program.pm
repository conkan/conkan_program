package conkan::Controller::Program;
use Moose;
use utf8;
# use Encode;
use JSON;
use String::Random qw/ random_string /;
use Try::Tiny;
use namespace::autoclean;
use Data::Dumper;
use YAML;
use DateTime;
use POSIX qw/ strftime /;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

conkan::Controller::Program - Catalyst Controller

=head1 DESCRIPTION

企画管理

=head1 METHODS

=head2 index

企画一覧にgo
=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->go('program_list');
}

#============================================================================
# 企画登録
=head2 add
-----------------------------------------------------------------------------
企画管理 add  : 企画登録 (Chain外)

=cut
sub add :Local {
    my ( $self, $c ) = @_;
   
    my $nextURLtail = 'list';   # 複数登録時、企画一覧にリダイレクト
    try {
        my $upload = $c->request->upload('jsoninputfile');
        my $jsonf = $upload->tempname;
        local $/ = undef;
        open( my $fh, '<:encoding(utf8)', $jsonf );
        my $json_text   = <$fh>;
        close( $fh );
        my $json_info = from_json( $json_text );
        my $aPginfo;
        if ( ref($json_info) eq 'ARRAY') {
            $aPginfo = $json_info;
        } else {
            $aPginfo = [ $json_info ];
        } 

        my $pgid;
        my $prog_id;
        foreach my $pginfo (@{$aPginfo}) {
            unless ( defined($pginfo->{'WebAPI_VERSION'}) ) {
                # WebAPI 1.0 >>>>
                #   ConkanProgram 2.0.0 Fix時には例外発生
                ( $pgid, $prog_id ) = __PACKAGE__->_WebAPI_1_0( $c, $pginfo );
                next;
            }
            ## PgRegProgramへの登録
            $prog_id = __PACKAGE__->_crtRegProgram( $c, $pginfo );
            ## PgProgramへの登録
            $pgid = __PACKAGE__->_crtProgram( $c, $prog_id, $pginfo );
            ## PgRegCast, PgAllCast, PgCastへの登録
            foreach my $cast (@{$pginfo->{'casts'}}) {
                __PACKAGE__->_crtCast( $c, $prog_id, $pgid, $cast );
            }
            ## PgRegEquipへの登録
            foreach my $equip (@{$pginfo->{'equips'}}) {
                __PACKAGE__->_crtRegEquip( $c, $prog_id, $equip );
            }
        }
        # 1件のみ登録の場合、登録した企画詳細表示にリダイレクト
        unless ( ref($json_info) eq 'ARRAY' ) {
            $nextURLtail = $pgid;
            # 登録者がadminの場合(WebAPI) 企画IDを追加
            if ( $c->user->get('name') eq 'admin' ) {
                $nextURLtail .= '&prog_id=' . $prog_id;
            }
        }
    } catch {
        $c->detach( '_dberror', [ shift ] );
    };
    $c->response->redirect( '/program/' . $nextURLtail );
}

=head2 regcastadd

企画管理 regcastadd  : 予定出演者追加 (Chain外)

=cut

sub regcastadd :Local {
    my ( $self, $c ) = @_;
    my $ckt = [ qw/ regpgid pgid / ];
    my $items = [ qw/ name namef title regno needreq needguest / ];
    my $hval = $c->forward('/program/_trnReq2Hash', [ [ @$ckt, @$items ] ], );

    try{
        my $prog_id = $hval->{'regpgid'};
        my $pgid    = $hval->{'pgid'};
        my $cast    = {
            'pgname'    => $hval->{'name'},
            'pgnamef'   => $hval->{'namef'},
            'pgtitle'   => $hval->{'title'},
            'needreq'   => $hval->{'needreq'},
            'needguest' => $hval->{'needguest'},
        };
        __PACKAGE__->_crtCast( $c, $prog_id, $pgid, $cast );
        $c->forward('/program/_autoProgress',
            [ $hval->{'regpgid'}, 'regcast', $items, undef, $hval ] );
        $c->stash->{'status'} = 'add';
    } catch {
        my $e = shift;
        $c->stash->{'status'} = 'dbfail';
        $c->log->error('regcastadd error ' . localtime() .
            ' dbexp : ' . Dumper($e) );
    };
    $c->log->info( localtime() . ' status:' . $c->stash->{'status'} );
    $c->component('View::JSON')->{expose_stash} = [ 'status', ];
    $c->forward('conkan::View::JSON');
};

=head2 _crtRegProgram

PgRegProgramへの登録

戻り値 $prog_id 企画ID(もとの値またはAI値)

=cut

sub _crtRegProgram :Private {
    my ( $self, $c,
         $pginfo,       # 入力申込情報ハッシュ
       ) = @_;
    my $prog_id;

    my $model = $c->model('ConkanDB::PgRegProgram');
    $prog_id = $pginfo->{'prog_no'};
    if ( $prog_id && $model->find( $prog_id ) ) {
        # 登録済の企画IDが指定されていたら、die
        # (将来的には上書きするかもだけど)
        die 'regpgid duplicate ' . $pginfo->{'pg_name'} . ' [' . $prog_id . ']';
    }

    # 登録情報生成
    # 必須の値が設定済みであることは、prog_registで確認済みなので、
    # ここでは未定義の場合DB初期値を使う
    my $val = {};
    my $p = $pginfo;
    $val->{'regpgid'}    = $p->{'prog_no'}      if defined $p->{'prog_no'};
    $val->{'regdate'}    = $p->{'regdate'}      if defined $p->{'regdate'};
    $val->{'regname'}    = $p->{'p1_name'}      if defined $p->{'p1_name'};
    $val->{'regma'}      = $p->{'email'}        if defined $p->{'email'};
    $val->{'regno'}      = $p->{'reg_num'}      if defined $p->{'reg_num'};
    $val->{'telno'}      = $p->{'tel'}          if defined $p->{'tel'};
    $val->{'faxno'}      = $p->{'fax'}          if defined $p->{'fax'};
    $val->{'celno'}      = $p->{'cellphone'}    if defined $p->{'cellphone'};
    $val->{'name'}       = $p->{'pg_name'}      if defined $p->{'pg_name'};
    $val->{'namef'}      = $p->{'pg_name_f'}    if defined $p->{'pg_name_f'};
    $val->{'type'}       = $p->{'pg_kind'}      if defined $p->{'pg_kind'};
    $val->{'place'}      = $p->{'pg_place'}     if defined $p->{'pg_place'};
    $val->{'layout'}     = $p->{'pg_layout'}    if defined $p->{'pg_layout'};
    $val->{'date'}       = $p->{'pg_time'}      if defined $p->{'pg_time'};
    $val->{'classlen'}   = $p->{'pg_koma'}      if defined $p->{'pg_koma'};
    $val->{'expmaxcnt'}  = $p->{'pg_ninzu'}     if defined $p->{'pg_ninzu'};
    $val->{'content'}    = $p->{'pg_naiyou'}    if defined $p->{'pg_naiyou'};
    $val->{'contentpub'} = $p->{'pg_naiyou_k'}  if defined $p->{'pg_naiyou_k'};
    $val->{'realpub'}    = $p->{'pg_kiroku_kb'} if defined $p->{'pg_kiroku_kb'};
    $val->{'afterpub'}   = $p->{'pg_kiroku_ka'} if defined $p->{'pg_kiroku_ka'};
    $val->{'openpg'}     = $p->{'pg_pggen'}     if defined $p->{'pg_pggen'};
    $val->{'restpg'}     = $p->{'pg_pgu18'}     if defined $p->{'pg_pgu18'};
    $val->{'avoiddup'}   = $p->{'pg_badprog'}   if defined $p->{'pg_badprog'};
    $val->{'experience'} = $p->{'pg_enquete'}   if defined $p->{'pg_enquete'};
    $val->{'comment'}    = $p->{'fc_comment'}   if defined $p->{'fc_comment'};
    # 登録実施
    my $row = $model->create( $val );
    $prog_id = $row->regpgid; # 登録時autoincriment値取得

    return $prog_id;
}

=head2 _crtProgram

PgProgramへの登録

戻り値 $pgid 企画内部ID(AI値)

=cut

sub _crtProgram :Private {
    my ( $self, $c,
         $prog_id,      # 企画ID
         $pginfo,       # 入力申込情報ハッシュ
       ) = @_;
    my $pgid;

    my $model = $c->model('ConkanDB::PgProgram');
    # 登録情報生成
    # 必須の値が設定済みであることは、prog_registで確認済みなので、
    # ここでは未定義の場合DB初期値を使う
    my $val = {};
    my $p = $pginfo;
    $val->{'regpgid'}   = $prog_id;   # 必ず存在する
    $val->{'sname'}     = $pginfo->{'pg_name'} if defined $pginfo->{'pg_name'};
    # 登録実施
    my $row = $model->create( $val );
    $pgid = $row->pgid; # 登録時autoincriment値取得

    return $pgid;
}

=head2 _crtCast

PgRegCast, PgAllCast, PgCastへの登録

戻り値 なし

=cut

sub _crtCast :Private {
    my ( $self, $c,
         $prog_id,      # 企画ID
         $pgid,         # 企画内部ID
         $cast,         # 出演者入力申込情報ハッシュ
       ) = @_;

    my $p = $cast;
    # PgRegCastへの登録
    my $model = $c->model('ConkanDB::PgRegCast');
    # 登録情報生成
    # 必須の値が設定済みであることは、prog_registで確認済みなので、
    # ここでは未定義の場合DB初期値を使う
    my $val = {};
    $val->{'regpgid'}   = $prog_id;   # 必ず存在する
    $val->{'name'}      = $p->{'pgname'}    if defined $p->{'pgname'};
    $val->{'namef'}     = $p->{'pgnamef'}   if defined $p->{'pgnamef'};
    $val->{'title'}     = $p->{'pgtitle'}   if defined $p->{'pgtitle'};
    $val->{'needreq'}   = $p->{'needreq'}   if defined $p->{'needreq'};
    $val->{'needguest'} = $p->{'needguest'} if defined $p->{'needguest'};
    # 登録実施
    my $row = $model->create( $val );
        
    # PgAllCastへの登録
    my $allcastval = {};
    #   名前は、$cast->{'name'}を優先だが、その場合フリガナは未指定
    if ( defined $cast->{'name'} ) {
        $allcastval->{'name'}   = $p->{'name'};
    }
    else {
        $allcastval->{'name'}   = $p->{'pgname'};
        $allcastval->{'namef'}  = $p->{'pgnamef'};
    }
    $allcastval->{'regno'}  = $p->{'entrantregno'}; 
    my $castid = $c->forward('/program/_addAllCast', [ $allcastval ], );

    # PgCastへの登録
    $model = $c->model('ConkanDB::PgCast');
    $val = {};
    $val->{'pgid'}   = $pgid,                  # 必ず存在する
    $val->{'castid'} = $castid,                # 必ず存在する
    $val->{'name'}   = $p->{'pgname'}   if defined $p->{'pgname'};
    $val->{'namef'}  = $p->{'pgnamef'}  if defined $p->{'pgnamef'};
    $val->{'title'}  = $p->{'pgtitle'}  if defined $p->{'pgtitle'};
    $val->{'status'} = $p->{'needreq'}  if defined $p->{'needreq'};
    $row = $model->create( $val );
}

=head2 _addAllCast

PgAllCastへの登録

戻り値: 見つかった/登録した 出演者IDを返却

=cut

sub _addAllCast :Private {
    my ( $self, $c, 
         $cast,     # 追加する出演者情報
                    # name, namef, regno, status, memo, restdate
       ) = @_;

    # 氏名の正規化
    # 空白前後の文字がASCIIの時は、空白を挿入
    # そうでない時は空白を詰める
    my $castname = '';
    my @names = split(/\s/, $cast->{'name'});
    my $maxcnt = scalar(@names);
    for ( my $cnt=0; $cnt< $maxcnt; $cnt++ ) {
        $castname .= $names[$cnt];
        if (   ( substr($castname, -1, 1) =~ /^[\x20-\x7E]+$/ )
            && ( $cnt+1 < $maxcnt )
            && ( substr($names[$cnt+1], 0, 1) =~ /^[\x20-\x7E]+$/ ) ) {
                $castname .= ' '
        }
    }

    my $model = $c->model('ConkanDB::PgAllCast');
    my $cond = {};
    # 無効化されていなくて、名前とフリガナ(フリガナ指定時)が一致する人を探す
    $cond->{'rmdate'} = \'IS NULL';
    $cond->{'name'}   = $castname;        
    $cond->{'namef'}  = $cast->{'namef'} if defined $cast->{'namef'};
    my $row = ($model->search( $cond ) )[0];
    unless ( $row ) {
        # 見つからなければ新規登録
        #   ただし、regnoは登録しない
        my $val = {};
        $val->{'name'}   = $castname;
        $val->{'namef'}  = $cast->{'namef'}  if defined $cast->{'namef'};
        $val->{'status'} = $cast->{'status'} if defined $cast->{'status'};
        $val->{'memo'}   = $cast->{'memo'} if defined $cast->{'memo'};
        $val->{'restdate'} = $cast->{'restdate'} if defined $cast->{'restdate'};

        $row = $model->create( $val );
    }
    return $row->castid(); # 見つかった/登録した 出演者IDを返却
}

=head2 _crtRegEquip

PgRegEquipへの登録

戻り値 なし

=cut

sub _crtRegEquip :Private {
    my ( $self, $c,
         $prog_id,      # 企画ID
         $equip,        # 機材入力申込情報ハッシュ
       ) = @_;

    my $model = $c->model('ConkanDB::PgRegEquip');
    # 登録情報生成
    # 必須の値が設定済みであることは、prog_registで確認済みなので、
    # ここでは未定義の場合DB初期値を使う
    my $val = {};
    my $p = $equip;
    $val->{'regpgid'}   = $prog_id;   # 必ず存在する
    $val->{'name'}      = $p->{'name'}      if defined $p->{'name'};
    $val->{'count'}     = $p->{'count'}     if defined $p->{'count'};
    $val->{'vif'}       = $p->{'vif'}       if defined $p->{'vif'};
    $val->{'aif'}       = $p->{'aif'}       if defined $p->{'aif'};
    $val->{'eif'}       = $p->{'eif'}       if defined $p->{'eif'};
    $val->{'intende'}   = $p->{'intende'}   if defined $p->{'intende'};
    # 登録実施
    my $row = $model->create( $val );
}

#============================================================================
#   WebAPI 1.0 >>>>
#       ConkanProgram 2.0.0 Fix時には削除

=head2 old_WebAPI_1_0

WebAPI 1.0 企画登録

戻り値 ( $pgid : 企画内部ID $prog_id : 企画ID )

 =cut old_WebAPI_1_0

sub _WebAPI_1_0 :Private {
    my ( $self, $c,
         $pginfo,       # 入力申込情報ハッシュ
       ) = @_;

    my $pgid;
    my $regcnf;
    my $hval;

    # $c->config->{Regist}->{RegProgram}の内容を元にpginfoの内容を登録
    ## regPgIDが未設定の場合autoincにより決定
    ## {RegProgram}のitem数は1つであり、loopmax定義はない
    $regcnf = $c->config->{'Regist'}->{'RegProgram'};
    $hval = __PACKAGE__->ParseRegist(
                    $pginfo, $regcnf->{'items'}->[0], undef, ''  );
    if ( ref($hval) eq 'HASH' ) {
        my $regpgid = $hval->{'regpgid'};
        if ( $regpgid &&
             $c->model('ConkanDB::' . $regcnf->{'schema'})->find( $regpgid ) ) {
            die 'regpgid duplicate ' . $hval->{'name'} . ' [' . $regpgid . ']';
            $hval->{'regpgid'} = undef;
        }
        my $row =
            $c->model('ConkanDB::' . $regcnf->{'schema'})->create( $hval );
 $c->ug('>>>> add reg_program:name [' . $hval->{'name'} . ']');
 $c->ug('>>>> add reg_program:regpgid [' . $row->regpgid . ']');
        ## $pginfo->{企画ID}の値を再設定 (autoinc対応)
        $pginfo->{'企画ID'} = $row->regpgid;
    }
    elsif ( $hval ) {
        die 'input Format Error /or/ regist.yml Format Error';
    }
    
    # $c->config->{Regist}->{Program}の内容を元にpginfoの内容を登録
    ## {Program}のitem数は1つであり、loopmax定義はない
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
            foreach my $cnt (1..$item->{loopmax}+1) {
                # 申込者本人が出演する場合があるので、+1
                $hval = __PACKAGE__->ParseRegist(
                                $pginfo, $item, undef, $cnt );
                if ( ref($hval) eq 'HASH' ) {
                    __PACKAGE__->_addCast( $c, $hval, $pgid );
                }
                elsif ( $hval ) {
                    die 'input Format Error /or/ regist.yml Format Error';
                }
            }
        }
        else {
            $hval = __PACKAGE__->ParseRegist( $pginfo, $item, undef, '');
            if ( ref($hval) eq 'HASH' ) {
                __PACKAGE__->_addCast( $c, $hval, $pgid );
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
    return ( $pgid, $pginfo->{'企画ID'} );
}

=head2 ParseRegist

WebAPI 1.0
Regist情報に基づく申込情報(pginfo)パース

戻り値 パース後のハッシュ(1レコード分)

 =cut old_WebAPI_1_0

sub ParseRegist :Private {
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
        if ( defined( $val ) && ( $val eq $regitem->{validval} ) ) {
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

=head2 _addCast

出演者登録実行

出演者受付に加え、全出演者、出演者管理 にも登録
DBエラー発生時は、例外発生するので呼び出し側で処理すること

 =cut old_WebAPI_1_0

sub _addCast :Private {
    my ( $self,
         $c,            # コンテキスト
         $hval,         # 登録する情報
         $pgid,         # 企画内部ID
       ) = @_;
                    
    # 出演者受付登録
    my $val = {
        'regpgid'   => $hval->{'regpgid'},
        'name'      => $hval->{'name'},
        'namef'     => $hval->{'namef'},
        'title'     => $hval->{'title'},
        'needreq'   => $hval->{'needreq'},
        'needguest' => $hval->{'needguest'},
    };
    $c->model('ConkanDB::PgRegCast')->create( $val );

    # 全出演者登録(名前とふりがな か regno が一致するものがない場合
    my $acrow;
    if (  ( exists($hval->{'entrantregno'} ) && $hval->{'entrantregno'} )
        ||( exists($hval->{'regno'}        ) && $hval->{'regno'}        ) ) {
        $acrow = ( $c->model('ConkanDB::PgAllCast')->search(
            { 
                'rmdate'  => \'IS NULL',
                -nest     => [
                    'regno' => $hval->{'entrantregno'},
                    'regno' => $hval->{'regno'},
                ],
            }
        ))[0];
    }
    else {
        $acrow = ( $c->model('ConkanDB::PgAllCast')->search(
            {
              'rmdate' => \'IS NULL',
              'name'  => $hval->{'name'},
              'namef' => $hval->{'namef'},
            }
        ))[0];
    }
    unless ( $acrow ) {
        my $aval = {
                'name'   => $hval->{'name'},
                'namef'  => $hval->{'namef'},
                'status' => '',
                'regno'  => $hval->{'regno'},
                };
        if ( exists($hval->{'entrantregno'} ) && $hval->{'entrantregno'} ) {
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
        'title'  => $hval->{'title'},
        'status' => ( $hval->{'entrantregno'} ) ? '申込者'
                                                : $hval->{'needreq'},
        },
    );
}

#   <<< WebAPI 1.0
#       ConkanProgram 2.0.0 Fix時には削除
#============================================================================

=cut

#============================================================================
# 表示処理 (Chain)
=head2 program
-----------------------------------------------------------------------------
企画管理 program_base  : Chainの起点

=cut

sub program_base : Chained('') : PathPart('program') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

#============================================================================
#   企画一覧
=head2 program/list 

企画管理 program_list  : 企画一覧

=cut

sub program_list : Chained('program_base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
}

=head2 program/listget_a program/listget_r 

企画管理 program_listget  : 企画一覧取得 _a:全企画 _r:担当企画

=cut

sub program_listget_a : Chained('program_base') : PathPart('listget_a') : Args(0) {
    my ( $self, $c ) = @_;
    $c->detach( 'program_listget', [ 1 ] );
}

sub program_listget_r : Chained('program_base') : PathPart('listget_r') : Args(0) {
    my ( $self, $c ) = @_;
    $c->detach( 'program_listget', [ 0 ] );
}

sub program_listget : Private {
    my ( $self, $c,
         $getall,      # 全企画を取得するか
       ) = @_;

    try {
        my $searchcond = +( $getall
            ? {}
            : { 'me.staffid' => $c->user->get('staffid') } );
        my $pgmlist = [ $c->model('ConkanDB::PgProgram')->search(
                    $searchcond,
                    {
                        'prefetch' => [ 'regpgid', 'staffid' ],
                        'order_by' => { '-asc' => [ 'me.regpgid', 'me.subno'] },
                    }
                )
            ];
        my $prglist = [ $c->model('ConkanDB::PgProgress')->search(
                    { },
                    {
                        'group_by' => [ 'regpgid' ],
                        'select'   => [ 'regpgid', { MAX => 'repdatetime'} ], 
                        'as'       => [ 'regpgid', 'lastprg' ],
                    }
                )
            ];
        my $lpdts = {};
        foreach my $prg ( @$prglist ) {
            $lpdts->{$prg->get_column('regpgid')} = $prg->get_column('lastprg');
        }

        my @list = ();
        foreach my $pgm ( @$pgmlist ) {
            my $regpgid = $pgm->regpgid->regpgid();
            my $sid = $pgm->staffid;
            my $lpdt = $lpdts->{$regpgid};
            push @list, {
                'regpgid'       => $regpgid,
                'pgid'          => $pgm->pgid(),
                'sname'         => $pgm->sname(),
                'subno'         => $pgm->subno(),
                'name'          => $pgm->regpgid->name(),
                'staff'         => +( $sid ? $sid->name() : '' ),
                'status'        => $pgm->status(),
                'contentpub'    => $pgm->regpgid->contentpub(),
                'repdatetime'   => +( $lpdt ? $lpdt : '' ),
            };
        }
        $c->stash->{'json'} = \@list;
        $c->stash->{'status'} = 'ok';
    } catch {
        my $e = shift;
        $c->log->error('program/listget error ' . localtime() .
            ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->log->info( localtime() . ' status:' . $c->stash->{'status'} );
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

#============================================================================
#   企画詳細
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
    # 企画開始終了時刻変換
    $c->forward('/program/_trnSEtime', [ $c->stash->{'Program'}, ], );
    $c->stash->{'pgid'}     = $pgid;
    $c->stash->{'regpgid'}  = $regpgid;
    $c->stash->{'subno'}    = $c->stash->{'Program'}->subno();
    $c->stash->{'self_li_id'} = $c->stash->{'self_li_id'} || 'program_list';
}

=head2 program/*/

企画管理program_detail  : 企画情報詳細表示

=cut

sub program_detail : Chained('program_show') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    my $regpgid = $c->stash->{'regpgid'};
    $c->stash->{'RegProgram'} =
        $c->model('ConkanDB::PgRegProgram')->find($regpgid);
}

#============================================================================
#   企画詳細(受付分)処理
=head2 program/*/regprogram
---------------------------------------------
企画管理 pgup_regprog   : 企画更新(受付分)

=cut
sub pgup_regprog : Chained('program_show') : PathPart('regprogram') : Args(0) {
    my ( $self, $c ) = @_;
    my $up_items = [ qw/
                    regpgid name namef
                    regma regname experience regno telno faxno celno
                    type place layout date classlen expmaxcnt
                    content contentpub realpub afterpub openpg restpg
                    avoiddup comment
                    / ];
    my $regpgid = $c->stash->{'regpgid'};
    my $pgid    = $c->stash->{'pgid'};
    $c->stash->{'M'} = $c->model('ConkanDB::PgRegProgram');
    try {
        my $rowprof = $c->stash->{'M'}->find($regpgid);
        if ( $c->request->method eq 'GET' ) {
            $c->stash->{'json'} = {
                pgid        => $pgid,
                regpgid     => $rowprof->regpgid(),
                subno       => $c->stash->{'subno'},
                name        => $rowprof->name(),
                namef       => $rowprof->namef(),
                regma       => $rowprof->regma(),
                regname     => $rowprof->regname(),
                regdate     => $rowprof->regdate()->strftime('%F'),
                experience  => $rowprof->experience(),
                regno       => $rowprof->regno(),
                telno       => $rowprof->telno(),
                faxno       => $rowprof->faxno(),
                celno       => $rowprof->celno(),
                type        => $rowprof->type(),
                place       => $rowprof->place(),
                layout      => $rowprof->layout(),
                date        => $rowprof->date(),
                classlen    => $rowprof->classlen(),
                expmaxcnt   => $rowprof->expmaxcnt(),
                content     => $rowprof->content(),
                contentpub  => $rowprof->contentpub(),
                realpub     => $rowprof->realpub(),
                afterpub    => $rowprof->afterpub(),
                openpg      => $rowprof->openpg(),
                restpg      => $rowprof->restpg(),
                avoiddup    => $rowprof->avoiddup(),
                comment     => $rowprof->comment(),
            };
        }
        $c->forward( '_pgupdate', [ 'regprogram', $rowprof, $up_items ] );
    } catch {
        my $e = shift;
        $c->log->error('program/' . $pgid . ' /regprogram error '
            . localtime() . ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->log->info( localtime() . ' status:' . $c->stash->{'status'} );
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

#============================================================================
#   企画詳細(管理分)処理
=head2 program/*/program
---------------------------------------------
企画管理 pgup_program  : 企画更新(管理分)
企画更新(管理分) は、 timetable/* を使用する

=cut

#============================================================================
#   予定出演者処理
=head2 program/*/regcastlist
---------------------------------------------
企画管理 pgdt_regcastlist  : 予定出演者リスト取得

=cut

sub pgdt_regcastlist : Chained('program_show') : PathPart('regcastlist') : Args(0) {
    my ( $self, $c ) = @_;
    my $pgid = $c->stash->{'pgid'};
    my $regpgid = $c->stash->{'regpgid'};
    try {
        my $rows = [ $c->model('ConkanDB::PgRegCast')->search(
                        { regpgid => $regpgid },
                        { 'order_by' => { '-asc' => 'id' }, } ) ];
        my @list = ();
        foreach my $row ( @$rows ) {
            my $regcast = {
                'name'      => $row->name(),
                'namef'     => $row->namef(),
                'title'     => $row->title(),
                'needreq'   => $row->needreq(),
                'needguest' => $row->needguest(),
            };
            push @list, $regcast;
        }
        $c->stash->{'json'} = \@list;
        $c->stash->{'status'} = 'ok';
    } catch {
        my $e = shift;
        $c->log->error('program/' . $pgid . ' /regcastlist/ error '
            . localtime() . ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->log->info( localtime() . ' status:' . $c->stash->{'status'} );
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

#============================================================================
#   決定出演者処理
=head2 program/*/castlist
---------------------------------------------
企画管理 pgdt_castlist  : 決定出演者リスト取得

=cut

sub pgdt_castlist : Chained('program_show') : PathPart('castlist') : Args(0) {
    my ( $self, $c ) = @_;
    my $pgid = $c->stash->{'pgid'};
    my $regpgid = $c->stash->{'regpgid'};
    try {
        my $rows = [ $c->model('ConkanDB::PgCast')->search(
                        { pgid => $pgid },
                        {
                            'prefetch' => [ 'castid' ],
                            'order_by' => { '-asc' => 'id' },
                        }
                    ) ];
        my @list = ();
        foreach my $row ( @$rows ) {
            my $cast = {
                'id'        => $row->id(),
                'status'    => $row->status(),
                'memo'      => $row->memo(),
                'pname'     => $row->name(),
                'title'     => $row->title(),
                'regno'     => $row->castid->regno(),
                'name'      => $row->castid->name(),
                'constatus' => $row->castid->status(),
            };
            push @list, $cast;
        }
        $c->stash->{'json'} = \@list;
        $c->stash->{'status'} = 'ok';
    } catch {
        my $e = shift;
        $c->log->error('program/' . $pgid . ' /regcastlist/ error '
            . localtime() . ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->log->info( localtime() . ' status:' . $c->stash->{'status'} );
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 program/*/cast/*
---------------------------------------------
企画管理 pgup_casttop  : 決定出演者追加/更新/削除 起点

=cut
sub pgup_casttop : Chained('program_show') : PathPart('cast') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $c->stash->{'id'} = $id;
    $c->stash->{'M'} = $c->model('ConkanDB::PgCast');
}

=head2 program/*/cast/*/

企画管理 pgup_cast  : 決定出演者追加/更新

=cut
sub pgup_cast : Chained('pgup_casttop') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    my $up_items = [ qw/
                    castid status memo name namef title
                    / ];
    my $pgid = $c->stash->{'pgid'};
    my $id = $c->stash->{'id'};
    try {
        my $rowprof = undef;
        if ( $id == 0 ) {   # 追加
            push @$up_items, qw/pgid/;
        }
        else {              # 更新
            $rowprof = $c->stash->{'M'}->find( $id,
                { 'prefetch' => [ 'pgid', 'castid' ], } );
            unless ( $rowprof ) {
                # 更新対象が削除済み
                $c->stash->{'status'} = 'noexist';
                $c->component('View::JSON')->{expose_stash} = [ 'status' ];
                $c->forward('conkan::View::JSON');
                return;
            }
        }
        if ( $c->request->method eq 'GET' ) {
            $c->stash->{'json'} = {};
            $c->stash->{'json'}->{'pgid'} = $pgid;
            if ( $rowprof ) {
                $c->stash->{'json'}->{'castid'} = $rowprof->castid->castid();
                $c->stash->{'json'}->{'status'} = $rowprof->status();
                $c->stash->{'json'}->{'memo'}   = $rowprof->memo();
                $c->stash->{'json'}->{'name'}   = $rowprof->name();
                $c->stash->{'json'}->{'namef'}  = $rowprof->namef();
                $c->stash->{'json'}->{'title'}  = $rowprof->title();
            }
            $c->stash->{'json'}->{'castlist'} = [ 
                map +{
                    'id' => $_->castid,
                    'val' => +( $_->regno ? $_->regno : '' ) . ' ' . $_->name
                }, $c->model('ConkanDB::PgAllCast')->all()
            ];
            my $M = $c->model('ConkanDB::PgSystemConf');
            $c->stash->{'json'}->{'statlist'}  = [
                map +{ 'id' => $_, 'val' => $_ },
                   @{from_json( $M->find('cast_status_vals')->pg_conf_value() )}
            ];
        }
        $c->forward( '_pgupdate', [ 'equip', $rowprof, $up_items ] );
    } catch {
        my $e = shift;
        $c->log->error('program/' . $pgid . ' /cast/ ' . $id . '/ error '
            . localtime() . ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->log->info( localtime() . ' status:' . $c->stash->{'status'} );
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 program/*/cast/*/del

企画管理 pgup_castdel  : 決定出演者削除

=cut
sub pgup_castdel : Chained('pgup_casttop') : PathPart('del') : Args(0) {
    my ( $self, $c ) = @_;
    my $up_items = [ qw/
                    castid name
                    / ];

    # あり得ないが念のため
    if ( ( $c->request->method eq 'GET' ) || ( $c->stash->{'id'} == 0 ) ) {
        $c->detach(
            '/program/' . $c->stash->{'pgid'} . '/cast/' . $c->stash->{'id'}
        );
    }

    $c->forward( '_pgdelete', [ 'cast', $up_items ] );
    $c->component('View::JSON')->{expose_stash} = [ 'status' ];
    $c->forward('conkan::View::JSON');
}

#============================================================================
#   機材要望処理
=head2 program/*/regequiplist
---------------------------------------------
企画管理 program_regequiplist  : 機材要望リスト取得

=cut
sub program_regequiplist : Chained('program_show') : PathPart('regequiplist') : Args(0) {
    my ( $self, $c ) = @_;
    my $regpgid = $c->stash->{'regpgid'};
    my $pgid = $c->stash->{'pgid'};
    try {
        my @list = ();
        my $rows = [ $c->model('ConkanDB::PgRegEquip')->search(
                            { regpgid => $regpgid },
                            { 'order_by' => { '-asc' => 'id' }, }
                   ) ];
        foreach my $row ( @$rows ) {
            my $regequip = {
                'id'        => $row->id(),
                'name'      => $row->name(),
                'count'     => $row->count(),
                'vif'       => $row->vif(),
                'aif'       => $row->aif(),
                'eif'       => $row->eif(),
                'intende'   => $row->intende(),
            };
            push @list, $regequip;
        }
        $c->stash->{'json'} = \@list;
        $c->stash->{'status'} = 'ok';
    } catch {
        my $e = shift;
        $c->log->error('program/' . $pgid . '/regequiplist error ' . localtime() .
            ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->log->info( localtime() . ' status:' . $c->stash->{'status'} );
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 program/*/regequip/*
---------------------------------------------
企画管理 pgup_regequiptop  : 機材要望追加/更新/削除 起点

=cut
sub pgup_regequiptop : Chained('program_show') : PathPart('regequip') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $c->stash->{'id'} = $id;
    $c->stash->{'M'} = $c->model('ConkanDB::PgRegEquip');
}

=head2 program/*/regequip/*/

企画管理 pgup_regequip  : 機材要望追加/更新

=cut
sub pgup_regequip : Chained('pgup_regequiptop') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    my $up_items = [ qw/
                    name count vif aif eif intende
                    / ];
    my $pgid = $c->stash->{'pgid'};
    my $regpgid = $c->stash->{'regpgid'};
    my $id = $c->stash->{'id'};
    try {
        my $rowprof = undef;
        if ( $id == 0 ) {   # 追加
            push @$up_items, qw/regpgid/;
        }
        else {              # 更新
            $rowprof = $c->stash->{'M'}->find( $id );
            unless ( $rowprof ) {
                # 更新対象が削除済み
                $c->stash->{'status'} = 'noexist';
                $c->component('View::JSON')->{expose_stash} = [ 'status' ];
                $c->forward('conkan::View::JSON');
                return;
            }
        }
        if ( $c->request->method eq 'GET' ) {
            $c->stash->{'json'} = {};
            $c->stash->{'json'}->{'regpgid'} = $regpgid;
            if ( $rowprof ) {
                $c->stash->{'json'}->{'name'}    = $rowprof->name();
                $c->stash->{'json'}->{'count'}   = $rowprof->count();
                $c->stash->{'json'}->{'vif'}     = $rowprof->vif();
                $c->stash->{'json'}->{'aif'}     = $rowprof->aif();
                $c->stash->{'json'}->{'eif'}     = $rowprof->eif();
                $c->stash->{'json'}->{'intende'} = $rowprof->intende();
            }
            # 提供機材要望情報
            my $defregstr = $c->model('ConkanDB::PgSystemConf')
                            ->find('def_regEquip')->pg_conf_value();
            my $pdefReg = from_json( $defregstr );
            my @regEquiplist = map { keys(%$_) } @$pdefReg;
            push ( @regEquiplist, ( 'その他要望機材', 'その他持ち込み機材' ) );
            my %defRegEquip  = map { each(%$_) } @$pdefReg;
            $c->stash->{'json'}->{'defRegEquip'} = \%defRegEquip;
            $c->stash->{'json'}->{'regEquiplist'} = \@regEquiplist;
        }
        $c->forward( '_pgupdate', [ 'regequip', $rowprof, $up_items ] );
    } catch {
        my $e = shift;
        $c->log->error('program/' . $pgid . ' /regequip/ ' . $id . '/ error '
            . localtime() . ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->log->info( localtime() . ' status:' . $c->stash->{'status'} );
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 program/*/regequip/*/del

企画管理 pgup_regequipdel  : 機材要望削除

=cut
sub pgup_regequipdel : Chained('pgup_regequiptop') : PathPart('del') : Args(0) {
    my ( $self, $c ) = @_;

    my $up_items = [ qw/
                    id
                    / ];

    my $pgid = $c->stash->{'pgid'};
    my $regpgid = $c->stash->{'regpgid'};
    my $id   = $c->stash->{'id'};

    # あり得ないが念のため
    if ( ( $c->request->method eq 'GET' ) || ( $c->stash->{'id'} == 0 ) ) {
        $c->detach(
            '/program/' . $c->stash->{'pgid'} . '/regequip/' . $c->stash->{'id'}
        );
    }

    $c->forward( '_pgdelete', [ 'regequip', $up_items ] );
    $c->component('View::JSON')->{expose_stash} = [ 'status' ];
    $c->forward('conkan::View::JSON');
}

#============================================================================
#   決定機材処理
=head2 program/*/equiplist
---------------------------------------------
企画管理 program_equiplist  : 決定機材リスト取得

=cut
sub program_equiplist : Chained('program_show') : PathPart('equiplist') : Args(0) {
    my ( $self, $c ) = @_;
    my $pgid = $c->stash->{'pgid'};
    try {
        # 場所コード設定済みか確認
        my @list = ();
        my $prog = $c->model('ConkanDB::PgProgram')->find($pgid);
        my $roomid = ( $prog->roomid ) ? $prog->roomid->roomid() : undef; 
        if ( $roomid ) {
            # 場所固定の機材をリストアップ
            my $rows =
                [ $c->model('ConkanDB::PgAllEquip')->search(
                            {
                                'roomid' => $roomid,
                                'rmdate' => \'IS NULL',
                            },
                            {
                                'order_by' => { '-asc' => 'equipno' },
                            }
                        ) ];
            foreach my $row ( @$rows ) {
                my $equip = {
                    'id'        => '',
                    'name'      => $row->name(),
                    'equipno'   => $row->equipno(),
                    'spec'      => $row->spec(),
                };
                push @list, $equip;
            }
        }
        my $rows =
            [ $c->model('ConkanDB::PgEquip')->search(
                        { pgid => $pgid },
                        {
                            'prefetch' => [ 'equipid' ],
                            'order_by' => { '-asc' => 'id' },
                        }
                    ) ];
        foreach my $row ( @$rows ) {
            my $equip = {
                'id'        => $row->id(),
                'name'      => $row->equipid->name(),
                'equipno'   => $row->equipid->equipno(),
                'spec'      => $row->equipid->spec(),
                'vif'       => $row->vif(),
                'aif'       => $row->aif(),
                'eif'       => $row->eif(),
                'intende'   => $row->intende(),
            };
            push @list, $equip;
        }
        $c->stash->{'json'} = \@list;
        $c->stash->{'status'} = 'ok';
    } catch {
        my $e = shift;
        $c->log->error('program/' . $pgid . '/equiplist error ' . localtime() .
            ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->log->info( localtime() . ' status:' . $c->stash->{'status'} );
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 program/*/equip/*
---------------------------------------------
企画管理 pgup_equiptop  : 決定機材追加/更新/削除 起点

=cut
sub pgup_equiptop : Chained('program_show') : PathPart('equip') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $c->stash->{'id'} = $id;
    $c->stash->{'M'} = $c->model('ConkanDB::PgEquip');
}

=head2 program/*/equip/*/

企画管理 pgup_equip  : 決定機材追加/更新

=cut
sub pgup_equip : Chained('pgup_equiptop') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;
    my $up_items = [ qw/
                    equipid vif aif eif intende
                    / ];
    my $pgid = $c->stash->{'pgid'};
    my $id = $c->stash->{'id'};
    try {
        my $rowprof = undef;
        if ( $id == 0 ) {   # 追加
            push @$up_items, qw/pgid/;
        }
        else {              # 更新
            $rowprof = $c->stash->{'M'}->find( $id,
                { 'prefetch' => [ 'pgid', 'equipid' ], } );
            unless ( $rowprof ) {
                # 更新対象が削除済み
                $c->stash->{'status'} = 'noexist';
                $c->component('View::JSON')->{expose_stash} = [ 'status' ];
                $c->forward('conkan::View::JSON');
                return;
            }
        }
        if ( $c->request->method eq 'GET' ) {
            $c->stash->{'json'} = {};
            $c->stash->{'json'}->{'pgid'} = $pgid;
            if ( $rowprof ) {
                $c->stash->{'json'}->{'name'} = $rowprof->equipid->name();
                $c->stash->{'json'}->{'equipid'} = $rowprof->equipid->equipid();
                $c->stash->{'json'}->{'vif'} = $rowprof->vif();
                $c->stash->{'json'}->{'aif'} = $rowprof->aif();
                $c->stash->{'json'}->{'eif'} = $rowprof->eif();
                $c->stash->{'json'}->{'intende'} = $rowprof->intende();
            }
            my $equips = [ $c->model('ConkanDB::PgAllEquip')->search(
                        { 
                            'roomid' => \'IS NULL',
                            'rmdate' => \'IS NULL'
                        },
                        { 'order_by' => { '-asc' => 'equipno' } }
                    ) ];
            my @equiplist;
            my %equipdata;
            my %bringid;
            for my $equip (@$equips) {
                my $equipid = $equip->equipid();
                my $equipno = $equip->equipno();
                push (@equiplist, {
                        'id'  => $equipid,
                        'val' => $equip->name() . '(' . $equipno . ')',
                    }
                );
                $equipdata{$equipid} = {
                    'spec'      => $equip->spec(),
                    'comment'   => $equip->comment(),
                };
                $bringid{$equipid} = 'bring-AV' if ( $equipno eq 'bring-AV' );
                $bringid{$equipid} = 'bring-PC' if ( $equipno eq 'bring-PC' );
            }
            $c->stash->{'json'}->{'equiplist'} = \@equiplist;
            $c->stash->{'json'}->{'equipdata'} = \%equipdata;
            $c->stash->{'json'}->{'bringid'}   = \%bringid;
        }
        $c->forward( '_pgupdate', [ 'equip', $rowprof, $up_items ] );
    } catch {
        my $e = shift;
        $c->log->error('program/' . $pgid . ' /equip/ ' . $id . '/ error '
            . localtime() . ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->log->info( localtime() . ' status:' . $c->stash->{'status'} );
    $c->component('View::JSON')->{expose_stash} = [ 'json', 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 program/*/equip/*/del

企画管理 pgup_equipdel  : 決定機材削除

=cut
sub pgup_equipdel : Chained('pgup_equiptop') : PathPart('del') : Args(0) {
    my ( $self, $c ) = @_;

    my $up_items = [ qw/
                    equipid
                    / ];

    my $pgid = $c->stash->{'pgid'};
    my $id   = $c->stash->{'id'};

    # あり得ないが念のため
    if ( ( $c->request->method eq 'GET' ) || ( $c->stash->{'id'} == 0 ) ) {
        $c->detach(
            '/program/' . $c->stash->{'pgid'} . '/equip/' . $c->stash->{'id'}
        );
    }

    $c->forward( '_pgdelete', [ 'equip', $up_items ] );
    $c->component('View::JSON')->{expose_stash} = [ 'status' ];
    $c->forward('conkan::View::JSON');
}

#============================================================================
#       企画更新共通
=head2 _pgupdate
---------------------------------------------
企画更新実施

=cut

sub _pgupdate :Private {
    my ( $self, $c, 
         $target,       # 更新対象
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
            # 企画開始終了時刻変換
            $c->forward('/program/_trnSEtime', [ $c->stash->{'rs'}, ], );
            $c->stash->{'status'} = 'ok';
        }
        else {
            my $value = $c->forward('/program/_trnReq2Hash', [ $up_items ], );
            my $regpgid = $c->stash->{'regpgid'};
            if ( defined( $rowprof ) ) {
                # 更新実施
                if ( $rowprof->updateflg eq 
                        +( $c->sessionid . $c->session->{'updtic'}) ) {
                        my $newregpgid = $value->{'regpgid'};
                        if ( defined($newregpgid) &&
                             ( $regpgid != $newregpgid ) ) {
$c->log->debug('>>>> regpgid: ' . $regpgid . ' -> ' . $newregpgid);
                            # 企画番号更新時特殊チェック
                            my $cannot = $c->model('ConkanDB::PgRegProgram')
                                    ->find($newregpgid);
                            if ( $cannot ) {
                                $c->stash->{'status'} = 'iddupfail';
                                return;
                            }
                        }
                        $c->forward('/program/_autoProgress',
                            [ $regpgid, $target, $up_items,
                              $rowprof, $value ] );
                        $rowprof->update( $value ); 
                        $c->stash->{'status'} = 'update';
                }
                else {
                    $c->log->info('updateflg: db: ' . $rowprof->updateflg);
                    $c->log->info('updateflg: cu: ' . $c->sessionid);
                    $c->log->info('                   '
                                                    . $c->session->{'updtic'} );
                    $c->stash->{'status'} = 'fail';
                }
            }
            else {
                # 追加
                $c->forward('/program/_autoProgress',
                            [ $regpgid, $target, $up_items, undef, $value ] );
                $c->stash->{'M'}->create( $value ); 
                $c->stash->{'status'} = 'add';
            }
        }
    } catch {
        my $e = shift;
        $c->log->error( '_pgupdate error ' . localtime()
            . ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
}

=head2 _pgdelete
---------------------------------------------
企画削除実施

=cut

sub _pgdelete :Private {
    my ( $self, $c,
         $target,       # 削除対象
         $up_items,     # 対象列名配列
    ) = @_;

    my $pgid = $c->stash->{'pgid'};
    my $id   = $c->stash->{'id'};
    try {
        my $rowprof = $c->stash->{'M'}->find( $id );
        my $regpgid = $c->stash->{'regpgid'};

        if ( $rowprof ) {
            if ( $rowprof->updateflg eq 
                    +( $c->sessionid . $c->session->{'updtic'}) ) {
                # 削除実施
                $c->forward('/program/_autoProgress',
                    [ $regpgid, $target, $up_items, $rowprof, undef ] );
                $rowprof->delete(); 
                $c->stash->{'status'} = 'del';
            }
            else {
                $c->stash->{'rs'} = undef;
                $c->stash->{'status'} = 'delfail';
            }
        }
        else {
            # 削除対象が削除済み
            $c->stash->{'status'} = 'noexist';
        }
    } catch {
        my $e = shift;
        $c->log->error( '_pgdelete error ' . localtime()
            . ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->log->info( localtime() .  sprintf( ' _pgdelete %s id[%d] status:%s',
                                        $target, $id, $c->stash->{'status'} ) );
}

#============================================================================
#   進捗報告処理
=head2 progress
-----------------------------------------------------------------------------
企画管理 progress  : 進捗登録 (Chain外)

進捗登録はTimeTableからも実施するため、Chain外

=cut

sub progress :Local {
    my ( $self, $c ) = @_;

    my $param   = $c->request->body_params;
    my $pgid    = $param->{'pgid'};
    my $regpgid = $param->{'regpgid'};

    my $str = $param->{'progress'};
    try {
        $c->forward('/program/_crProgress', [ $regpgid, $str, ], ) if ( $str );
        $c->stash->{'status'} = 'nodlgok';
    } catch {
        my $e = shift;
        $c->log->error('program/progress error ' . localtime() .
            ' dbexp : ' . Dumper($e) );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->log->info( localtime() . ' status:' . $c->stash->{'status'} );
    $c->component('View::JSON')->{expose_stash} = [ 'status' ];
    $c->forward('conkan::View::JSON');
}

=head2 program/*/progress/*/*
---------------------------------------------
企画管理 program_progressget   : 進捗報告取得

=cut
sub program_progressget : Chained('program_show') : PathPart('progress') : Args(2) {
    my ( $self, $c, $pageno, $pagesize ) = @_;
    my $regpgid = $c->stash->{'regpgid'};
    try {
        my $prgcnt = $c->model('ConkanDB::PgProgress')->search(
                        { regpgid => $regpgid },
                    )->count;
        my $prglist = [ $c->model('ConkanDB::PgProgress')->search(
                        { regpgid => $regpgid },
                        {
                            'prefetch' => [ 'staffid' ],
                            'order_by' => { '-desc' => 'repdatetime' },
                            'rows'      => $pagesize,
                            'page'      => $pageno,
                        }
                    )
                ];
        my @list = ();
        foreach my $prg ( @$prglist ) {
            my $rdt = $prg->repdatetime();
            push @list, {
                'repdatetime'   => +( defined( $rdt ) ? $rdt->strftime('%F %T') : '' ),
                'tname'         => $prg->staffid->tname(),
                'report'        => $prg->report(),
            };
        }
        $c->stash->{'totalItems'} = $prgcnt;
        $c->stash->{'json'} = \@list;
        $c->stash->{'status'} = 'ok';
    } catch {
        my $e = shift;
        $c->log->error(
            'program/' . $regpgid . '/progressget/' . $pageno . '/' . $pagesize
            . ' error ' . localtime() . ' dbexp : ' . Dumper($e)
        );
        $c->stash->{'status'} = 'dbfail';
    };
    $c->log->info( localtime() . ' status:' . $c->stash->{'status'} );
    $c->component('View::JSON')->{expose_stash} = [
        'json', 'status', 'totalItems' ];
    $c->forward('conkan::View::JSON');
}

#============================================================================
# 企画複製分割
=head2 cpysep
-----------------------------------------------------------------------------
企画管理 cpysep  : 企画複製分割 (Chain外)

=cut

sub cpysep :Local {
    my ( $self, $c ) = @_;

    my $param   = $c->request->body_params;
    my $regpgid = $param->{'regpgid'};
    my $pgid    = $param->{'pgid'};
    my $action  = $param->{'cpysep_act'};
    my $svregpgid = $regpgid;

    my $row;
    my $hval;

    try {
        if ( $action eq 'cpy' ) { # 複製
            # 企画受付複製
            $row = $c->model('ConkanDB::PgRegProgram')->find($regpgid);
            $hval = { $row->get_columns };
            delete $hval->{'regpgid'};
            $row = $c->model('ConkanDB::PgRegProgram')->create( $hval );
            $regpgid = $row->regpgid();
            # 企画管理複製
            $row = $c->model('ConkanDB::PgProgram')->find($pgid);
            $hval = { $row->get_columns };
            delete $hval->{'pgid'};
            $hval->{'regpgid'} = $regpgid;
            $hval->{'subno'} = 0;
            $row = $c->model('ConkanDB::PgProgram')->create( $hval );
            $pgid = $row->pgid();
            # 出演者受付複製
            $row = [ $c->model('ConkanDB::PgRegCast')->search(
                                        { 'regpgid' => $svregpgid } ) ];
            foreach my $r ( @$row ) {
                $hval = { $r->get_columns };
                delete $hval->{'id'};
                $hval->{'regpgid'} = $regpgid;
                $c->model('ConkanDB::PgRegCast')->create( $hval );
            }
            # 機材受付複製
            $row = [ $c->model('ConkanDB::PgRegEquip')->search(
                                        { 'regpgid' => $svregpgid } ) ];
            foreach my $r ( @$row ) {
                $hval = { $r->get_columns };
                delete $hval->{'id'};
                $hval->{'regpgid'} = $regpgid;
                $c->model('ConkanDB::PgRegEquip')->create( $hval );
            }
            try {
                my $prstr = 'copy to ' . $regpgid;
                $c->forward('/program/_crProgress', [ $svregpgid, $prstr, ], );
                $prstr = 'copy from ' . $svregpgid;
                $c->forward('/program/_crProgress', [ $regpgid, $prstr, ], );
            } catch {
                # 自動進捗登録時の失敗は、エラーログのみ残す
                $c->response->status(200);
                my $e = shift;
                $c->log->error('_autoProgress error ' . localtime() .
                    ' dbexp : ' . Dumper($e) );
            };
        }
        else {  # 分割
            # 企画管理のみ複製
            $row = $c->model('ConkanDB::PgProgram')->find($pgid);
            $hval = { $row->get_columns };
            delete $hval->{'pgid'};
            $row = [ $c->model('ConkanDB::PgProgram')->search(
                    { 'regpgid' => $regpgid },
                    {
                        'select'   => [ { MAX => 'subno'} ], 
                        'as'       => [ 'maxsubno' ],
                    } ) ]->[0];
$c->log->debug('>>>> maxsubno:[' . $row->get_column('maxsubno') . ']');
            $hval->{'subno'} = $row->get_column('maxsubno') + 1;
            $row = $c->model('ConkanDB::PgProgram')->create( $hval );
            $pgid = $row->pgid();
            try {
                my $prstr = 'split to ' . $hval->{'subno'};
                $c->forward('/program/_crProgress', [ $svregpgid, $prstr, ], );
            } catch {
                # 自動進捗登録時の失敗は、エラーログのみ残す
                $c->response->status(200);
                my $e = shift;
                $c->log->error('_autoProgress error ' . localtime() .
                    ' dbexp : ' . Dumper($e) );
            };
        }
    } catch {
        $c->detach( '_dberror', [ shift ] );
    };
    $c->response->redirect('/program/' .  $pgid );
}

#============================================================================
# 企画情報ダウンロード
=head2 csvdownload
-----------------------------------------------------------------------------
企画管理 csvdownload  : 企画情報CSVダウンロード (Chain外)

=cut

sub csvdownload :Local {
    my ( $self, $c ) = @_;
    try {
       my $condval = $c->request->body_params->{'pg_status'};
       my $get_status = ( ref($condval) eq 'ARRAY' ) ? $condval : [ $condval ];
       push ( @$get_status, \'IS NULL' )
           if exists( $c->request->body_params->{'pg_null_stat'} );
       my $outext = exists($c->request->body_params->{'pg_outext'}) ? 1 : 0;
       # 指定の実行ステータスで抽出
       my $rows =
           [ $c->model('ConkanDB::PgProgram')->search(
               {
                   'status'   => $get_status,
               },
               {
                   'prefetch' => [ 'regpgid', 'roomid' ],
                   'order_by' => { '-asc' => [ 'me.regpgid', 'me.subno' ] },
               } )
           ];
   $c->log->debug('>>> ' . 'program cnt : ' . scalar(@$rows) );
       my @data = (
           [
               '企画ID',
               'サブNO',
               '正式企画名',
               '正式企画名フリガナ',
               '企画短縮名',
               '企画名',
               '内容',
               '内容事前公開可否',
               '一般公開可否',
               '未成年参加可否',
               '備考',
               '実行ステータス',
               '実行ステータス補足',
               '実施日時1',
               '実施日時2',
               '部屋番号',
               '実施場所',
               '企画紹介文',
               '出演者企画ネーム',
               '出演者肩書',
               '出演ステータス',
               '...',
           ]
       );
       foreach my $row ( @$rows ) {
           # 実施日付は YYYY/MM/DD、開始終了時刻は HH:MM (いずれも0サフィックス)
           my $datmHash = $c->forward('/program/_trnDateTime4csv', [ $row, ], );
           my @pfmdatetime  = undef;
           if ( $datmHash->{'dates'} ) {
               for ( my $idx=0; $idx<scalar(@{$datmHash->{'dates'}}); $idx++ ) {
                   $pfmdatetime[$idx] = $datmHash->{'dates'}->[$idx] . ' '
                                      . $datmHash->{'stms'}->[$idx] . '-'
                                      . $datmHash->{'etms'}->[$idx];
               }
           }
           # 決定出演者取得
           my $castrows =
               [ $c->model('ConkanDB::PgCast')->search(
                           { pgid => $row->pgid() },
                           {
                               'prefetch' => [ 'castid' ],
                               'order_by' => { '-asc' => 'id' },
                           }
                       ) ];
           my @casts = ();
           foreach my $castrow ( @$castrows ) {
               my $pname = $castrow->name() || $castrow->castid->name();
               push ( @casts, $pname );            # 企画ネーム
               push ( @casts, $castrow->title() ); # 肩書
               push ( @casts, $castrow->status()); # 出演ステータス
           }
           # 実施場所情報
           my $roomno = undef;
           my $roomname = undef;
           if ( $row->roomid() ) {
               $roomno = $row->roomid->roomno();
               $roomname = $row->roomid->name();
           }
   
           my $pgname  = $row->sname() || $row->regpgid->name();
           my $content = $outext ? $row->regpgid->content() : '';
           my $comment = $outext ? $row->regpgid->comment() : '';
           my $progres = $outext ? $row->progressprp() : '';
           push ( @data, [
               $row->regpgid->regpgid(),    # 企画ID,
               $row->subno(),               # サブNO,
               $row->regpgid->name(),       # 正式企画名,
               $row->regpgid->namef(),      # 正式企画名フリガナ,
               $row->sname(),               # 企画短縮名,
               $pgname,                     # 企画名,
               $content,                    # 内容,
               $row->regpgid->contentpub(), # 内容事前公開可否,
               $row->regpgid->openpg(),     # 一般公開可否,
               $row->regpgid->restpg(),     # 未成年参加可否,
               $comment,                    # 備考,
               $row->status(),              # 実行ステータス,
               $row->memo(),                # 実行ステータス補足,
               $pfmdatetime[0],             # 実施日時1,
               $pfmdatetime[1],             # 実施日時2,
               $roomno,                     # 部屋番号,
               $roomname,                   # 実施場所,
               $progres,                    # 企画紹介文,
               @casts,                      # 決定出演者,
           ]);
       }
   
       $c->stash->{'csv'} = \@data;
       $c->response->header( 'Content-Disposition' =>
           'attachment; filename=' .
               strftime("%Y%m%d%H%M%S", localtime()) . '_program.csv' );
   
       $c->forward('conkan::View::Download::CSV');
    } catch {
        $c->detach( '_dberror', [ shift ] );
    };
}

#============================================================================
#   内部ユーティリティ
=head2 _dberror

DBエラー表示

=cut

sub _dberror :Private {
    my ( $self, $c, $e) = @_; 
    my $msg = ref($e) ? Dumper($e) : $e;
    $c->log->error( 'DB Error' . localtime() . ' Program:dbexp : ' . $msg );
    $c->clear_errors();
    my $body = $c->response->body() || $msg;
    $c->response->body('<FORM>DBエラー<br/><pre>' . $body . '</pre></FORM>');
    $c->response->status(200);
}

=head2 _trnDateTime4csv

CSV出力用企画開始/終了時刻変換

戻り値 : $dates: 日付配列参照
       : $stms : 開始時刻配列参照
       : $etms : 終了時刻配列参照
=cut

sub _trnDateTime4csv :Private {
    my ( $self, $c, 
         $trg,      # 変換対象ハッシュ
       ) = @_;
    my $dates = undef;
    my $stms  = undef;
    my $etms  = undef;
    if ( $trg->date1() ) {
        my @date  = split('T', $trg->date1());
        $date[0] =~ s[-][/]g;
        @date = split('/', $date[0]);
        $c->forward('/program/_trnSEtime', [ $trg, ], );
        $dates->[0] = sprintf('%04d/%02d/%02d', @date);
        $stms->[0]  = ( exists($trg->{'shour1'}) && exists($trg->{'smin1'}) )
                ? sprintf('%02d:%02d', $trg->{'shour1'}, $trg->{'smin1'})
                : '';
        $etms->[0]  = ( exists($trg->{'ehour1'}) && exists($trg->{'emin1'}) )
                ? sprintf('%02d:%02d', $trg->{'ehour1'}, $trg->{'emin1'})
                : '';
    }
    if ( $trg->date2() ) {
        my @date  = split('T', $trg->date2());
        $date[0] =~ s[-][/]g;
        @date = split('/', $date[0]);
        $dates->[1] = sprintf('%04d/%02d/%02d', @date);
        $stms->[1]  = ( exists($trg->{'shour2'}) && exists($trg->{'smin2'}) )
                ? sprintf('%02d:%02d', $trg->{'shour2'}, $trg->{'smin2'})
                : '';
        $etms->[1]  = ( exists($trg->{'ehour2'}) && exists($trg->{'emin2'}) )
                ? sprintf('%02d:%02d', $trg->{'ehour2'}, $trg->{'emin2'})
                : '';
    }
    my $result = {
        'dates' => $dates,
        'stms'  => $stms,
        'etms'  => $etms,
    };
    return $result;
}

=head2 TimeArgTrn

開始終了時刻変換テーブル

=cut

my %TimeArgTrn = (
    'stime1' => [ 'shour1', 'smin1' ],
    'etime1' => [ 'ehour1', 'emin1' ],
    'stime2' => [ 'shour2', 'smin2' ],
    'etime2' => [ 'ehour2', 'emin2' ],
);

my %DateArgTrn = (
    'date1' => [ 'year1', 'month1', 'day1' ],
    'date2' => [ 'year2', 'month2', 'day2' ],
);

=head2 _trnSEtime

企画開始/終了時刻変換

=cut

sub _trnSEtime :Private {
    my ( $self, $c, 
         $trgHash,      # 変換対象ハッシュ
       ) = @_;

    foreach my $item (keys(%TimeArgTrn)) {
        my $wkval = eval( '$trgHash->' . $item );
        next unless defined($wkval);
        # 開始終了時刻を分解して時と分にわける
        my @wk = split( /:/, $wkval );
        if ( scalar( @wk ) >= 2 ) {
            $trgHash->{$TimeArgTrn{$item}->[0]} =
                sprintf('%02d', $wk[0] + $c->config->{time_origin});
            $trgHash->{$TimeArgTrn{$item}->[1]} =
                sprintf('%02d', $wk[1]);
        }
    }
}

=head2 _trnReq2Hash

POSTパラメータをDB更新用ハッシュに変換

戻り値: DB更新用ハッシュ

=cut

sub _trnReq2Hash :Private {
    my ( $self, $c, 
         $up_items,     # 対象列名配列
       ) = @_;

    my $value = {};
    for my $item (@{$up_items}) {
        if ( exists( $TimeArgTrn{$item} ) ) {
            my $hour = $c->request->body_params->{$TimeArgTrn{$item}->[0]};
            my $min  = $c->request->body_params->{$TimeArgTrn{$item}->[1]};
            $hour =~ s/\s+$// if defined($hour);
            $min  =~ s/\s+$// if defined($min);
            if ( defined($hour) && ( $hour ne '' ) ) {
                $hour -= $c->config->{time_origin};
                $min = 0 unless $min;
                $value->{$item} = sprintf( '%02d:%02d', $hour, $min );
            }
            else {
                $value->{$item} = undef;
            }
        }
        else {
            if ( defined($c->request->body_params->{$item}) &&
                 ( $c->request->body_params->{$item} ne '' ) ) {
                $value->{$item} = $c->request->body_params->{$item};
            }
            else {
                $value->{$item} = undef;
            }
        }
        if ( defined( $value->{$item} ) ) {
            $value->{$item} =~ s/\s+$//;
            $value->{$item} = undef if ( $value->{$item} eq '' );
        }
    }
    return $value;
}

=head2 _autoProgress

更新内容自動進捗登録

進捗文字列の順序を揃えるため、項目名配列を受け取る
(ハッシュのキーの順序は不定のため)

=cut

sub _autoProgress :Private {
    my ( $self, $c, 
         $regpgid,  # 対象企画番号
         $target,   # 更新対象
         $itemkeys, # 項目名配列
         $row,      # 対象レコード(更新前)
         $value,    # 更新用ハッシュ
       ) = @_;

    my %mask_items = (  # 値をマスクする項目名(利便性のためハッシュ)
        'regma' => 1,
        'telno' => 1,
        'faxno' => 1,
        'celno' => 1,
    );

    try {
        my $progstrlog = '';
        my $progstr = '';
        if ( defined( $row ) ) {
            if ( defined( $value ) ) { # 更新
                my $addstrlog = '';
                my $addstr    = '';
                for my $key (@{$itemkeys}) {
                    my $rowval = $row->get_column($key);
                    my $val = $value->{$key};
                    if ( defined( $rowval ) ) {
                        if ( exists( $TimeArgTrn{$key} ) ) {
                            my @times = split(':', $row->get_column($key));
                            $rowval = sprintf( '%02d:%02d', @times );
                        }
                        elsif ( exists( $DateArgTrn{$key} ) ) {
                            $rowval =~ s[-][/]g;
                        }
                    }
                    else {
                        $rowval = '';
                    }
                    if ( defined( $val ) && ($rowval ne $val ) ) {
                        my $maskval = exists($mask_items{$key}) ? 'xxxxxx'
                                                                : $val;
                        if ( $addstr eq '' ) {
                            $addstrlog = 'Update ';
                            $addstr    = 'Update ';
                        }
                        $addstrlog .= $key . ' change to ' . $val . ' ';
                        $addstr    .= $key . ' change to ' . $maskval . ' ';
                    }
                }
                $progstrlog .= $addstrlog;
                $progstr    .= $addstr;
            }
            else { # 削除
                my $addstr = 'Delete ';
                for my $key (@{$itemkeys}) {
                    $addstr .= $key . ':' . $row->get_column($key) . ' ';
                }
                $progstrlog .= $addstr;
                $progstr    .= $addstr;
            }
        }
        else { # 生成
            my $addstrlog = 'Create ';
            my $addstr    = 'Create ';
            for my $key (@{$itemkeys}) {
                my $val = exists($value->{$key}) ? $value->{$key} || '' : '';
                my $maskval = exists($mask_items{$key}) ? 'xxxxxx' : $val;
                $addstrlog .= $key . ':' . $val . ' ';
                $addstr    .= $key . ':' . $maskval . ' ';
            }
            $progstrlog .= $addstrlog;
            $progstr    .= $addstr;
        }
        if ( $progstr ne '' ) {
            $c->log->info( localtime()  . ' _autoProgress regpgid:' . $regpgid
                                        . ' progstr:' . $progstrlog );
            my $repstr = '[Auto Progress] ' . $target . ' ' . $progstr;
            $c->forward('/program/_crProgress', [ $regpgid, $repstr, ], );
        }
    } catch {
        # 自動進捗登録時の失敗は、エラーログのみ残す
        $c->response->status(200);
        my $e = shift;
        $c->log->error('_autoProgress error ' . localtime() .
            ' dbexp : ' . Dumper($e) );
    };
}

=head2 _crProgress

進捗登録実施

=cut

sub _crProgress :Private {
    my ( $self, $c, 
         $regpgid,  # 対象企画番号
         $progstr,  # 報告内容
       ) = @_;

    $c->model('ConkanDB::PgProgress')->create(
        {
            'regpgid'       => $regpgid,
            'staffid'       => $c->user->get('staffid'),
            'repdatetime'   => \'NOW()',
            'report'        => $progstr,
        },
    );
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
