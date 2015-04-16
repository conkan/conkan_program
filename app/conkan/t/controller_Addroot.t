use strict;
use warnings;
use Test::More;


use Catalyst::Test 'conkan';
use conkan::Controller::Addroot;

ok( request('/addroot')->is_success, 'Request should succeed' );
done_testing();
