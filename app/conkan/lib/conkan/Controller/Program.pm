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
   
    my $upload = $c->request->upload('jsoninputfile');
    my $jsonf = $upload->tempname;
    local $/ = undef;
    open( my $fh, '<:encoding(utf8)', $jsonf );
    my $json_text   = <$fh>;
    close( $fh );
    my $pginfo = from_json( $json_text );

    my $regcnf;
    my $hval;

    # $c->config->{Regist}->{RegProgram}の内容にもとづいて、pginfoの内容を登録
    ## PgIDが未設定の場合autoincするため
    ## {RegProgram}のitem数は1つであり、loopmax定義はない
    $regcnf = $c->config->{Regist}->{RegProgram};
    $hval = __PACKAGE__->ParseRegist( $pginfo, $regcnf->{items}->[0], undef, ''  );
    if ( ref($hval) eq 'HASH' ) {
        my $row = $c->model('ConkanDB::' . $regcnf->{schema})->create( $hval );
        ## $pginfo->{企画ID}の値を再設定 (autoinc対応)
        $pginfo->{'企画ID'} = $row->pgid;
    }

    # $c->config->{Regist}->{RegCast}の内容にもとづいて、pginfoの内容を登録
    ## 同時にPgAllCastにも登録するため
    ## {RegCast}のみloopmax定義がある
    $regcnf = $c->config->{Regist}->{RegCast};
    foreach my $item (@{$regcnf->{items}}) {
        if ( defined($item->{loopmax}) ) {
            foreach my $cnt (1..$item->{loopmax}) {
                $hval = __PACKAGE__->ParseRegist( $pginfo, $item, undef, $cnt );
                if ( ref($hval) eq 'HASH' ) {
                    __PACKAGE__->AddCast( $c, $hval );
                }
            }
        }
        else {
            $hval = __PACKAGE__->ParseRegist( $pginfo, $item, undef, '');
            if ( ref($hval) eq 'HASH' ) {
                __PACKAGE__->AddCast( $c, $hval );
            }
        }
    }

    # $c->config->{Regist}の内容に基づいて pginfoの内容をDBに登録
    ## {RegCast}以外にはloopmax定義はない
    my @kinds = keys( %{$c->config->{Regist}} );
    foreach my $kind (@kinds) {
        next if ($kind eq 'RegProgram' );
        next if ($kind eq 'RegCast' );
        $regcnf = $c->config->{Regist}->{$kind};
        foreach my $item (@{$regcnf->{items}}) {
            $hval = __PACKAGE__->ParseRegist( $pginfo, $item, undef, '');
            if ( ref($hval) eq 'HASH' ) {
                $c->model('ConkanDB::' . $regcnf->{schema})->create( $hval )
            }
        }
    }
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
       ) = @_;

    # 出演者受付登録
    $c->model('ConkanDB::PgRegCast')->create( $hval );
    # 全出演者登録
    my $castid;
    my $acrow = $c->model('ConkanDB::PgAllCast')->find( $hval->{'name'},
            { 'key'  => 'name_UNIQUE', },
        );
    if ( $acrow ) {
        $castid = $acrow->castid();
    }
    else {
        my $aval = {
                'name'   => $hval->{'name'},
                'namef'  => $hval->{'namef'},
                'status' => '',
                };
        if ( $hval->{'entrantregno'} =~ /^\d+$/ ) {
            $aval->{'regno'} = $hval->{'entrantregno'};
        }
        $acrow = $c->model('ConkanDB::PgAllCast')->create( $aval );
        $castid = $acrow->castid();
    }
    # 出演者管理登録
    $c->model('ConkanDB::PgCast')->create(
        {
        'pgid'   => $hval->{pgid},
        'castid' => $castid,
        'name'   => $hval->{'name'},
        'namef'  => $hval->{'namef'},
        'status' => ( $hval->{'entrantregno'} ) ? '申込者' : $hval->{'needreq'},
        },
    );
}

=head2 progress
-----------------------------------------------------------------------------
企画管理 progress  : 進捗登録 (Chain外)

