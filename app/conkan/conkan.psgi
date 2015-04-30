use strict;
use warnings;
use IO::Handle;
use File::Spec;
use File::Basename;
use Plack::Builder;

use lib (dirname(File::Spec->rel2abs($0)) . '/lib');
use conkan;

STDERR->autoflush(1);
my $error_file  = "/var/log/conkan/error_log";
open STDERR, ">>", $error_file or die $!;

my $app = conkan->apply_default_middlewares(conkan->psgi_app);
$app;
