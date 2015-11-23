use strict;
use warnings;
use Test::More;


use Catalyst::Test 'conkan';
use conkan::Controller::Program;

ok( request('/program')->is_success, 'Request should succeed' );
done_testing();
