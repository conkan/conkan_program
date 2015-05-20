package conkan::Controller::Config;
use Moose;
use utf8;
use JSON;
use Net::OAuth;
use HTTP::Request::Common;
use String::Random qw/ random_string /;
use XML::Feed;
use Try::Tiny;
use DateTime;
use namespace::autoclean;
use Data::Dumper;

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
    regist_confは別途

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
        my $updaterow = [ $sysconM->find('updateflg') ]->[0];
        if ( $updaterow->pg_conf_value eq
                +( $c->sessionid . $c->session->{'updtic'}) ) {
            my $param = $c->request->body_params;
            try {
                foreach my $pHwk ( @rowconf ) {
                    next if ( $pHwk->pg_conf_code eq 'updateflg' );
                    $param->{$pHwk->pg_conf_code} =~ s/\s+$//;
                    $pHwk->pg_conf_value( $param->{$pHwk->pg_conf_code} );
                    $pHwk->update();
                }
                $c->stash->{'state'} = 'success';
            } catch {
                my $e = shift;
                $c->log->error('>>> ' . localtime() . 'dbexp : [' . $e . ']');
                if ( scalar @{ $c->error } ) {
                    foreach my $err (@{ $c->error }) {
                        $c->log->error('>>> ' . localtime() . 'dbexp : [' . $err . ']');
                    }
                    $c->clear_errors();
                }
                $c->stash->{'state'} = 'deny';
            };
        }
        else {
            $c->stash->{'state'} = 'deny';
        }
        $c->stash->{'cnf'} = undef;
    }
}

=head2 staff
-----------------------------------------------------------------------------
スタッフ管理 staff_base  : Chainの起点

=cut

sub staff_base : Chained('') : PathPart('config/staff') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # staffテーブルに対応したrsオブジェクト取得
    $c->stash->{'RS'}   = $c->model('ConkanDB::PgStaff');
}

=head2 staff/list 

スタッフ管理 staff_list  : スタッフ一覧

=cut

sub staff_list : Chained('staff_base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{'list'} = [ $c->stash->{RS}
                            ->search( { 'account'  => { '!=' => 'admin' } },
                                      { 'order_by' => { '-asc' => 'staffID' } } 
                                    )
                          ];
}

