package conkan::View::Initialize;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT::ForceUTF8';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
);

=head1 NAME

conkan::View::Initialize - TT View for conkan

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
