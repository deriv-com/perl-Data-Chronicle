#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Data::Chronicle' ) || print "Bail out!\n";
    use_ok( 'Data::Chronicle::Reader' ) || print "Bail out!\n";
    use_ok( 'Data::Chronicle::Writer' ) || print "Bail out!\n";
    use_ok( 'Data::Chronicle::Mock' ) || print "Bail out!\n";
}

diag( "Testing Data::Chronicle $Data::Chronicle::VERSION, Perl $], $^X" );
