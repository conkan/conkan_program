package conkan::View::Download::CSV;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::Download::CSV';

__PACKAGE__->config(
    'eol'           => "\r\n",
);

=head1 NAME

conkan::View::Download::CSV - Download View for conkan

=head1 DESCRIPTION

Download View for conkan.

=head1 SEE ALSO

L<conkan>

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
