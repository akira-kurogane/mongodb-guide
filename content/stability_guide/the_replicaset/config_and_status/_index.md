+++
title = "Replica set configuration and status"
menuTitle = "Conf & status"
date =  2019-10-19T09:00:00+09:00
weight = 5
draft = true
+++


## Config

The **replica set config** is the BSON document in _local_ db's _system.replset_ collection. You usually see this running [rs.conf()](https://docs.mongodb.com/manual/reference/method/rs.conf/) (= [replSetGetConfig](https://docs.mongodb.com/manual/reference/command/replSetGetConfig/)).

From a code perspective it is better to say that the replica set config is the in-memory replica set configuration that is always synchronized between the live nodes, and _system.replset_ collection is just the on-disk serialization. But as you will see `db.system.replset.findOne({}, {"_id": false})` and `rs.conf()` look the same.

There are a few replication options in the mongod [configuration file](https://docs.mongodb.com/manual/reference/configuration-options/index.html#replication-options), but except for the replica set name these do not overlap with the properties in the replica set config. If the name in the configuration file and the _system.replset_ collection disagree the mongod will abort on startup, so I tend to see the configuration file copy of the name as a safety check only.

### Modifying

To update the replica set config there is no command that allows you to update just one value at a time. You must take a copy of the existing configuration, modify parts of that object, then send the whole document back in a [rs.reconfig()](https://docs.mongodb.com/manual/reference/method/rs.reconfig/#rs.reconfig) (= [replSetReconfig](https://docs.mongodb.com/manual/reference/command/replSetReconfig/)) command.

## Status

Replica set status (seen with [rs.status()](https://docs.mongodb.com/manual/reference/method/rs.status/) = [replSetGetStatus](https://docs.mongodb.com/manual/reference/command/replSetGetStatus/)) includes a "members" array with the hosts identified by hostname (or IP address) and port (as you get from `rs.conf()`) but is otherwise the living state that would disappear instantly with a `mongod` process's shutdown. The most important information to you is probably which the replication state the members are in. Next is how close the replication in secondaries is following the primary.

### Replication states

PRIMARY, SECONDARY and ARBITER are the only running-as-normal [replication states](https://docs.mongodb.com/manual/reference/replica-states/).

The others (STARTUP2, RECOVERY, UNKNOWN, ROLLBACK, DOWN, REMOVED, and the more-or-less never seen STARTUP) are error or transitional phases.

While a node is running normally as a primary:

* Clients will send all write commands to it
* Clients will also send read commands to it if they have (the default) "primary". "primaryPreferred" and "nearest" read preference reads may also be coming.
* At least one of the secondaries will be tailing its oplog. (Not necessarily all of them &ndash; they usually do, but they can also tail from another secondaryif it allows the replication to go faster.)
* It monitors the highest optime the fastest secondary has proceeded to, the maxim optime half (or more) of the secondaries have proceeded to by the information they pass back in the repeating getmore commands from the secondaries and the heartbeats.
* When w:2+ or w:majority commands they are queued after they complete on the primary. Only when an asynchronous process tracking the progress for the relevant number of secondaries reaches the same opTime (or later) does the command complete, including sending the net response back to the client.

While a node is running normally as a secondary:

* It will reject all writes made by any user except the internal '\_\_system' user
* It will reject reads unless 'slaveOk' field in the request is true.
* The replication thread(s) begin a find on the local db's _oplog.rs_ collection with the clause that the "ts" field > the latest "ts" value they already have in their own oplog collection. This find will have the "tailable" and "awaitData" options set to true. Until there is an error this find will be continued with repeated `getmore` commands.
* The replication thread(s) apply the ops from the source using the (wait for it) [applyOps](https://docs.mongodb.com/manual/reference/command/applyOps/) command.
