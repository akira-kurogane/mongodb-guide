+++
title = "Replica sets"
date =  2018-05-31T15:23:26+10:00
weight = 5
+++

## Downtime-proofing

Replica sets have been around for a while before MongoDB. The older name for those was master-slave sets. Clients write to the one master node (or a node that is acting as master for those particular records) and the slaves copy the same updates.

Relational databases that existed before MongoDB had to 'bolt it on' after their original design was already set. MongoDB and other distributed databases or key-value stores of the same generation, such as Cassandra and Redis, had the mechanics for replication built in from the start. (To be pedantic: they were in mind from the start and were programmed in during the beta-phase development.)

The original purpose of the older master-slave replication added onto relational databases is being a guarantee against data being lost if the master node crashes and can't be recovered.

To that other features were added:

* The ability to manually switch the nodes, making a slave take on the primary role and directing the client traffic to the new master.
* Even better- Automatic switching if there is sudden death of a master.
* Optionally directing reads to secondaries so the read load is spread around.

Replication in MongoDB had all of those things built in from the start. This better start has allowed things to evolve further too.

Replication is also part of the assumed maintenance procedure. No downtime to do upgrades or config changes &ndash; do **rolling restarts** where the new binary version or per-node config settings are changed one by one.

