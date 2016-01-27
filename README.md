# Chronicle storage system (perl-Data-Chronicle)

This module contains helper methods which can be used to store and retrieve information
on an efficient storage with below properties:



* **Timeliness**
It is assumed that data to be stored are time-based meaning they change over time and the latest version is most important for us.
Many data structures in our system fall into this category (For example Volatility Surfaces, Interest Rate information, ...).

* **Efficient**:
The module uses Redis cache to provide efficient data storage and retrieval.

* **Persistent**:
In addition to caching every incoming data, it is also stored in PostgresSQL for future retrieval.

* **Distributed**:
These data are stored in distributed storage so they will be replicated to other servers instantly.

* **Transparent**:
This modules hides all the details about distribution, caching, database structure and ... from developer. He only needs to call a method
to save data and another method to retrieve it. All the underlying complexities are handled by the module.


There are four important methods this module provides:

* **set**:
Given a category, name and value stores the JSONified value in Redis and PostgreSQL database under "category::name" group and also stores current
system time as the timestamp for the data (Which can be used for future retrieval if we want to get data as of a specific time). Note that the value
MUST be either hash-ref or array-ref.

* **get**:
Given a category and name returns the latest version of the data according to current Redis cache

* **get_for**:
Given a category, name and timestamp returns version of data under "category::name" as of the given date (using a DB lookup).

* **get_for_period**:
Given a category, name, start_timestamp and end_timestamp returns an array-ref containing all data stored between given period for the given "category::name" (using a DB lookup).

## Examples ##

```
my $d = get_some_data();

my $chronicle = Data::Chronicle->new( 
    cache_reader => $reader, 
    cache_writer => $writer,
    db_handle    => $dbh);

#store data into Chronicle
$chronicle->set("vol_surface", "frxUSDJPY", $d);

#retrieve latest data stored for "vol_surface" and "frxUSDJPY"
my $dt = $chronicle->get("vol_surface", "frxUSDJPY");

#find vol_surface for frxUSDJPY as of a specific date
my $some_old_data = $chronicle->get_for("vol_surface", "frxUSDJPY", $epoch1);

```
