# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl BTree.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok('BTree') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use BTree;

my $tree = BTree->new({ by_key => 'id' });
ok($tree);

my $options = $tree->options();
ok($options);
is('HASH', ref $options);

my $ret;

$ret = $tree->insert({ id => 10, 'name' => 'Bob' });
ok($ret, 'normal insert');

$ret = $tree->insert({ id => 8, 'name' => 'John' });
ok($ret, 'normal insert');

$ret = $tree->insert({ id => 12, 'name' => 'Connie' });
ok($ret, 'normal insert');

$ret = $tree->insert(11 , { id => 10, 'name' => 'Bob' });
ok($ret, 'insert with an external key');


