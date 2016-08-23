#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Data::Chronicle' );
    use_ok( 'Data::Chronicle::Reader' );
    use_ok( 'Data::Chronicle::Writer' );
    use_ok( 'Data::Chronicle::Mock' );
}

diag( "Testing Data::Chronicle $Data::Chronicle::VERSION, Perl $], $^X" );
