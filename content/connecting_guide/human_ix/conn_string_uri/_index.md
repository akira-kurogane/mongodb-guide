+++
title = "Connection string URI"
description = "MongoDB connection URI syntax"
date =  2018-05-30T23:14:32+10:00
weight = 5
+++


Ladies and gentlemen, I present to you _(drum roll)_ the standard MongoDB connection string URI:

<tt>mongodb://\[user\[:password\]@\]host\[:port\]\[,host\[:port\]\]\*\[/\[database\_name\]\[?\[conn\_option\[=value\]\]\[,conn\_option\[=value\]\]\*\]\]</tt>

At this point I expect all readers fall into one of following three groups:

1. _'Yuck. Punctuation vomit or what?'_
2. _'Ah, a URI like those ones for [ODBC](https://tools.ietf.org/html/draft-patrick-lambert-odbc-uri-scheme-00) / [Postgresql](https://www.postgresql.org/docs/9.3/libpq-connect.html) / [MS SQL server](https://docs.microsoft.com/en-us/sql/connect/jdbc/building-the-connection-url?view=sql-server-2017) / [MySQL](https://dev.mysql.com/doc/refman/8.0/en/connecting-using-uri-or-key-value-pairs.html#connecting-using-uri) etc. ...'_
3. _'You've neglected the DNS/SRV seedlist format, moron'_

If you are in group #1 I'm sorry but I can't 'sexy it up' in any way, no matter how hard I try. At it's simplest the URI you type is short and easy, but as you add authentication credentials and options it can't help becoming more and more verbose.

If you are in group #2 one special difference to note is that multiple host+port tuples can be accepted, instead of just one. More on this in the [Replicaset host-list syntax](#replicaset-host-list-syntax) section below.

If you are in group #3, cool, you're done, you don't need this page and you can move onto the next. (And I'll say I'm envious that you've been given enough privileges to add and modify SRV records on your DNS servers.)

#### Non-URI formats

You may have used (or will see on other sites) ways to connect without using the URI format. E.g. with the shell `mongo --host myhost.my.domain:27018`, or a code sample something like `var conn = new MongoClient("myhost.my.domain", 27018)'`.

These are just for legacy compatibility and/or to give some abbreviation. In reality those arguments will be immediately reformatted into a new 'mongodb://...' string and that is what the driver code will use.

As well as being deprecated the non-URI formats differ in syntax from one language driver to another. Let's just stop thinking about them a.s.a.p.

## Examples

### Basic / minimal

