#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Data::Chronicle::Reader' ) || print "Bail out!\n";
    use_ok( 'Data::Chronicle::Writer' ) || print "Bail out!\n";
}

diag( "Testing Data::Chronicle $Data::Chronicle::Writer::VERSION, Perl $], $^X" );
