package conkan::Controller::Config;
use Moose;
use Encode;
use JSON;
use Net::OAuth;
use HTTP::Request::Common;
use String::Random qw/ random_string /;
use XML::Feed;
use Data::Dumper;
use namespace::autoclean;

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

=head2 staff/add

スタッフ管理 staff_add   : スタッフ追加

=cut

sub staff_add : Chained('staff_base') : PathPart('add') : Args(0) {
    my ( $self, $c ) = @_;

    my $type = $c->config->{'addroot'}->{'type'};
    $c->stash->{'addstaff'} = 1;
    my $value ={};
    if ( $type eq 'plain' ) {
        if ( $c->request->method eq 'GET' ) {
            # 登録表示
            $value->{'role'} = 'NORM';
            $c->response->template('add_plain.tt');
        }
        else {
            # 登録実施
            for my $item qw/name account passwd role ma
                            telno regno
                            tname tnamef oname onamef comment / {
                $value->{$item} = $c->request->body_params->{$item};
            }
            $c->stash->{RS}->create( $value );
            #   メール送信
            # とりあえず自動送信はせず、add_plain.tt内で通知するよう促す
            # name, account, maを表示する
            for my $item qw/name account ma / {
                $c->stash->{'rs'}->{$item} = $value->{$item};
            }
            $c->stash->{'state'} = 'success';
        }
    }
    elsif ( $type eq 'cybozu' ) {
        # 既存スタッフのcyid一覧取得
        my %allcyid = ();

        my @arr_ouid = $c->stash->{'RS'}->search(
                                { 'account'  => { '!=' => 'admin' } },
                                { 'order_by' => { '-asc' => 'staffID' } },
                            )->get_column('otheruid')->all;
        for my $ouid (@arr_ouid) {
            my $id = decode_json( $ouid )->{'cybozuID'};
            $allcyid{$id} = 1;
        }

        # グループ参加メンバ一覧取得
        my $prm = $c->forward('/addroot/getprm');
        my $request = Net::OAuth->request( 'protected resource' )->new(
            %{$prm->{'defaults'}},
            'request_method' => 'GET',
            'request_url'    =>
                $prm->{'provider'}->{'gw_memberList_endpoint'}
                    . '?group=' . $prm->{'groupid'},
        );
        $request->sign;

        my $ua = LWP::UserAgent->new;
        my $ua_response = $ua->request( GET $request->to_url );
$c->log->debug('>>> content : ' . "\n" . decode_utf8($ua_response->content));
        Catalyst::Exception->throw( $ua_response->status_line.' '. $ua_response->content )
            unless $ua_response->is_success;

        # メンバ情報解析
        local $XML::Atom::ForceUnicode = 1;
        my $gwmfeed = XML::Atom::Feed->new(\$ua_response->content);
        Catalyst::Exception->throw( XML::Feed->errstr )
            unless $gwmfeed;

        for my $entry ( $gwmfeed->entries ) {
            # entryの子ノード cbl:who のアトリビュートが、nameとcyid
            # になるはずだが、取得できないのでこれはダメぽ
            # てか、APIだとma取れないからほとんど意味無いですこれ
            my $cyid;
            my $name;
            my $ma;
            unless ( $allcyid{$cyid} ) { # cyidが未登録の参加者を追加
                $value->{'name'}     = $name;
                $value->{'account'}  = $ma;
                $value->{'ma'}       = $ma;
                $value->{'otheruid'} = '{"cybozuID":' . '"' . $cyid . '"}';
                $value->{'passwd'}   = random_string( 'cccccccc' );
                $c->stash->{RS}->create( $value );
                # チャット送信
                $c->stash->{'chat'} = $value;
                $c->stash->{'chat'}->{'template'} = 'wellcome.tt';
                $c->stash->{'chat'}->{'cyid'} = $cyid;
                $c->stash->{'chat'}->{'loginurl'} = $c->uri_for('/login');
                $c->forward('/config/sendchat');
            }
        }
        $c->go('/config/staff/list');
    }
}

=head2 sendchat

チャット送信

現在のAPIレベルでは、送信できないっぽい・・・ひどい

=cut

