+++
title = "Sharding for expansion"
date =  2018-05-31T16:05:23+10:00
draft = true
weight = 15
+++

### Basic overview

\[the sharding picture]


\['You on a replica set']  - \[rs.status() example]


\['You migrated to a cluster of a single shard'] - \[sh.status() example]


- \[rs.status() example on mongos shows it fails]


\['Your first new shard'] - \[sh.status() example]

### The mongos node

Once you've sharded your data the clients need the ability to read and update the collection data from multiple mongod nodes at any given time, where with a replica set, or a standalone node, they used to communicate with only one before.


In a MongoDB cluster what is used to facilitate this is the mongos router node. A client connects to a mongos node like it was a single, large standalone mongod node, or connects to a pool of them to get mongos node failover. This failover mechanism is different than a replica set election failover of course, but at the same time is still a very similar concept.


Either way the connection object provided by the MongoDB driver API will appear the same as if it were a replica set connection or a connection to a standalone. The user data reached through that connection will opaquely appear as if the user collections were all on one massive server rather than partitioned between several shard replica sets.


The system databases (local, admin and config) will not be the same when you connect via a mongos node. Firstly there will be no local database. The "config" database will be a new addition - replica sets don't have it. And the "admin" db will be hosted on the same servers as the configdb and the information there, particularly user and role info, will be the one authority for that sort of data when clients need it.


The mongos node will read the sharding configuration metadata from the config db, and the authentication and authority information plus a few cluster-wide system variables from the admin db. It will especially keep track of the current shard version number and share that with the shards each time it interacts with them. If the mongos node and a shard detect they have different versions the 'older' one will contact the config server and get the config metadata updates it needs to be current. Then they will continue with the same command, or if the updates require it, the command will be re-routed by the mongos node to the shard that now has the collection data the first shard held at some older time.


So even though collection data may be dynamically moving between shards the mongos node will be routing to the right place at all times by systematically updating it's copy of the cluster's metadata from the config db.

### The config db / the config servers

The "config" db is a set of collections, just like any other database.


\[List the collections and/or show the object relationships between shard, databases, collections, chunks]


The config servers are a replica set, holding this relatively small database, whose purpose is to hold the "config" db and "admin" db that is shared by the entire cluster. The clients of the config db can be humans, making a connection manually to look at it, but mainly they are the mongos nodes and the shard nodes, particularly the primary node of each shard's replica set.

### Sharded collections, shard keys, etc.

Although sharding can be used to distribute a database A to one shard, database B to the next, etc. sharding's main purpose is to partition the data of very large collections. Collections whose active data set exceeds the RAM available on any one of your servers.

TODO
