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

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

}

=head2 profile

=cut

sub profile :Local {
    my ( $self, $c ) = @_;

    my $param = $c->request->body_params;
    my $value = {};
    for my $item qw/name role ma
                    passwd staffid account telno regno
                    tname tnamef comment / {
        $value->{$item} = $c->flash->{$item} || $param->{$item};
    }
    my $staffM = $c->model('ConkanDB::PgStaff');
    my $staffid = $value->{'staffid'};
    unless ( $staffid || ( $c->user->get('account') eq 'admin' ) ) {
        $staffid = $c->user->get('staffid');
    }

    if ( $staffid ) { # 更新
        my $rowprof = [ $staffM->find($staffid) ]->[0];

        if ( $c->request->method eq 'GET' ) {
            # 更新表示
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
            $c->stash->{'rs'}->passwd = undef;
        }
        else {
            # 更新実施
            if ( $rowprof->updateflg eq 
                +( $c->sessionid . $c->session->{'updtic'}) ) {
                $value->{'otheruid'} = $rowprof->otheruid;
                if ( $value->{'passwd'} ) {
                    $value->{'passwd'} =
                        crypt( $value->{'passwd'}, random_string( 'cccc' ));
                }
                else {
                    $value->{'passwd'}   = $rowprof->passwd
                }
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
        my $oainfo;
        for my $item qw/cyid CybozuToken CybozuSecret / {
            $oainfo->{$item} = $c->flash->{'oainfo'}->{$item} || $param->{$item};
        }
        if ( $c->request->method eq 'GET' ) {
            # 登録表示
            while ( my( $key, $val ) = each( %$oainfo ) ) {
                $value->{$key} = $val;
            }
            $c->stash->{'rs'} = $value;
        }
        else {
            # 登録実施
            unless ( $staffM->search({account => $value->{'account'}})->count ) {
                $value->{'otheruid'} = encode_json( $oainfo );
                # 末尾の空白を除く
                foreach my $key ( keys( %$value ) ) {
                    $value->{$key} =~ s/\s+$//;
                }
                $value->{'passwd'} =
                    crypt( $value->{'passwd'}, random_string( 'cccc' ));
                $staffM->create( $value );
                $c->stash->{'rs'} = undef;
                $c->stash->{'state'} = 'success';
            }
            else {
                while ( my( $key, $val ) = each( %$oainfo ) ) {
                    $value->{$key} = $val;
                }
                $c->stash->{'state'} = undef;
                $c->stash->{'accountdupl'} = 1;
                $c->stash->{'rs'} = $value;
                $c->stash->{'rs'}->{'passwd'} = undef;
            }
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
