# perl-Data-Chronicle
Chronicle storage system




This module contains helper methods which can be used to store and retrieve information
on an efficient storage with below properties:

=over 4

=item B<Timeliness>

It is assumed that data to be stored are time-based meaning they change over time and the latest version is most important for us.
Many data structures in our system fall into this category (For example Volatility Surfaces, Interest Rate information, ...).

=item B<Efficient>

The module uses Redis cache to provide efficient data storage and retrieval.

=item B<Persistent>

In addition to caching every incoming data, it is also stored in PostgresSQL for future retrieval.

=item B<Distributed>

These data are stored in distributed storage so they will be replicated to other servers instantly.

=item B<Transparent>

This modules hides all the details about distribution, caching, database structure and ... from developer. He only needs to call a method
to save data and another method to retrieve it. All the underlying complexities are handled by the module.

=back

There are three important methods this module provides:

=over 4

=item C<set>

Given a category, name and value stores the JSONified value in Redis and PostgreSQL database under "category::name" group and also stores current
system time as the timestamp for the data (Which can be used for future retrieval if we want to get data as of a specific time). Note that the value
MUST be either hash-ref or array-ref.

=item C<get>

Given a category and name returns the latest version of the data according to current Redis cache

=item C<get_for>

Given a category, name and timestamp returns version of data under "category::name" as of the given date (using a DB lookup).

=back

=head1 Example

 my $d = get_some_data();

 #store data into Chronicle
 BOM::System::Chronicle::set("vol_surface", "frxUSDJPY", $d);

 #retrieve latest data stored for "vol_surface" and "frxUSDJPY"
 my $dt = BOM::System::Chronicle::set("vol_surface", "frxUSDJPY");

 #find vol_surface for frxUSDJPY as of a specific date
 my $some_old_data = get_for("vol_surface", "frxUSDJPY", $epoch1);

