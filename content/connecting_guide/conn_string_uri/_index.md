+++
title = "Connection string URI"
date =  2018-05-30T23:14:32+10:00
weight = 5
+++

Although the first versions of the drivers and the mongo shell accepted different formats, over time they standardized on supporting the following RFC 3986-style URI syntax:

`mongodb:[//[user[:password]@]host[:port]][/[user_auth_db_name][?[conn_option[=value]][,conn_option[=value]]*]]`

To make a new connection a MongoDB client needs at least the two things any TCP connection requires - a hostname (or it's IP address) and a port.

`mongodb://myhost.my.domain:27017/`

What if host or port are wrong or the MongoDB server can't be reached because of a network problem?
The TCP connection will never be established and the error is simply that a TCP socket connection is never established.

If the DB requires users to authenticate with username and password then add those too.

`mongodb://akira:secret@myhost.my.domain:27017/`

What if the user credentials are rejected (e.g. unknown username or wrong password)? 
The TCP socket connection will be established. Over the TCP connection the username and it's hashed password will be sent. If they fail the server will send the failure reply ('user unauthorized', etc.) in a MongoDB Wire protocol OP_REPLY, then close the socket immediately.

_**Q.** "What if the MongoDB server requires user authentication but the client fails to give username and password?"_

Unintuitively the TCP connection will be established and stay open! It will remain open to allow the client send credentials. Any command other than authenticate will be rejected with an authorization error. In this state it's a green light for TCP conversations to continue, whilst being a red light for database access.

One optional (and becoming deprecated) parameter can come after the right-most "/". All other connection options will follow a "?" after that.

If the DB requires clients to use SSL network encryption then we add the "ssl=true" to instruct the driver to do that. If we want the driver to make a pool of at least 50 database connections that different threads in the application can share, then we could add "minPoolSize=50". Multiple options are concatenated with the "&".

`mongodb://akira:secret@myhost.my.domain:port/?ssl=true&minPoolSize=50`

The "ssl=true" option points out that, unfortunately, there are some connection-related options that MongoDB connection URI cannot be used to list. SSL connections usually require a CA cert file and/or a client certificate file to be used. The way this attached to a connection is driver-specific.

The MongoDB connection URIs above could be syntactically valid as HTTP URLs if we simply replace "mongodb" with "http", but it isn't always so. There is one key rule-breaker which is necessitated by the fact that MongoDB typically uses replica sets. If a replica set has hosts hostA, hostB and hostC, each using the same port 27017, then the URI can accept them in a comma-separated list:

`mongodb://akira:secret@hostA:27017,hostB:27017,hostC:27017/?ssl=true&minPoolSize=50`

If you only specify one host (let's say hostA:27017) that the driver can connect to it will automatically query for the full replica set configuration/status. After that it will be aware of all the other hosts, so it might seem unnecessary to specify multiple hosts to connect to. But imagine a time when hostA was shut down for maintenance, or had crashed, and the client has to establish a new connection. 

### Defaults

Most of of the URI parameters have default values.

Most useful to know is that the hostname default is localhost, and the port default is 27017. It's these that make it possible for clients to connect without specifying any connection options at all. All you need to do is to set up a mongod or mongos process running on port 27017 with no user authentication on the same server as the client and you can pull off the same trick.