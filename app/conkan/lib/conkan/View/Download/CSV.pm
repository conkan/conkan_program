package conkan::View::Download::CSV;
use Moose;
use namespace::autoclean;
use Encode;

extends 'Catalyst::View::Download::CSV';

__PACKAGE__->config(
    'eol'           => "\r\n",
);

=head1 NAME

conkan::View::Download::CSV - Download View for conkan

=head1 DESCRIPTION

Download View for conkan.

=head1 METHOD

=head2 render

encoding追加

=cut

my $QR_CRLF = qr/\r\n/;
my $QR_LF = qr/\r/;
my $QR_CR = qr/([^",])\n/;
sub render {
    my ( $self,
         $c, $template, $args ) = @_;

    my $content = $self->SUPER::render( $c, $template, $args );
    $content =~ s/$QR_CRLF/\n/g;
    $content =~ s/$QR_LF/\n/g;
    while ( $content =~ $QR_CR ) {
        $content =~ s/$QR_CR/$1\\n/g;
    }
    if ( $c->stash->{'csvenc'} ) {
        $c->response->content_type('application/octet-stream');
        $content = encode( $c->stash->{'csvenc'}, $content );
    }
    return $content;
}

=head1 SEE ALSO

L<conkan>

=head1 AUTHOR

root

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
