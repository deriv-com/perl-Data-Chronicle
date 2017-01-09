package Data::Chronicle::Writer;

use 5.014;
use strict;
use warnings;
use Data::Chronicle;

=head1 NAME

Data::Chronicle::Writer - Provides writing to an efficient data storage for volatile and time-based data

=cut

our $VERSION = $Data::Chronicle::VERSION;

=head1 DESCRIPTION

This module contains helper methods which can be used to store and retrieve information
on an efficient storage with below properties:

=over 4

=item B<Timeliness>

It is assumed that data to be stored are time-based meaning they change over time and the latest version is most important for us.

=item B<Efficient>

The module uses Redis cache to provide efficient data storage and retrieval.

=item B<Persistent>

In addition to caching every incoming data, it is also stored in PostgresSQL for future retrieval.

=item B<Transparent>

This modules hides all the details about distribution, caching, database structure and ... from developer. He only needs to call a method
to save data and another method to retrieve it. All the underlying complexities are handled by the module.

=back

=head1 Example

 my $d = get_some_log_data();

 my $chronicle_w = Data::Chronicle::Writer->new( 
    cache_writer => $writer,
    db_handle    => $dbh,
    ttl          => 86400);

 my $chronicle_r = Data::Chronicle::Reader->new( 
    cache_reader => $reader,
    db_handle    => $dbh);


 #store data into Chronicle - each time we call `set` it will also store 
 #a copy of the data for historical data retrieval
 $chronicle_w->set("log_files", "syslog", $d);

 #retrieve latest data stored for syslog under log_files category
 my $dt = $chronicle_r->get("log_files", "syslog");

 #find historical data for `syslog` at given point in time
 my $some_old_data = $chronicle_r->get_for("log_files", "syslog", $epoch1);

=cut

use JSON;
use Date::Utility;
use Moose;

has [qw(cache_writer db_handle)] => (
    is      => 'ro',
    default => undef,
);

has 'ttl' => (
    isa      => 'Int',
    is       => 'ro',
    default  => undef,
);

=head3 C<< set("category1", "name1", $value1)  >>

Store a piece of data "value1" under key "category1::name1" in Pg and Redis.

=cut

sub set {
    my $self     = shift;
    my $category = shift;
    my $name     = shift;
    my $value    = shift;
    my $rec_date = shift;
    my $archive  = shift;

    $archive //= 1;    #default to true
    die "Recorded date is undefined" unless $rec_date;
    die "Recorded date is not a Date::Utility object" if ref $rec_date ne 'Date::Utility';
    die "Cannot store undefined values in Chronicle!" unless defined $value;
    die "You can only store hash-ref or array-ref in Chronicle!" unless (ref $value eq 'ARRAY' or ref $value eq 'HASH');

    $value = JSON::to_json($value);

    my $key = $category . '::' . $name;
    $self->cache_writer->set($key => $value, $self->ttl ? ('EX' => $self->ttl) : ());
    $self->_archive($category, $name, $value, $rec_date) if $archive and $self->db_handle;

    return 1;
}

sub _archive {
    my $self     = shift;
    my $category = shift;
    my $name     = shift;
    my $value    = shift;
    my $rec_date = shift;

    my $db_timestamp = $rec_date->db_timestamp;

    return $self->db_handle->prepare(<<'SQL')->execute($category, $name, $value, $db_timestamp);
WITH ups AS (
    UPDATE chronicle
       SET value=$3
     WHERE timestamp=$4
       AND category=$1
       AND name=$2
 RETURNING *
)
INSERT INTO chronicle (timestamp, category, name, value)
SELECT $4, $1, $2, $3
 WHERE NOT EXISTS (SELECT * FROM ups)
SQL
}

no Moose;

=head1 AUTHOR

Binary.com, C<< <support at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-chronicle at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Chronicle>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Chronicle::Writer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Chronicle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Chronicle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Chronicle>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Chronicle/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Binary.com.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
