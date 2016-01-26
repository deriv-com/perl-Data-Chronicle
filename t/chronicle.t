use strict;
use warnings;

use DBI;
use Test::MockTime qw(:all);
use Test::More tests => 7;
use Test::Exception;
use Test::NoWarnings;
use Data::Chronicle;
use Date::Utility;
use Test::Mock::Redis;

my $redis = Test::Mock::Redis->new(server => 'whatever');
my $dbh = DBI->connect( 'DBI:Mock:', '', '' )
               || die "Cannot create handle: $DBI::errstr\n";

my $d = { sample1 => [1, 2, 3],
          sample2 => [4, 5, 6],
          sample3 => [7, 8, 9] };

my $d_old = { sample1 => [2, 3, 5],
          sample2 => [6, 6, 14],
          sample3 => [9, 12, 13] };

my $first_save_epoch = time;

my $chronicle = Data::Chronicle->new(
    cache_writer    => $redis,
    cache_reader    => $redis,
    db_handle       => $dbh);

is $chronicle->set("vol_surface", "frxUSDJPY", $d), 1, "data is stored without problem";
is $chronicle->set("vol_surface", "frxUSDJPY-old", $d_old, Date::Utility->new(0)), 1, "data is stored without problem when specifying recorded date";

$dbh->{mock_add_resultset} = [
      [ 'id', 'category', 'name', 'value' ],
        [ 1, 'vol_surface', 'frxUSDJPY-old', JSON::to_json($d_old) ]
    ];

my $old_data = $chronicle->get_for("vol_surface", "frxUSDJPY-old", 0);
is_deeply $old_data, $d_old, "data stored using recorded_date is retrieved successfully";

$dbh->{mock_add_resultset} = [
      [ 'id', 'category', 'name', 'value' ],
        [ 1, 'vol_surface', 'frxUSDJPY', JSON::to_json($d) ]
    ];

my $d2 = $chronicle->get("vol_surface", "frxUSDJPY");
is_deeply $d, $d2, "data retrieval works";

my $d3 = { xsample1 => [10, 20, 30],
          xsample2 => [40, 50, 60],
          xsample3 => [70, 80, 90] };

is $chronicle->set("vol_surface", "frxUSDJPY", $d3), 1, "new version of the data is stored without problem";

$dbh->{mock_add_resultset} = [
      [ 'id', 'category', 'name', 'value' ],
        [ 1, 'vol_surface', 'frxUSDJPY', JSON::to_json($d3) ]
    ];

my $d4 = $chronicle->get("vol_surface", "frxUSDJPY");
is_deeply $d3, $d4, "data retrieval works for the new version";
