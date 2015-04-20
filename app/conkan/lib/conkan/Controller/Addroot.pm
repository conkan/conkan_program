package conkan::Controller::Addroot;
use Moose;
use Net::OAuth;
use HTTP::Request::Common;
use String::Random qw/ random_string /;
use XML::Feed;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

conkan::Controller::Addroot - Catalyst Controller

=head1 DESCRIPTION

最初の管理者登録

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # 初期設定で選択したスタッフ登録方法に従ってジャンプ
    $c->response->redirect( 'addroot/' . $c->config->{'addroot'}->{'type'} );
}

=head2 plain

個別入力による登録

=cut

sub plain :Local {
    my ( $self, $c ) = @_;
}

=head2 cybozu

CybouzuLive情報流用登録

=cut

sub cybozu :Local {
    my ( $self, $c ) = @_;

    $Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
    my $api_fqdn = 'api.cybozulive.com';
    my $sysconfM = $c->model('ConkanDB::PgSystemConf');

    my $rs = $sysconfM->find('CybozuToken');
    my $token = [ $rs->pg_conf_value ]->[0] if $rs;
    unless ( $token ) {
        # サイボウズOAuth認証開始
        my $auth = $c->authenticate( { 'provider' => $api_fqdn }, 'oauth' );
        if ( $auth ) {
            # access-token,secret登録
            $sysconfM->update_or_create( {
                'pg_conf_code'  => 'CybozuToken',
                'pg_conf_name'  => 'サイボウズライブ Access Token',
                'pg_conf_value' => $c->user->token,
            });
            $sysconfM->update_or_create({
                'pg_conf_code'  => 'CybozuSecret',
                'pg_conf_name'  => 'サイボウズライブ Access Token Secret',
                'pg_conf_value' => $c->user->token_secret,
            });
            $c->response->redirect('cybozu');
        }
    } else {
        my $provider = $c->config->{'Plugin::Authentication'}->{'oauth'}
                            ->{'credential'}->{'providers'}->{$api_fqdn};
        my $tokensec = [ $sysconfM->find('CybozuSecret')->pg_conf_value ]->[0];
        my %defaults = (
            'consumer_key'      => $provider->{consumer_key},
            'consumer_secret'   => $provider->{consumer_secret},
            'token'             => $token,
            'token_secret'      => $tokensec,
            'timestamp'         => time,
            'nonce'             => random_string( 'ccccccccccccccccccc' ),
            'signature_method'  => 'HMAC-SHA1',
            'oauth_version'     => '1.0a',
        );

        # グループ情報取得
        my $request = Net::OAuth->request( 'protected resource' )->new(
            %defaults,
            'request_method'    => 'GET',
            'request_url'   => $provider->{group_info_endpoint},
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

        # グループに属していることに確認
        my $groupid;
        my $grtitle = $c->config->{'addroot'}->{'group'};
        for my $entry ( $grfeed->entries ) {
            if ( $entry->title eq $grtitle ) {
                $groupid = $entry->id;
                last;
            }
        }
        Catalyst::Exception->throw( "412 Precondition Failed\nグループに参加していません" )
            unless $groupid;

        # GroupID登録
        $groupid =~ s/^.*,//;   # IDのみにtrancate
        $sysconfM->update_or_create( {
            'pg_conf_code'  => 'CybozuGID',
            'pg_conf_name'  => 'サイボウズライブ グループID',
            'pg_conf_value' => $groupid,
        });

        # ユーザ情報を元に、プロファイル設定画面へリダイレクト
        $c->flash->{name}    = $grfeed->author->name;
        $c->flash->{account} = $grfeed->author->email;
        $c->flash->{ma}      = $grfeed->author->email;
        $c->flash->{cyid}    = $grfeed->author->uri;
        $c->flash->{role}    = 'ROOT';

        $c->response->redirect('/mypage/profile');
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
