+++
title = "Connection string URI"
description = "The syntax of the MongoDB connection URI"
date =  2018-05-30T23:14:32+10:00
weight = 5
+++

Although there were some differences between the connection argument formats used in the early versions of the drivers, over time they standardized on supporting the following RFC 3986-style URI syntax:

<tt>mongodb:\[//\[user\[:password\]@\]host\[:port\]\]\[/\[user\_auth\_db\_name\]\[?\[conn\_option\[=value\]\]\[,conn\_option\[=value\]\]\*\]\]`</tt>

You might know that the mongo shell can accept a different format, but those are command line arguments. What is used internally in the driver is the URI format above. And since v3.4 or so it also accepts the URI format in the --host argument. MongoDB tools such mongodump came on board a little later.

To make a new connection a MongoDB client needs at least the two things any TCP connection requires - a hostname (or it's IP address) and a port.

<tt>mongodb://myhost.my.domain:27017/</tt>

What if host or port are wrong or the MongoDB server can't be reached because of a network problem?
The TCP connection will never be established and the error message will be something along those lines. E.g. 'socket exception', and not 'MongoDB server failure'.

If the DB requires users to authenticate with username and password then add those too.

<tt>mongodb://**akira:secret@**myhost.my.domain:27017/</tt>

By default/convention the user authentication credentials are saved in the "admin" db on the server. This is the assumed default for mongodb connection URIs too, so you can leave it absent (as above) most of the time. 
But if the "akira" user authentication credentials had been created in in the "orderhist" user databases then that db name is needed as shown below. I do not recommended created user auth outside the "admin" &ndash; the below is just for reference in case you are accessing a non-conventional MongoDB cluster or replica set.

<tt>mongodb://akira:secret@myhost.my.domain:27017/**orderhist**</tt>
<tt>mongodb://akira:secret@myhost.my.domain:27017/**?authSource=orderhist**</tt>

What if the user credentials are rejected (e.g. unknown username or wrong password)? 
The TCP socket connection will be established for a moment. Over the TCP connection the username and it's hashed password will be sent. If they fail the server will send the failure reply ('user unauthorized', etc.) in a MongoDB Wire protocol OP_REPLY (or rereply OP_MSG?), then close the socket immediately.

_**Q.** "What if the MongoDB server requires user authentication but the client fails to give username and password?"_

Unintuitively the TCP connection will be established and stay open! It will remain open to allow the client send credentials. Any command other than authenticate will be rejected with an authorization error. In this state it's a green light for TCP conversations to continue, whilst being a red light for database access.

#### Connection URI Parameters

For convenience the full syntax again:

<tt>mongodb:\[//\[user\[:password\]@\]host\[:port\]\]\[/\[user\_auth\_db\_name\]\[?\[conn\_option\[=value\]\]\[,conn\_option\[=value\]\]\*\]\]`</tt>

After the "/" that follows host\[:port\] all the values are optional. The first is the user_auth_db_name (see above), then whether that db name is present or not put "?" before any other parameters. Delimit with an "\&", like in a HTTP URI.

TODO: replace SSL with TLS everywhere in this document.

**Example** If the DB was configured to accept connections that use SSL network encryption then from the client side we add the "ssl=true" to instruct the driver to do that. If we want the driver to make a pool of at least 50 database connections that different threads in the application can share, then we could add "minPoolSize=50".

<tt>mongodb://akira:secret@myhost.my.domain:27017/?ssl=true\&minPoolSize=50</tt>

#### The (one) parameter that can't go in the URI

Using the "ssl=true" option in my example above requires me to point out that, unfortunately, one of the SSL options (but so far only this one) need to be passed to the client connection function outside of URI. SSL connections usually require a CA cert file and/or a client certificate file to be used, and you can't put a local filepath into an URI. (Well maybe you can, but this isn't standardized.)

A C++ driver example of adding an SSL client PEM file:
```C++
mongocxx::options::ssl ssl_opts{};
ssl_opts.pem_file("client.pem");

mongocxx::options::client client_opts{};
client_opts.ssl_opts(ssl_opts);

auto client = mongocxx::client{
    uri{"mongodb://host1/?..<other_parameters>..&ssl=true"}, client_opts};
```

#### Replicaset host-list syntax

The MongoDB connection URIs above could be syntactically valid as HTTP URLs if we simply replace "mongodb" with "http", but it isn't always so. There is one key HTTP-like rule-breaker which is necessitated by the fact that MongoDB typically uses replica sets. If a replica set has hosts hostA, hostB and hostC, each using the same port 27017, then the URI can accept them in a comma-separated list:

<tt>mongodb://akira:secret@hostA:27017,hostB:27017,hostC:27017/?ssl=true\&minPoolSize=50</tt>

If you only specify one host (let's say hostA:27017) that the driver can connect to it will automatically query for the full replica set configuration/status. After that it will be aware of all the other hosts, so it might seem unnecessary to specify multiple hosts to connect to. But imagine a time when hostA was shut down for maintenance, or had crashed, and the client has to establish a new connection. 

### Defaults

Most of of the URI parameters have default values.

Most useful to know is that the hostname default is **localhost**, and the port default is **27017**. It's these that make it possible for clients to connect without specifying any connection options at all. All you need to do is to set up a mongod or mongos process running on port 27017 with no user authentication on the same server as the client.
