package conkan;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

extends 'Catalyst';

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory
#
# starmanでのデバッグ時には
#   -Debug -Log=debug
# を追加すること

use Catalyst qw/
    ConfigLoader
    Config::YAML
   -Debug -Log=debug
    Static::Simple
    Session
    Session::Store::FastMmap
    Session::State::Cookie
    Authentication
/;

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in conkan.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.
#
# conkan.yml は Plugin::ConfigLoaderが自動で読み込むので、それ以外を指定

__PACKAGE__->config( {
    'config_file'   =>  [ 'regist.yml', ],
} );

# Start the application
__PACKAGE__->setup();

=encoding utf8

=head1 NAME

conkan - Catalyst based application

=head1 SYNOPSIS

    script/conkan_server.pl

=head1 DESCRIPTION

汎用コンベンション管理システム conkan

=head1 SEE ALSO

L<conkan::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Studio REM

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
