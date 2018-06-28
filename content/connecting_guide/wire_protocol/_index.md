+++
title = "The wire protocol"
date =  2018-05-30T23:23:56+10:00
weight = 10
+++

In one way all communication with mongodb databases is identical. No matter which client you use, what type of data you store in mongodb, whether you're running a query or an update, using the aggregation pipeline, issuing an administration command, all the data will be sent and received in a request/response protocol over TCP/IP called the MongoDB Wire Protocol.

The Mongo(DB) Wire protocol is a simple, application-layer socket protocol that is transported by the TCP/IP internet protocol, similar to SSH, HTTP, SNMP, etc. (Unix domain sockets can also be used (<a href="https://docs.mongodb.com/manual/reference/configuration-options/#net-unixdomainsocket-options">reference</a>) by local clients, but in a distributed system those are rare.)


Client |     | Socket data |     |Server
------ | --- | ----------- | --- | ------
find(..) | → | OP_QUERY struct | → | find
         | ← | OP_REPLY | ← | 

The format of data in MongoDB Wire Protocol requests and responses is relatively simple, but it is a binary one and is far from being human-readable.

OP_QUERY example:

Field datatype | name | description
-------------- | ---- | --------
Raw int32 | int32 messageLength | total message size, including this
Raw int32 | int32 requestID | identifier for this message
Raw int32 | int32 responseTo | (will be empty as this is a request)
Raw int32 | int32 opCode | Will be 2004 for OP_QUERY
Raw int32 | int32 flags | bit vector of query options. See below for details.
Raw cstring | cstring fullCollectionName ; | "dbname.collectionname".<br>(N.b. dbname will be "$cmd" if some command that doesn't have naturally require a db namespace is being shoe-horned into a OP_QUERY, .e.g. <a href="https://docs.mongodb.com/manual/reference/command/isMaster/">isMaster,</a> <a href="https://docs.mongodb.com/manual/reference/command/hostInfo/">hostInfo</a>, <a href="https://docs.mongodb.com/manual/reference/command/serverStatus/">serverStatus</a>.)
Raw int32 | int32 numberToSkip | number of documents to skip
Raw int32 | int32 numberToReturn | number of documents to return in the first OP_REPLY batch
BSON document | query | query object. See below for details.
BSON document | returnFieldsSelector | Optional. Selector indicating the fields to return. See below for details.

You can, if you like, communicate with a mongod or mongos node by opening a TCP socket and sending commands formatted to the MongoDB Wire Protocol, wait for the response, read it out, send again, etc.

You can also 'sniff' the data exchange between clients and the database, at least if you are running with network encryption disabled (i.e. ssl = disabled). Wireshark: https://wiki.wireshark.org/Mongo

Of course there is no need - there are mongo drivers for many programming languages that perform the task of doing this for you.
