# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl BTree.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 15;
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

$ret = $tree->update({ id => 8, 'name' => 'Johnson' });
ok($ret, 'normal update');

$ret = $tree->insert({ id => 12, 'name' => 'Connie' });
ok($ret, 'normal insert');

$ret = $tree->delete(12);
ok($ret, 'delete successfully @ 12');

$ret = $tree->delete(12);
ok(!$ret, 'inexistent key deletion');

$ret = $tree->delete(99);
ok(!$ret, 'inexistent key deletion');

ok $tree->insert({ id => 13, 'name' => 'Wendy' }), "insert Wendy @ 13";
ok $tree->insert({ id => 12, 'name' => 'Samma' }), "insert Samma @ 12";
ok $tree->insert({ id => 3, 'name' => 'Amy' }), "insert Amy @ 3";
$tree->delete(13);

diag("deleting multiple keys");
$tree->delete(13, 12, 3);

$tree->dump();

$ret = $tree->insert(199 , { id => 10, 'name' => 'Bob' });
ok($ret, 'insert with an external key');


