use strict;
use warnings;
use Test::More;


use Catalyst::Test 'conkan';
use conkan::Controller::Config;

ok( request('/config')->is_success, 'Request should succeed' );
done_testing();
