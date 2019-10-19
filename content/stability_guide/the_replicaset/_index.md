+++
title = "Replica sets"
date =  2018-05-31T15:23:26+10:00
weight = 5
draft = true
+++

{{% children %}}

## Downtime-proofing

Replica sets have been around for a while before MongoDB. The usual name for those is Master-Slave pairs or sets. Clients write to the one master node (or a node that is acting as master for those particular records) and the slaves copy the same updates.

The relational databases that existed before MongoDB had to bolt this on after their original design was already set. MongoDB and other distributed databases or key-value stores of the same generation, such as Cassandra and Redis, are built with the mechanics for replication built in from the start.

The original purpose of the older master-slave replication added onto relational databases is being a guarantee against data being lost if the master node crashes and can't be recovered.

To that other features were added:

* The ability to manually switch the nodes, making a slave take on the primary role and directing the client traffic to the new master.
* Even better- Automatic switching if there is sudden death of a master.
* Optionally directing reads to secondaries so the read load is spread around.

Replication in MongoDB is all of those things, just it is built in from the start. This better start has allowed things to evolve further too.

Replication is also part of the assumed maintenance procedure. No downtime to do upgrades or config changes &ndash; do **rolling restarts** where the new binary version or per-node config settings are changed one by one.

## Terminology

**PRIMARY**, **SECONDARY** and ARBITER are the only running-as-normal [replication states](https://docs.mongodb.com/manual/reference/replica-states/).

The others (STARTUP2, RECOVERY, UNKNOWN, ROLLBACK, DOWN, REMOVED, and the more-or-less never seen STARTUP) are error or transitional phases.

The replica set **config** is the BSON document in _local_ db's _system.replset_ collection. You usually see this running `rs.conf()` (= `replSetGetConfig`).

Replica set **status** (seen with `rs.status()` = `replSetGetStatus`) is the living state at the moment, state that would disappear instantly with a `mongod` process's shutdown. First and foremost it includes which replication state (PRIMARY, SECONDARY, or others) the members are in. Next is how close the replication in secondaries is following the primary.

See [Replica set configuration and status](config_and_status) for more details.

**Sharding**: Trick entry! Sharding has nothing to do with replication. `mongos` nodes rely on shard replica sets to just work. They pass through different consistency preferences like write concerns and read preferences through to shards regardless of which shard or shards it may be. Sharding is completely orthogonal to replication and vice versa.

