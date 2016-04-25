package conkan::View::TT;
use strict;
use warnings;
use utf8;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT::ForceUTF8';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    ENCODING   => 'utf8',
    render_die => 1,
    COMPILE_EXT => '.ttc',
    COMPILE_DIR => './ttctmp',
);

=head1 NAME

conkan::View::TT - TT View for conkan

=head1 DESCRIPTION

TT View for conkan.

=head1 SEE ALSO

L<conkan>

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
