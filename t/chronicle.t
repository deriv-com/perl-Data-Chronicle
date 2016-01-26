use strict;
use warnings;

use Test::MockTime qw(:all);
use Test::More tests => 8;
use Test::Exception;
use Test::NoWarnings;
use Time::HiRes;
use Time::Local ();
use Data::Chronicle;
use Date::Utility;


my $d = { sample1 => [1, 2, 3],
          sample2 => [4, 5, 6],
          sample3 => [7, 8, 9] };

my $d_old = { sample1 => [2, 3, 5],
          sample2 => [6, 6, 14],
          sample3 => [9, 12, 13] };

my $first_save_epoch = time;
is BOM::System::Chronicle::set("vol_surface", "frxUSDJPY", $d), 1, "data is stored without problem";
is BOM::System::Chronicle::set("vol_surface", "frxUSDJPY-old", $d_old, Date::Utility->new(0)), 1, "data is stored without problem when specifying recorded date";

my $old_data = BOM::System::Chronicle::get_for("vol_surface", "frxUSDJPY-old", 0);
is_deeply $old_data, $d_old, "data stored using recorded_date is retrieved successfully";

my $d2 = BOM::System::Chronicle::get("vol_surface", "frxUSDJPY");
is_deeply $d, $d2, "data retrieval works";

sleep 1;

my $d3 = { xsample1 => [10, 20, 30],
          xsample2 => [40, 50, 60],
          xsample3 => [70, 80, 90] };

is BOM::System::Chronicle::set("vol_surface", "frxUSDJPY", $d3), 1, "new version of the data is stored without problem";

my $d4 = BOM::System::Chronicle::get("vol_surface", "frxUSDJPY");
is_deeply $d3, $d4, "data retrieval works for the new version";

subtest 'set for a specific date' => sub {
    my $now = Date::Utility->new;
    $d->{sample4} = 'something';
    my $ten_minutes_ago = $now->minus_time_interval('10m');
    lives_ok {
        set_absolute_time($ten_minutes_ago->epoch);
        ok BOM::System::Chronicle::set("vol_surface", "frxUSDJPY", $d), 'saved';
        restore_time;

        my $d = BOM::System::Chronicle::get_for('vol_surface', 'frxUSDJPY', $ten_minutes_ago);
        is $d->{sample4}, 'something', 'data retrieved';
    } 'save and fetch from postgres chronicle';
};