To make a new connection a MongoDB client needs at least the two things any TCP connection requires - a hostname (or it's IP address) and a port.

<tt>mongodb://myhost.my.domain:27017/</tt>

What if host or port are wrong or the MongoDB server can't be reached because of a network problem?
The TCP connection will never be established and the error message will be something along those lines. E.g. 'socket exception', and not 'MongoDB server failure'.

### Adding access credentials

If the DB requires users to authenticate with username and password then add those too, delimited by ":" and suffixed with "@".

<tt>mongodb://**akira:secret@**myhost.my.domain:27017/</tt>

{{% notice tip %}}
If you have tricky punctuation characters in your password that would wreck the URI parsing (i.e. "/", ":", "@", or "%") encode those with [percent encoding](https://tools.ietf.org/html/rfc3986#section-2.1). E.g. "EatMyH@t" -> "EatMyH%40t".
{{% /notice %}}

By default/convention the user authentication credentials are saved in the "**admin**" db on the server. This is the assumed default for mongodb connection URIs too, so you can leave it absent (as above) most of the time. 

But if the "akira" user authentication credentials had been created in in the "orderhist" user databases then that db name is needed as shown below. The first format sets the starting db namespace (that commands such as find, db stats, etc. will act in) as "orderhist" and the auth source db is assumed to be the same. The second format allows for the starting db namespace to be something else.

<tt>mongodb://akira:secret@myhost.my.domain:27017/**orderhist**</tt>

<tt>mongodb://akira:secret@myhost.my.domain:27017/\[some\_other\_db\]**?authSource=orderhist**</tt>

{{% notice warning %}}
I do not recommended created user auth outside the "admin" db &ndash; the above is just for reference in case you are accessing a non-conventional MongoDB cluster or replica set.
{{% /notice %}}

What if the user credentials are rejected (e.g. unknown username or wrong password)? 
The TCP socket connection will be established for a moment. Over the TCP connection the username and it's hashed password will be sent. If they fail the server will send the failure reply ('user unauthorized', etc.) in a MongoDB Wire protocol OP_REPLY (or rereply OP_MSG?), then close the socket immediately.

_**Q.** "What if the MongoDB server requires user authentication but the client fails to give username and password?"_

Unintuitively the TCP connection will be established and stay open! It will remain open to allow the client to send db user credentials. Any command other than _[<tt>authenticate</tt>](https://docs.mongodb.com/manual/reference/command/authenticate/)_ or the ones drivers need for basic state detection (_[<tt>isMaster</tt>](https://docs.mongodb.com/manual/reference/command/isMaster/)_, _[<tt>hostInfo</tt>](https://docs.mongodb.com/manual/reference/command/hostInfo/)_, etc.) will be rejected with an authorization error.

### Connection options

For convenience the full syntax again:

<tt>mongodb://\[user\[:password\]@\]host\[:port\]\[,host\[:port\]\]\*\[/\[database\_name\]\[?\[conn\_option\[=value\]\]\[,conn\_option\[=value\]\]\*\]\]</tt>

After the "/" that follows host\[:port\] all the values are optional. The first is the user_auth_db_name (see above), then whether that db name is present or not put "?" before any other parameters. Delimit with an "\&", like in a HTTP URI.

**Example** If the DB was configured to accept connections that use SSL network encryption then from the client side we add the "ssl=true" to instruct the driver to do that. If we want the driver to make a pool of at least 50 database connections that different threads in the application can share, then we could add "minPoolSize=50".

<tt>mongodb://akira:secret@myhost.my.domain:27017/?ssl=true\&minPoolSize=50</tt>

{{% notice note %}}
Staring in v4.2 there is general renaming of "SSL" as "TLS" in mongod/mongos server node and mongo shell options, and the MongoDB documentation in general ([link](https://docs.mongodb.com/master/release-notes/4.2/#add-tls-options)). It seems the connection string URI options are going to remain _ssl\*_ though.
{{% /notice %}}

#### Most common options

... as I recall seeing / expect should be used.

- [replicaSet](https://docs.mongodb.com/manual/reference/connection-string/#replica-set-option). Invalid if connecting to a sharded cluster. But otherwise use this ensure you establish a replicaset connection that will failover in the event of a primary switch, rather than just having a standalone connection.
- [authSource](https://docs.mongodb.com/manual/reference/connection-string/#urioption.authSource)
- [readPreference](https://docs.mongodb.com/manual/reference/connection-string/#urioption.readPreference) N.b. I'd recommend not using this; i.e. always use the default, which is doing reads only from primaries. But I know many users do secondary reads (I hypothesize a habit learned from completely different, non-db systems that have load balancers) and this is the option for setting that.
- [w](https://docs.mongodb.com/manual/reference/connection-string/#urioption.w) (write concern level)
- [connectTimeoutMS](https://docs.mongodb.com/manual/reference/connection-string/#urioption.connectTimeoutMS)
- [retryWrites](https://docs.mongodb.com/manual/reference/connection-string/#urioption.retryWrites) If there is a primary switch this will automatically retry once (but only once) any writes to the old primary that errored because it crashed / was stepped down in the middle of the first attempt.


#### The (one) connection parameter that can't go in the URI

Using the "ssl=true" option in my example above requires me to point out that, unfortunately, one of the SSL options (but so far only this one) need to be passed to the client connection function outside of URI. SSL connections usually require a CA cert file and/or a client certificate file to be used, and you can't put a local filepath into an URI. (Well maybe you can, but this isn't standardizedyet.)

A C++ driver example of adding an SSL client PEM file is shown below. The point is simply that the minimal case of needing just one line with the URI connection in it is no longer possible; we have to prepare and add an extra connection option alongside it when the client connection object is constructed.

```C++
mongocxx::options::ssl ssl_opts{};
ssl_opts.pem_file("client.pem");

mongocxx::options::client client_opts{};
client_opts.ssl_opts(ssl_opts);

auto client = mongocxx::client{uri{"mongodb://host1/?..<other_parameters>..&ssl=true"}, client_opts};
```

### Replicaset host-list syntax

The MongoDB connection URIs above could be syntactically valid as HTTP URLs if we simply replace "mongodb" with "http", but it isn't always so. There is one key HTTP-like rule-breaker which is necessitated by the fact that MongoDB typically uses replica sets. If a replica set has hosts hostA, hostB and hostC, each using the same port 27017, then the URI can accept them in a comma-separated list:

<tt>mongodb://akira:secret@hostA:27017,hostB:27017,hostC:27017/?ssl=true\&minPoolSize=50</tt>

If you only specify one host (let's say hostA:27017) that the driver can connect to it will automatically query for the full replica set configuration/status. After that it will be aware of all the other hosts, so it might seem unnecessary to specify multiple hosts to connect to. But imagine a time when hostA was shut down for maintenance, or had crashed, and the client has to establish a new connection. 

### Defaults

Most of of the URI parameters have default values.

Most useful to know is that the hostname default is **localhost**, and the port default is **27017**. It's these that make it possible for clients to connect without specifying any connection options at all. All you need to do is to set up a mongod or mongos process running on port 27017 with no user authentication on the same server as the client.
