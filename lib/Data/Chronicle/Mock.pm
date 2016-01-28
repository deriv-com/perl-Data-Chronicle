package Data::Chronicle::Mock;

use 5.006;
use strict;
use warnings;

use DBI;
use Test::PostgreSQL;
use Test::Mock::Redis;
use Data::Chronicle::Reader;
use Data::Chronicle::Writer;

sub get_mocked_chronicle {
    my $redis = Test::Mock::Redis->new(server => 'whatever');

    my $pgsql = Test::PostgreSQL->new();
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

    my $chronicle_r = Data::Chronicle::Reader->new(
        cache_reader    => $redis,
        db_handle       => $dbh);

    my $chronicle_w = Data::Chronicle::Writer->new(
        cache_writer    => $redis,
        db_handle       => $dbh);


    #we need to store a reference to $pgsql or else, as soon as this method
    #is returned, it will be destroyed and connection will be lost.
    $chronicle_r->meta->add_attribute(
        dummy => (
            accessor => 'dummy',
        )
    );

    $chronicle_w->meta->add_attribute(
        dummy => (
            accessor => 'dummy',
        )
    );

    $chronicle_r->dummy($pgsql);
    $chronicle_w->dummy($pgsql);

    return ($chronicle_r, $chronicle_w);
}

1;
