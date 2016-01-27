package Data::Chronicle::Mock;

use 5.006;
use strict;
use warnings;

use Data::Chronicle;
use Test::Mock::Redis;
use Test::postgresql;
use DBI;

sub get_mocked_chronicle {
    my $redis = Test::Mock::Redis->new(server => 'whatever');

    my $pgsql = Test::postgresql->new();
    my $dbh = DBI->connect($pgsql->dsn);

    my $stmt = qq(CREATE TABLE chronicle (
      id bigserial,
      timestamp TIMESTAMP DEFAULT NOW(),
      category VARCHAR(255),
      name VARCHAR(255),
      value TEXT,
      PRIMARY KEY(id),
      CONSTRAINT search_index UNIQUE(category,name,timestamp)
    ););

    $dbh->do($stmt);

    my $chronicle = Data::Chronicle->new(
        cache_writer    => $redis,
        cache_reader    => $redis,
        db_handle       => $dbh);

    $chronicle->meta->add_attribute(
        dummy => (
            accessor => 'dummy',
        )
    );

    $chronicle->dummy($pgsql);

    return $chronicle;
}

1;