sub sendchat :Private {
    my ( $self, $c ) = @_;
                
    my $chatprm = $c->stash->{'chat'};
    my $prm = $c->forward('/addroot/getprm');
    #   まずチャットID取得
    my $request = Net::OAuth->request( 'protected resource' )->new(
        %{$prm->{'defaults'}},
        'request_method' => 'GET',
        'request_url'    =>
            $prm->{'provider'}->{'mp_chat_endpoint'}
                . '?chat-type=DIRECT&chat-member=' . $chatprm->{'cyid'},
    );
    $request->sign;

    my $ua = LWP::UserAgent->new;
    my $ua_response = $ua->request( GET $request->to_url );
    Catalyst::Exception->throw( $ua_response->status_line.' '. $ua_response->content )
        unless $ua_response->is_success;

    local $XML::Atom::ForceUnicode = 1;
    my $feed = XML::Atom::Feed->new(\$ua_response->content);
    Catalyst::Exception->throw( XML::Feed->errstr )
        unless $feed;

    my $entry = [ $feed->entries ]->[0];
    $chatprm->{'chatid'} = $entry->id;

    # 送信
    $request = Net::OAuth->request( 'protected resource' )->new(
        %{$prm->{'defaults'}},
        'request_method' => 'POST',
        'request_url'    =>
            $prm->{'provider'}->{'mp_chatpush_endpoint'},
        'content_type' => 'application/atom+xml',
    );
    $request->sign;

    $ua = LWP::UserAgent->new;
    $ua_response = $ua->request( POST $request->to_url, 
                                 $c->forward('/config/mkchat') );

    Catalyst::Exception->throw( $ua_response->status_line.' '. $ua_response->content )
        unless $ua_response->is_success;
}

=head2 mkchat

チャットFeed生成

=cut

sub mkchat :Private {
    my ( $self, $c ) = @_;
                
    my $chatprm = $c->stash->{'chat'};

    return $c->forward( "View::TT", "render", $chatprm->{'template'}, $chatprm );
}

=head2 staff/*

スタッフ管理 staff_show  : スタッフ情報更新のための表示

=cut

sub staff_show : Chained('staff_base') :PathPart('') :CaptureArgs(1) {
    my ( $self, $c, $staffid ) = @_;
    
    my $rowprof = [ $c->stash->{'RS'}->find($staffid) ]->[0];
    $rowprof->update( { 
        'updateflg' =>  $c->sessionid
    } );
    $c->stash->{'rs'} = $rowprof;
    if ( $rowprof->otheruid ) {
        $c->stash->{'rs'}->{'cyid'}
            = decode_json( $rowprof->otheruid )->{'cybozuID'};
    }
    $c->stash->{'rs'}->{'passwd'} = undef;
}

=head2 staff/*/edit

スタッフ管理staff_edit  : スタッフ情報更新

=cut

sub staff_edit : Chained('staff_show') : PathPart('edit') : Args(0) {
    my ( $self, $c ) = @_;

    my $staffid = $c->stash->{'rs'}->{'staffid'};
    # GETはおそらく直打ちとかなので再度
    if ( $c->req->method eq 'GET' ) {
        $c->go->( '/config/staff/' . $staffid );
    }
    else {
        # 更新実施
        my $rowprof = [ $c->stash->{'RS'}->find($staffid) ]->[0];
        if ( $rowprof->updateflg eq $c->sessionid ) {
            my $value = {};
            for my $item qw/name role ma
                            passwd staffid account telno regno
                            tname tnamef oname onamef comment / {
                $value->{$item} = $c->request->body_params->{$item};
            }
            $value->{'staffid'}  = $rowprof->staffid;
            $value->{'otheruid'} = $rowprof->otheruid;
            $value->{'passwd'}   = $rowprof->passwd
                unless $value->{'passwd'};
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

=head2 staff/*/del

スタッフ管理 staff_del   : スタッフ削除

=cut

sub staff_del : Chained('staff_show') : PathPart('del') : Args(0) {
    my ( $self, $c ) = @_;
    my $staffid = $c->stash->{'rs'}->{'staffid'};
    # GETはおそらく直打ちとかなので再度
    if ( $c->req->method eq 'GET' ) {
        $c->go->( '/config/staff/' . $staffid );
    }
    else {
        # 削除実施
        my $rowprof = [ $c->stash->{'RS'}->find($staffid) ]->[0];
        if ( $rowprof->updateflg eq $c->sessionid ) {
            $rowprof->update( { 'rmdate'   => "'NOW()'" } );
            $c->stash->{'rs'} = undef;
            $c->stash->{'state'} = 'success';
        }
        else {
            $c->stash->{'rs'} = undef;
            $c->stash->{'state'} = 'deny';
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
