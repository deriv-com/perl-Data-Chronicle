use strict;
use warnings;

use Date::Utility;
use Test::More;
use Test::Exception;
use Data::Chronicle::Writer;
use Data::Chronicle::Subscriber;
require Test::NoWarnings;
use YAML::XS;

package t::InMemoryCache {
    use Moose;

    has cache => (
        is      => 'ro',
        default => sub { {} });

    sub multi { }
    sub exec  { }

    sub set {
        my ($self, $key, $value) = @_;
        $self->cache->{"set::$key"} = $value;
    }

    sub publish {
        my ($self, $key, $value) = @_;
        $self->cache->{"publish::$key"} = $value;
    }

    sub subscribe {
        my ($self, $key, $subref) = @_;
        $self->cache->{"subscribe::$key"} = $subref;
    }

    sub unsubscribe {
        my ($self, $key, $subref) = @_;
        delete $self->cache->{"subscribe::$key"};
    }

    sub ping { }
};

my $data = {sample => 'data'};

subtest "Call Set after dropping the connection" => sub {
    my $cache  = t::InMemoryCache->new;
    my $writer = Data::Chronicle::Writer->new(
        cache_writer   => $cache,
        publish_on_set => 1,
        ttl            => 86400
    );

    # calling set() which will call mset() and put the flag `multi`
    $writer->set('namespace', 'category', $data, Date::Utility->new, 0);

    my $connection_config = YAML::XS::LoadFile($ENV{BOM_TEST_REDIS_REPLICATED} // '/etc/rmg/redis-replicated.yml');
    my $port              = $connection_config->{port};
    my $password          = $connection_config->{password} ? $connection_config->{password} : '';

    # Kill All Client Connections
    my $cmd = "redis-cli -p $port -a $password CLIENT KILL TYPE normal";
    system($cmd);

    # call set again after dropping the connection
    # check the connection will be recreated
    lives_ok(sub { $writer->set('namespace', 'category', $data, Date::Utility->new, 0) }, 'expecting to live');

};

done_testing;
