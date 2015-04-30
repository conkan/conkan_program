use strict;
use warnings;
use Test::More;


use Catalyst::Test 'conkan';
use conkan::Controller::Mypage;

ok( request('/mypage')->is_success, 'Request should succeed' );
done_testing();
