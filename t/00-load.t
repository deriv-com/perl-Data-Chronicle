#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Chronicle' ) || print "Bail out!\n";
}

diag( "Testing Data::Chronicle $Data::Chronicle::VERSION, Perl $], $^X" );
