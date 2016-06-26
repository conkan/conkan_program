package conkan::View::JSON;

use strict;
use base 'Catalyst::View::JSON';

=head1 NAME

conkan::View::JSON - Catalyst JSON View

=head1 SYNOPSIS

See L<conkan>

=head1 DESCRIPTION

Catalyst JSON View.

=head1 METHOD

=head2 process

Cache-Controlヘッダ追加

=cut

sub process {
    my($self, $c) = @_;
    
    $c->res->header('Cache-Control' => 'no-cache');
    $self->SUPER::process( $c );
}

=head1 AUTHOR

root

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
