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

システム全体設定(未実装)
    system_conf, regist_conf の更新

=cut

#sub setting :Local {
#    my ( $self, $c ) = @_;
#}

=head2 staff

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
                $c->log->error('>>> dbexp : [' . $e . ']');
                if ( scalar @{ $c->error } ) {
                    foreach my $err (@{ $c->error }) {
                        $c->log->error('>>> dbexp : [' . $err . ']');
                    }
                    $c->clear_errors();
                }
                $c->response->body('<FORM>更新失敗</FORM>');
            };
        }
        else {
            $c->stash->{'rs'} = undef;
            $c->response->body = '<FORM><H1>更新できませんでした</H1></FORM>';
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
                $c->log->error('>>> dbexp : [' . $e . ']');
                if ( scalar @{ $c->error } ) {
                    foreach my $err (@{ $c->error }) {
                        $c->log->error('>>> dbexp : [' . $err . ']');
                    }
                    $c->clear_errors();
                }
                $c->response->body('<FORM>削除失敗</FORM>');
            };
        }
        else {
            $c->response->body = '<FORM><H1>削除できませんでした</H1></FORM>';
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
