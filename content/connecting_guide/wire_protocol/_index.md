+++
title = "The wire protocol"
date =  2018-05-30T23:23:56+10:00
weight = 10
+++

In one way all communication with mongodb databases is identical. No matter which client you use, what type of data you store in mongodb, whether you're running a query or an update, using the aggregation pipeline, issuing an administration command, all the data will be sent and received in a request/response protocol over TCP/IP called the MongoDB Wire Protocol.

\[TODO: Picture of OP_COMMAND body being sent from client server to db server, with OP_REPLY going back\]

The format of data in MongoDB Wire Protocol requests and responses is relatively simple, but it is a binary one and is far from being human-readable.

\[TODO: Picture of the same OP_COMMAND data from above, broken out into it's header segment, which explodes into it's flag values, and the command body in bson, exploded into the bson length and type headers plus the data in each field\]

You can, if you like, communicate with a mongod or mongos node by opening a TCP socket and sending commands formatted to the MongoDB Wire Protocol, wait for the response, read it out, send again, etc.

You can also 'sniff' the data exchange between clients and the database, at least if you are running with network encryption disabled (i.e. ssl = disabled).

Of course there is no need - there are mongo drivers for many programming languages that perform the task of doing this for you.