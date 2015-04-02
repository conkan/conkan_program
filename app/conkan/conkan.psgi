use strict;
use warnings;
use File::Spec;
use File::Basename;

use lib (dirname(File::Spec->rel2abs($0)) . '/lib');
use conkan;

my $app = conkan->apply_default_middlewares(conkan->psgi_app);
$app;

