use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::Chronicle',
    AUTHOR           => q{Binary.com <support@binary.com>},
    VERSION_FROM     => 'lib/Data/Chronicle/Writer.pm',
    ABSTRACT_FROM    => 'lib/Data/Chronicle/Writer.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::NoWarnings' => 0,
        'Date::Utility' => 0,
        'Moose' => 0,
        'JSON' => 0,
        'DBI' => 0,
        'Test::PostgreSQL' => 0,
        'Test::Mock::Redis' => 0,
    },
    PREREQ_PM => {
        'Date::Utility' => 0,
        'Moose' => 0,
        'JSON' => 0,
        'DBI' => 0,
        'Test::PostgreSQL' => 0,
        'Test::Mock::Redis' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Chronicle-*' },
);
