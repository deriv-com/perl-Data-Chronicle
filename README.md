# NAME

Data::Chronicle - Chronicle storage system

# DESCRIPTION

This package contains three modules (Reader, Writer, and Subscriber) which can be used to store and retrieve information
on an efficient storage with below properties:

## Timeliness

It is assumed that data to be stored are time-based meaning they change over time and the latest version is most important for us.

## Efficient

The module uses Redis cache to provide efficient data storage and retrieval.

## Persistent

In addition to caching every incoming data, it is also stored in PostgreSQL for future retrieval.

## Transparent

This modules hides all the details about caching, database structure and ... from developer. He only needs to call a method
to save data and another method to retrieve it. All the underlying complexities are handled by the module.

Note that you will need to pass \`cache\_writer\`, \`cache\_reader\` and \`dbic\` to the \`Data::Chronicle::Reader/Writer\` modules. These three arguments, provide access to your Redis and PostgreSQL which will be used by Chronicle modules.

\`cache\_writer\` and \`cache\_reader\` should be to be able to get/set given data under given key (both of type string). \`dbic\` should be capable to store and retrieve data with \`category\`,\`name\` in addition to the timestamp of data insertion. So it should be able to retrieve data for a specific timestamp, category and name. Category, name and data are all string. This can easily be achieved by defining a table in you database containing these columns: \`timestamp, category, name, value\`.

# METHODS

There are four important methods this module provides:

## ["set" in Data::Chronicle::Writer](https://metacpan.org/pod/Data%3A%3AChronicle%3A%3AWriter#set)

Given a category, name and value stores the JSONified value in Redis and PostgreSQL database under "category::name" group and also stores current
system time as the timestamp for the data (Which can be used for future retrieval if we want to get data as of a specific time). Note that the value
MUST be either hash-ref or array-ref.

    $writer->set("category1", "name1", "value1");
    $writer->set("category1", "name2", "value2", Date::Utility->new("2016-08-01 00:06:00"));

## ["mset" in Data::Chronicle::Writer](https://metacpan.org/pod/Data%3A%3AChronicle%3A%3AWriter#mset)

Given multiple categories, names and values atomically performs the set operation on each corresponding category, name, value set.

    $writer->mset([["category1", "name1", $value1], ["category2, "name2", $value2], ...]);

## ["get" in Data::Chronicle::Reader](https://metacpan.org/pod/Data%3A%3AChronicle%3A%3AReader#get)

Given a category and name returns the latest version of the data according to current Redis cache

    my $value1 = $reader->get("category1, "name1"); #value1

## ["mget" in Data::Chronicle::Reader](https://metacpan.org/pod/Data%3A%3AChronicle%3A%3AReader#mget)

Given multiple categories and name atomically performs the get operation on each corresponding category, name set.

    my @values = $reader->mget([["category1", "name1"], ["category2", "name2"], ...])

## ["get\_for" in Data::Chronicle::Reader](https://metacpan.org/pod/Data%3A%3AChronicle%3A%3AReader#get_for)

Given a category, name and timestamp returns version of data under "category::name" as of the given date (using a DB lookup).

    my $some_old_data = $reader->get_for("category1", "name2", Date::Utility->new("2016-08-01 00:06:00"));

## ["get\_for\_period" in Data::Chronicle::Reader](https://metacpan.org/pod/Data%3A%3AChronicle%3A%3AReader#get_for_period)

Given a category, name, start\_timestamp and end\_timestamp returns an array-ref containing all data stored between given period for the given "category::name" (using a DB lookup).

    my $arrayref = $reader->get_for_period("category1", "name2", Date::Utility->new("2015-08-01 00:06:00"), Date::Utility->new("2015-08-01 00:06:00"));

## ["get\_history" in Data::Chronicle::Reader](https://metacpan.org/pod/Data%3A%3AChronicle%3A%3AReader#get_history)

Given a category, name, and revision returns version of the data the specified number of revisions in the past.
If revision 0 is chosen, the latest version of the data will be returned.
If revision 1 is chosen, the previous version of the data will be returned.

    my $some_old_data = $reader->get_for("category1", "name2", 2);

## ["subscribe" in Data::Chronicle::Subscriber](https://metacpan.org/pod/Data%3A%3AChronicle%3A%3ASubscriber#subscribe)

Given a category, name, and callback assigns the callback to be called when a new value is set for the specified category and name (if the writer has publish\_on\_set enabled).

    $subscriber->subscribe("category1", "name2", sub { print 'Hello World' });

## ["unsubscribe" in Data::Chronicle::Subscriber](https://metacpan.org/pod/Data%3A%3AChronicle%3A%3ASubscriber#unsubscribe)

Given a category, name, clears the callbacks associated with the specified category and name.

    $subscriber->unsubscribe("category1", "name2");

# EXAMPLES

    my $d = get_some_log_data();

    my $chronicle_w = Data::Chronicle::Writer->new(
        cache_writer => $writer,
        dbic         => $dbic);

    my $chronicle_r = Data::Chronicle::Reader->new(
        cache_reader => $reader,
        dbic         => $dbic);


    #store data into Chronicle - each time we call `set` it will also store
    #a copy of the data for historical data retrieval
    $chronicle_w->set("log_files", "syslog", $d);

    #retrieve latest data stored for syslog under log_files category
    my $dt = $chronicle_r->get("log_files", "syslog");

    #find historical data for `syslog` at given point in time
    my $some_old_data = $chronicle_r->get_for("log_files", "syslog", $epoch1);
