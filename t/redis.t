use strict;
use warnings;

use Date::Utility;
use Test::More;
use Test::Exception;
use Data::Chronicle::Writer;
use Data::Chronicle::Reader;
require Test::NoWarnings;
use BOM::Config::Chronicle;
use YAML::XS;

my $data = {sample => 'data'};

subtest "Call Set after dropping the connection" => sub {
    
    my $writer = BOM::Config::Chronicle::get_chronicle_writer();
    my $reader = BOM::Config::Chronicle::get_chronicle_reader();
     # calling set() which will call mset() and put the flag `multi`
    $writer->set('namespace', 'category', $data, Date::Utility->new, 0);

    # change this to use the default one with the default port and localhost in CircleCI
    my $connection_config  = YAML::XS::LoadFile($ENV{BOM_TEST_REDIS_REPLICATED} // '/etc/rmg/redis-replicated.yml');
    my $port               = $connection_config->{write}->{port};
    my $password           = $connection_config->{write}->{password} ? $connection_config->{write}->{password} : '';
    use Data::Dumper;
   
    # Kill All Client Connections
    my $cmd = "redis-cli -p $port -a $password CLIENT KILL TYPE normal";
    for (1..10) {   system($cmd);   sleep(1);}

    # call set again after dropping the connection
    # check the connection will be recreated
    lives_ok( sub { $writer->set('namespace', 'category', $data, Date::Utility->new, 0) }, 'expecting to live' );
};

Test::NoWarnings::had_no_warnings();
done_testing;