use strict;
use warnings;
use Test::More;


use Catalyst::Test 'conkan';
use conkan::Controller::Addstaff;

ok( request('/addstaff')->is_success, 'Request should succeed' );
done_testing();
