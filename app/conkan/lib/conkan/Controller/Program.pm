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
    ## PgIDが未設定の場合autoincするため、{RegProgram}のみ先行登録
    ## {RegProgram}のitem数は1つであり、loopmax定義はない
    $regcnf = $c->config->{Regist}->{RegProgram};
    $hval = __PACKAGE__->ParseRegist( $pginfo, $regcnf->{items}->[0], undef, ''  );
    if ( ref($hval) eq 'HASH' ) {
$c->log->debug(">>> hval :\n" . Dump($hval) );
        my $row = $c->model('ConkanDB::' . $regcnf->{schema})->create( $hval );
        ## $pginfo->{企画ID}の値を再設定 (autoinc対応)
$c->log->debug(">>>  row->pgid :[" . $row->pgid . ']' );
        $pginfo->{'企画ID'} = $row->pgid;
    }

    # $c->config->{Regist}の内容に基づいて pginfoの内容をDBに登録
$c->log->debug('>>> pgid:[' . $pginfo->{'企画ID'} . ']');
    my @kinds = keys( %{$c->config->{Regist}} );
    foreach my $kind (@kinds) {
        next if ($kind eq 'RegProgram' );
        $regcnf = $c->config->{Regist}->{$kind};
        foreach my $item (@{$regcnf->{items}}) {
            if ( defined($item->{loopmax}) ) {
                foreach my $cnt (1..$item->{loopmax}) {
                    $hval = __PACKAGE__->ParseRegist( $pginfo, $item, undef, $cnt );
                    if ( ref($hval) eq 'HASH' ) {
                        $c->model('ConkanDB::' . $regcnf->{schema})->create( $hval );
                    }
                }
            }
            else {
                $hval = __PACKAGE__->ParseRegist( $pginfo, $item, undef, '');
                if ( ref($hval) eq 'HASH' ) {
                    $c->model('ConkanDB::' . $regcnf->{schema})->create( $hval )
                }
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
    foreach my $prg ( @$prglist ) {
        $list->{$prg->pgid()} = $prg->get_column('lastprg');
    }

    foreach my $pgm ( @$pgmlist ) {
        $pgm->{'pgidv'}  = $pgm->pgid->pgid();
        $pgm->{'name'}   = $pgm->pgid->name();
        $pgm->{'staff'}  = $pgm->staffid ? $pgm->staffid->name() : '';
        $pgm->{'reqpdatetime'} = $list->{$pgm->{'pgidv'}};
    }
    $c->stash->{'list'} = $pgmlist;
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