=head2 staff/*

スタッフ管理 staff_show  : スタッフ情報更新のための表示起点

=cut

sub staff_show : Chained('staff_base') :PathPart('') :CaptureArgs(1) {
    my ( $self, $c, $staffid ) = @_;
    
    my $rowprof = [ $c->stash->{'RS'}->find($staffid) ]->[0];
    $c->session->{'updtic'} = time;
    $rowprof->update( { 
        'updateflg' =>  $c->sessionid . $c->session->{'updtic'}
    } );
    $c->stash->{'rs'} = $rowprof;
    if ( $rowprof->otheruid ) {
        my $cybozu = decode_json( $rowprof->otheruid );
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
        my $rowprof = [ $c->stash->{'RS'}->find($staffid) ]->[0];
        if ( $rowprof->updateflg eq 
                +( $c->sessionid . $c->session->{'updtic'}) ) {
            my $value = {};
            for my $item qw/name role ma
                            passwd staffid account telno regno
                            tname tnamef comment / {
                $value->{$item} = $c->request->body_params->{$item};
            }
            $value->{'staffid'}  = $rowprof->staffid;
            $value->{'otheruid'} = $rowprof->otheruid;
            if ( $value->{'passwd'} ) {
                $value->{'passwd'} =
                    crypt( $value->{'passwd'}, random_string( 'cccc' ));
            }
            else {
                $value->{'passwd'}   = $rowprof->passwd
            }
            try {
                $rowprof->update( $value ); 
                $c->response->body('<FORM><H1>更新しました</H1></FORM>');
            } catch {
                my $e = shift;
                $c->log->error('>>> ' . localtime() . 'dbexp : [' . $e . ']');
                if ( scalar @{ $c->error } ) {
                    foreach my $err (@{ $c->error }) {
                        $c->log->error('>>> ' . localtime() . 'dbexp : [' . $err . ']');
                    }
                    $c->clear_errors();
                }
                $c->response->body('<FORM>更新失敗</FORM>');
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
        # 削除実施
        my $rowprof = [ $c->stash->{'RS'}->find($staffid) ]->[0];
        if ( $rowprof->updateflg eq 
                +( $c->sessionid . $c->session->{'updtic'}) ) {
            try {
                $rowprof->update( { 'rmdate'   => DateTime->now() } );
                $c->response->body('<FORM><H1>削除しました</H1></FORM>');
            } catch {
                my $e = shift;
                $c->log->error('>>> ' . localtime() . 'dbexp : [' . $e . ']');
                if ( scalar @{ $c->error } ) {
                    foreach my $err (@{ $c->error }) {
                        $c->log->error('>>> ' . localtime() . 'dbexp : [' . $err . ']');
                    }
                    $c->clear_errors();
                }
                $c->response->body('<FORM>削除失敗</FORM>');
            };
        }
        else {
            $c->response->body = '<FORM><H1>削除できませんでした</H1><BR/>他のシステム管理者が変更した可能性があります</FORM>';
        }
        $c->stash->{'rs'} = undef;
        $c->response->status(200);
    }
}

=head2 room
-----------------------------------------------------------------------------
部屋管理 room_base  : Chainの起点

=cut

sub room_base : Chained('') : PathPart('config/room') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # roomテーブルに対応したrsオブジェクト取得
    $c->stash->{'RS'}   = $c->model('ConkanDB::PgRoom');
}

=head2 room/list 

部屋管理 room_list  : 部屋一覧

=cut

sub room_list : Chained('room_base') : PathPart('list') : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{'list'} = [ $c->stash->{RS}
                            ->search( { },
                                      { 'order_by' => { '-asc' => 'roomID' } } )
                          ];
}

=head2 room/*

部屋管理 room_show  : 部屋情報更新のための表示起点

=cut

sub room_show : Chained('room_base') :PathPart('') :CaptureArgs(1) {
    my ( $self, $c, $roomid ) = @_;
    
    my $rowroom;
    if ( $roomid != 0 ) {
        $rowroom = [ $c->stash->{'RS'}->find($roomid) ]->[0];
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

    my $roomid = $c->request->body_params->{'roomid'};

    $c->log->debug('>>> room_edit :[' . $roomid . ']');

    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->log->debug('>>> reload');
        $c->go->( '/config/room/' . $roomid );
    }
    else {
        my $value = {};
        for my $item qw/name roomno max type size tablecnt
                        chaircnt equips useabletime net comment / {
            $value->{$item} = $c->request->body_params->{$item};
            $value->{$item} =~ s/\s+//;
        }
        if ( $roomid != 0 ) {
            # 更新
            my $rowroom = [ $c->stash->{'RS'}->find($roomid) ]->[0];
            if ( $rowroom->updateflg eq 
                    +( $c->sessionid . $c->session->{'updtic'}) ) {
                try {
                    $c->log->debug('>>> update');
                    $rowroom->update( $value ); 
                    $c->response->body('<FORM><H1>更新しました</H1></FORM>');
                } catch {
                    my $e = shift;
                    $c->log->error('>>> ' . localtime() . 'dbexp : [' . $e . ']');
                    if ( scalar @{ $c->error } ) {
                        foreach my $err (@{ $c->error }) {
                            $c->log->error('>>> ' . localtime() . 'dbexp : [' . $err . ']');
                        }
                        $c->clear_errors();
                    }
                    $c->response->body('<FORM>更新失敗</FORM>');
                };
            }
            else {
                $c->log->debug('>>> updateflg unmatch');
                $c->response->body = '<FORM><H1>更新できませんでした</H1><BR/>他のシステム管理者が変更した可能性があります</FORM>';
            }
        }
        else {
            # 新規登録
            try {
                $c->log->debug('>>> create');
                $c->stash->{'RS'}->create( $value );
                $c->response->body('<FORM><H1>登録しました</H1></FORM>');
            } catch {
                my $e = shift;
                $c->log->error('>>> ' . localtime() . 'dbexp : [' . $e . ']');
                if ( scalar @{ $c->error } ) {
                    foreach my $err (@{ $c->error }) {
                        $c->log->error('>>> ' . localtime() . 'dbexp : [' . $err . ']');
                    }
                    $c->clear_errors();
                }
                $c->response->body('<FORM>登録失敗</FORM>');
            };
        }
        $c->stash->{'rs'} = undef;
        $c->response->status(200);
    }
}

=head2 room/*/del

部屋管理 room_del   : 部屋削除

=cut

sub room_del : Chained('room_show') : PathPart('del') : Args(0) {
    my ( $self, $c ) = @_;
    my $roomid = $c->request->body_params->{'roomid'};
    # GETはおそらく直打ちとかなので再度
    if ( $c->request->method eq 'GET' ) {
        $c->go->( '/config/room/' . $roomid );
    }
    else {
        # 削除実施
        my $rowprof = [ $c->stash->{'RS'}->find($roomid) ]->[0];
        if ( $rowprof->updateflg eq 
                +( $c->sessionid . $c->session->{'updtic'}) ) {
            try {
                $rowprof->update( { 'rmdate'   => DateTime->now() } );
                $c->response->body('<FORM><H1>削除しました</H1></FORM>');
            } catch {
                my $e = shift;
                $c->log->error('>>> ' . localtime() . 'dbexp : [' . $e . ']');
                if ( scalar @{ $c->error } ) {
                    foreach my $err (@{ $c->error }) {
                        $c->log->error('>>> ' . localtime() . 'dbexp : [' . $err . ']');
                    }
                    $c->clear_errors();
                }
                $c->response->body('<FORM>削除失敗</FORM>');
            };
        }
        else {
            $c->response->body = '<FORM><H1>削除できませんでした</H1><BR/>他のシステム管理者が変更した可能性があります</FORM>';
        }
        $c->stash->{'rs'} = undef;
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
