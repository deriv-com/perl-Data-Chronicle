use strict;
use warnings;

use Data::Chronicle::Writer;
use RedisDB;
use Date::Utility;
use Test::More;
use Test::Exception;
require Test::NoWarnings;

plan skip_all => "\$ENV{CHECK_REDIS} is not set, skipping" unless $ENV{CHECK_REDIS};

my $data = {sample => 'data'};

subtest "Call Set after dropping the connection" => sub {

    my $connection = RedisDB->new(
        host => 'localhost',
        port => '6379',
    );

    my $writer = Data::Chronicle::Writer->new(
        publish_on_set => 1,
        cache_writer   => $connection
    );
     # calling set() which will call mset() and put the flag `multi`
    $writer->set('namespace', 'category', $data, Date::Utility->new, 0);

    # Kill All Client Connections
    my $cmd = "redis-cli -p 6379 CLIENT KILL TYPE normal";
    for (1..5) {   system($cmd);   sleep(1);}

    # call set again after dropping the connection
    # check the connection will be recreated
    lives_ok( sub { $writer->set('namespace', 'category', $data, Date::Utility->new, 0) }, 'expecting to live' );
};

Test::NoWarnings::had_no_warnings();
done_testing;