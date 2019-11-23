+++
title = "Replica set elections"
menuTitle = "Elections"
date =  2019-10-19T09:00:00+09:00
weight = 10
+++

By far the most common cause of an election is when you are restarting `mongod` nodes yourself for maintenance reasons. Restarting nodes whilst doing a version upgrade for example.

The end result of an election is that one node will receive the most votes, or equal votes but then go higher by a tie-breaker mechanism, and it will 'step up' to the PRIMARY role. The amount of time could be milliseconds, but can also be up to 10 seconds plus the extra milliseconds for network lag and replica set config updating. (It could even a few more seconds above 10 seconds if all nodes are overloaded by high write load.) The election "term" number in the distributed replica set config is incremented too.

Only the members of the replica set itself participate in the election. With the exception that a user can instruct a primary to step down (which is only a trigger) clients or `mongos` nodes do not participate in an election at all. They will only react to what the nodes do (see [automatic switching](../driver_failover/)).

The members continual monitoring of each other's status (or notice a lack of response) is primarily by two types of network command.

* "heartbeat" commands
* The repeated `getmore` commands fetching the oplog

There will be an election when:

* A majority of the members lose contact with the primary node because:
  * (QUICK:) It was shut down, or
  * (SLOW:) It crashed abruptly, or
  * (SLOW:) The network is blocked or broken
* (SLOW election:) The primary is too slow to respond (because load on its server is beyond capacity)
* (QUICK election:) The primary 'steps down' from that role
  * Because it is instructed to (i.e. `rs.stepDown()` was executed), or
  * It stepped down from primary role autonomously because its egress network traffic to a majority of the other members was blocked even though the ingress traffic was still arriving. E.g. there was some 'firewall fun' where it could send to (and get responses back from) the other members but they could not do vice versa.
* (QUICK election:) Any node detects that the current primary has a lower priority value than itself. (This can only happen when there has been replica set configuration modification. By default all nodes have the same priority.)
* (QUICK election:) After one election if a 'losing' secondary realizes it has caught up on the oplog faster than the newly elected primary can during its catch-up phase then the more up-to-date secondary will trigger another election so it can take over instead.

A new mongod node being added to a replicaset does not cause an election. If an election did happen at that time it would be for an indirect reason.

Any nodes that missed the election will detect they are out of date by seeing that the term other nodes have in their replica set config is higher, and will accept that new config. And relinquish primary role immediately if they still thought they had it. This would be unlikely as they usually would have stepped down when they lost contact to the majority of the other replica set members, but it might have happened if that old primary's egress network connections remained opened whilst the ingress ones were blocked. (Another 'firewall fun' situation.)
