package conkan::Controller::Mypage;
use Moose;
use JSON;
use String::Random qw/ random_string /;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

conkan::Controller::Mypage - Catalyst Controller

=head1 DESCRIPTION

MyPageを表示する Catalyst Controller.

=head1 METHODS

=cut


=head2 index

login済 -> mypage/list
未login -> 初期設定

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $uid = $c->user->get('staffid');
    $c->response->redirect( '/mypage/list' ) if ( $uid > 1 );
}

=head2 mypage
-----------------------------------------------------------------------------
MYPAGE mypage_base  : Chainの起点

=cut

sub mypage_base : Chained('') : PathPart('mypage') : CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

=head2 list

そのユーザが担当している企画一覧

=cut
sub mypage_list : Chained('mypage_base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;

    my $uid = $c->user->get('staffid');
    my $pgmlist =
        [ $c->model('ConkanDB::PgProgram')->search( { 'me.staffid' => $uid },
            {
                'prefetch' => [ 'regpgid', 'staffid' ],
                'order_by' => { '-asc' => [ 'me.regpgid', 'me.subno' ] },
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
            'status'        => $pgm->status(),
            'repdatetime'   => $lastprgs->{$regpgid},
        };
    }
    $c->stash->{'list'} = \@list;
}

=head2 mypage/*

MYPAGE mypage_show  : 詳細表示起点

=cut

sub mypage_show : Chained('mypage_base') :PathPart('') :Args(1) {
    my ( $self, $c, $pgid ) = @_;

    $c->stash->{'self_li_id'} = 'mypage';
    $c->go('/program/program_detail/', [ $pgid ], [] );
}

=head2 profile

プロファイル設定

=cut

sub profile :Local {
    my ( $self, $c ) = @_;

    my $param = $c->request->body_params;
    # flashかformからパラメータを取り出し、末尾の空白を除く
    my $value = {};
    for my $item qw/name role ma
                    passwd staffid account telno regno
                    tname tnamef comment / {
        $value->{$item} = $c->flash->{$item} || $param->{$item};
        $value->{$item} =~ s/\s+$// if defined($value->{$item});
    }
    # flashかformからoainfoパラメータを取り出し、末尾の空白を除く
    my $oainfo = {};
    for my $item qw/cyid CybozuToken CybozuSecret / {
        $oainfo->{$item} = $c->flash->{'oainfo'}->{$item} || $param->{$item};
        $oainfo->{$item} =~ s/\s+$// if defined($oainfo->{$item});
    }

    my $staffM = $c->model('ConkanDB::PgStaff');
    my $staffid = $value->{'staffid'};
    my $curacnt = $c->user->get('account');
    unless ( defined($staffid) ) {
        if ( !defined($curacnt) || $curacnt ne 'admin' ) {
            $staffid = $c->user->get('staffid');
        }
    }
    # 既存のスタッフ検索
    my $row = $staffM->find( $value->{'account'}, { 'key' => 'account_UNIQUE' });
    if ( $row && $row->passwd eq '' ) {
        # 仮登録 -> 本登録
        $c->stash->{'addstaff'} = 1;
        $staffid = $row->staffid;
    }
    if ( $staffid ) { # 更新
        my $rowprof = $staffM->find($staffid);
        if ( $c->request->method eq 'GET' ) {
            # 更新表示
            $c->session->{'updtic'} = time;
            $rowprof->update( { 
                'updateflg' =>  $c->sessionid . $c->session->{'updtic'}
            } );
            $c->stash->{'rs'} = $rowprof;
            my $cybozu = $rowprof->otheruid ? decode_json( $rowprof->otheruid )
                                            : $oainfo;
            while ( my( $key, $val ) = each( %$cybozu )) {
                $c->stash->{'rs'}->{$key} = $val;
            }
            $c->stash->{'rs'}->{'passwd'} = undef;
        }
        else {
            # 更新実施
            if ( $rowprof->updateflg eq 
                +( $c->sessionid . $c->session->{'updtic'}) ) {
                $value->{'otheruid'} = $rowprof->otheruid ||
                                       encode_json( $oainfo );
                if ( $value->{'passwd'} ) {
                    $value->{'passwd'} =
                        crypt( $value->{'passwd'}, random_string( 'cccc' ));
                }
                else {
                    $value->{'passwd'}   = $rowprof->passwd
                }
                $value->{'tname'} = $value->{'tname'} || $value->{'name'};
                $rowprof->update( $value ); 
                $c->stash->{'rs'} = undef;
                $c->stash->{'state'} = 'success';
            }
            else {
                $c->stash->{'rs'} = undef;
                $c->stash->{'state'} = 'deny';
            }
        }
    }
    else {  # 新規登録
        $c->stash->{'addstaff'} = 1;
        if ( $c->request->method eq 'GET' ) {
            # 登録表示
            while ( my( $key, $val ) = each( %$oainfo ) ) {
                $value->{$key} = $val;
            }
            $c->stash->{'rs'} = $value;
        }
        else {
            # 登録実施
            $value->{'otheruid'} = encode_json( $oainfo );
            $value->{'passwd'} =
                crypt( $value->{'passwd'}, random_string( 'cccc' ));
            $value->{'tname'} = $value->{'tname'} || $value->{'name'};
            $value->{'staffid'} = undef;
            $staffM->create( $value );
            $c->stash->{'rs'} = undef;
            $c->stash->{'state'} = 'success';
        }
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
