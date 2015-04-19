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
                    tname tnamef oname onamef comment / {
        $value->{$item} = $c->flash->{$item} || $param->{$item};
    }
    my $staffM = $c->model('ConkanDB::PgStaff');
    my $staffid = $value->{'staffid'};
    unless ( $staffid || ( $c->user->get('account') eq 'admin' ) ) {
        $staffid = $c->user->get('staffid');
    }

    if ( $value->{'passwd'} ) {
        $value->{'passwd'} = crypt( $value->{'passwd'}, random_string( 'cccc' ));
    }

    if ( $staffid ) { # 更新
        my $rowprof = [ $staffM->find($staffid) ]->[0];

        if ( $c->request->method eq 'GET' ) {
            # 更新表示
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
        else {
            # 更新実施
            if ( $rowprof->updateflg eq $c->sessionid ) {
                $value->{'otheruid'} = $rowprof->otheruid;
                $value->{'passwd'} = $rowprof->passwd
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
    else {  # 新規登録
        my $cyid = $c->flash->{'cyid'} || $param->{'cyid'};
        if ( $c->request->method eq 'GET' ) {
            # 登録表示
            $value->{'cyid'} = $cyid;
            $c->stash->{'rs'} = $value;
        }
        else {
            # 登録実施
            $value->{'otheruid'} = '{"cybozuID":' . '"' . $cyid . '"}';
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