=cut

sub progress :Local {
    my ( $self, $c ) = @_;

    my $param = $c->request->body_params;
    my $pgid   = $param->{'pgid'};

    $c->model('ConkanDB::PgProgress')->create(
        {
        'pgid'      => $pgid,
        'staffid'   => $c->user->get('staffid'),
        'repdatetime' => \'NOW()',
        'report'        => $param->{'progress'},
        },
    );

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
                'prefetch' => [ 'pgid', 'staffid' ],
                'order_by' => { '-asc' => 'me.pgid' },
            } )
        ];
    my $prglist =
        [ $c->model('ConkanDB::PgProgress')->search( { },
            {
                'group_by' => [ 'pgid' ],
                'select'   => [ 'pgid', { MAX => 'repdatetime'} ], 
                'as'       => [ 'pgid', 'lastprg' ],
            } )
        ];
    my $list = {};
    foreach my $prg ( @$prglist ) {
        $list->{$prg->get_column('pgid')} = $prg->get_column('lastprg');
    }

    foreach my $pgm ( @$pgmlist ) {
        $pgm->{'pgidv'}  = $pgm->pgid->pgid();
        $pgm->{'name'}   = $pgm->pgid->name();
        $pgm->{'staff'}  = $pgm->staffid ? $pgm->staffid->name() : '';
        $pgm->{'repdatetime'} = $list->{$pgm->{'pgidv'}};
    }
    $c->stash->{'list'} = $pgmlist;
}

=head2 program/regprogram

企画管理 pgup_regprog  : 企画更新(受付分)

=cut
sub pgup_regprog : Chained('program_base') : PathPart('regprogram') : Args(1) {
    my ( $self, $c, $pgid ) = @_;

    $c->stash->{'args'} = { target => 'regprogram', pgid => $pgid, };

}

=head2 program/program

企画管理 pgup_program  : 企画更新(管理分)

=cut
sub pgup_program : Chained('program_base') : PathPart('program') : Args(1) {
    my ( $self, $c, $pgid ) = @_;

    $c->stash->{'args'} = { target => 'program', pgid => $pgid, };

}

=head2 program/equip

企画管理 pgup_equip  : 決定機材更新

=cut
sub pgup_equip : Chained('program_base') : PathPart('equip') : Args(2) {
    my ( $self, $c, $pgid, $id ) = @_;

    $c->stash->{'args'} = { target => 'equip', pgid => $pgid, id => $id, };

}

=head2 program/cast

企画管理 pgup_cast  : 決定出演者更新

=cut
sub pgup_cast : Chained('program_base') : PathPart('cast') : Args(2) {
    my ( $self, $c, $pgid, $id ) = @_;

    $c->stash->{'args'} = { target => 'cast', pgid => $pgid, id => $id, };

}

=head2 program/*

企画管理 program_detail  : 詳細表示

=cut

sub program_detail : Chained('program_base') : PathPart('') : Args(1) {
    my ( $self, $c, $pgid ) = @_;

    $c->stash->{'RegProgram'} =
        $c->model('ConkanDB::PgRegProgram')->find($pgid);
    $c->stash->{'RegCasts'} =
        [ $c->model('ConkanDB::PgRegCast')->search(
                        { pgid => $pgid },
                        {
                            'order_by' => { '-asc' => 'id' },
                        }
                    ) ];
    $c->stash->{'RegEquips'} =
        [ $c->model('ConkanDB::PgRegEquip')->search(
                        { pgid => $pgid },
                        {
                            'order_by' => { '-asc' => 'id' },
                        }
                    ) ];
    $c->stash->{'Program'}  =
        [ $c->model('ConkanDB::PgProgram')->search(
                        { pgid => $pgid },
                        {
                            'prefetch' => [ 'staffid', 'roomid' ],
                        },
                    ) ]->[0];
    $c->stash->{'Progress'}  =
        [ $c->model('ConkanDB::PgProgress')->search(
                        { pgid => $pgid },
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
};
=encoding utf8

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
