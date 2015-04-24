package conkan::Controller::Addstaff;
use Moose;
use Net::OAuth;
use HTTP::Request::Common;
use String::Random qw/ random_string /;
use XML::Feed;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

conkan::Controller::Addstaff - Catalyst Controller

=head1 DESCRIPTION

スタッフ登録

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # 初期設定で選択したスタッフ登録方法に従ってジャンプ
    $c->response->redirect( 'addstaff/' . $c->config->{'addstaff'}->{'type'} );
}

=head2 plain

個別入力による登録

=cut

sub plain :Local {
    my ( $self, $c ) = @_;
        
    # プロファイル設定画面へリダイレクト
    $c->flash->{role}    = $c->session->{'init_role'} eq 'addroot'
                                 ? 'ROOT'
                                 : 'NORM';

    $c->response->redirect('/mypage/profile');
}

=head2 cybozu

CybouzuLive情報流用登録

=cut

my $api_fqdn = 'api.cybozulive.com';

sub cybozu :Local {
    my ( $self, $c ) = @_;

    $Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

    my $token = $c->flash->{'CybozuToken'};
    unless ( $token ) {
        # サイボウズOAuth認証開始
        my $auth = $c->authenticate( { 'provider' => $api_fqdn }, 'oauth' );
        if ( $auth ) {
            # access-token,secretをflashで引き渡す
            $c->flash->{'CybozuToken'}  = $c->user->token;
            $c->flash->{'CybozuSecret'} = $c->user->token_secret;
            $c->response->redirect('cybozu');
        }
    } else {
        # グループ情報取得
        my $authprm = $c->forward('/addstaff/getprm');
        my $request = Net::OAuth->request( 'protected resource' )->new(
            %{$authprm->{'defaults'}},
            'request_method'    => 'GET',
            'request_url'   => $authprm->{'provider'}->{'group_info_endpoint'},
        );
        $request->sign;

        my $ua = LWP::UserAgent->new;
        my $ua_response = $ua->request( GET $request->to_url );
        Catalyst::Exception->throw( $ua_response->status_line.' '. $ua_response->content )
            unless $ua_response->is_success;

        # グループ情報解析
        local $XML::Atom::ForceUnicode = 1;
        my $grfeed = XML::Atom::Feed->new(\$ua_response->content);
        Catalyst::Exception->throw( XML::Feed->errstr )
            unless $grfeed;

        # グループに属していることを確認
        my $groupid;
        my $grtitle = $c->config->{'addstaff'}->{'group'};
        for my $entry ( $grfeed->entries ) {
            if ( $entry->title eq $grtitle ) {
                $groupid = $entry->id;
                last;
            }
        }
        Catalyst::Exception->throw( "412 Precondition Failed\nグループに参加していません" )
            unless $groupid;

        # ユーザ情報を元に、プロファイル設定画面へリダイレクト
        $c->flash->{'name'}    = $grfeed->author->name;
        $c->flash->{'account'} = $grfeed->author->email;
        $c->flash->{'ma'}      = $grfeed->author->email;
        $c->flash->{'role'}    = $c->session->{'init_role'} eq 'addroot' 
                                 ? 'ROOT'
                                 : 'NORM';
        $c->flash->{'cyid'}    = $grfeed->author->uri;
        $c->flash->{'CybozuToken'}  = $c->flash->{'CybozuToken'};
        $c->flash->{'CybozuSecret'} = $c->flash->{'CybozuSecret'};

        $c->response->redirect('/mypage/profile');
    }
}

=head2 getprm

CybouzuLive情報取得パラメータ設定

戻り値 $ret->{'provider'} : プロバイダ情報ハッシュリファレンス
       $ret->{'default'}  : デフォルトパラメータハッシュリファレンス

=cut

sub getprm :Private {
    my ( $self, $c ) = @_;

    my $retprm = {};
    my $token    = $c->flash->{'CybozuToken'};
    my $tokensec = $c->flash->{'CybozuSecret'};
    $retprm->{'provider'} =
         $c->config->{'Plugin::Authentication'}->{'oauth'}
                        ->{'credential'}->{'providers'}->{$api_fqdn};
    $retprm->{'defaults'} = {
        'consumer_key'      => $retprm->{'provider'}->{'consumer_key'},
        'consumer_secret'   => $retprm->{'provider'}->{'consumer_secret'},
        'token'             => $token,
        'token_secret'      => $tokensec,
        'timestamp'         => time,
        'nonce'             => random_string( 'ccccccccccccccccccc' ),
        'signature_method'  => 'HMAC-SHA1',
        'oauth_version'     => '1.0a',
    };

    return $retprm;
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
