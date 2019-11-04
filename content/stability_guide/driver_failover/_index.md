+++
title = "Driver automatic failover"
date =  2019-10-14T08:23:26+09:00
weight = 30
draft = true
+++

When there is an [election](../the_replicaset/elections) writes from clients must start going to the new primary. Likewise reads using the (default) primary read preference must go there, and reads using secondary read preference should be directed only to nodes that are secondary after the election.

What you need to do is: Nothing, nothing at all. It is handled for the clients automatically, and DBAs do not have to install or configure anything extra either.

The reason is the MongoDB drivers have the code that does it. This is another design decision implemented from very early in MongoDB's development, and was something that you could rely on without even noticing it even before MongoDB became well-known.

Given how many different languages MongoDB drivers were implemented in this is impressive. Network programming is asynchronous by nature and has a menagerie of error possibilities that can't be abstracted away, but the same complex switching logic was achieved in each language.

Originally development of the drivers only had to follow the wire protocol, but this left too much open for interpretation. From about the time of v3.0 MongoDB started created strict specifications for the theoretical 'Meta' driver and then the implementations of officially-supported drivers converged in the finer details too.

* [Server discovery and monitoring](https://github.com/mongodb/specifications/blob/master/source/server-discovery-and-monitoring/server-discovery-and-monitoring.rst)
* [Server selection](https://github.com/mongodb/specifications/blob/master/source/server-selection/server-selection.rst)
* [Driver read preferences](https://github.com/mongodb/specifications/blob/master/source/driver-read-preferences.rst)

If you are connecting to sharded cluster you are connecting to `mongos` nodes of course. In this case the `mongos` node does the automatic switching of the traffic to the new primary node after an election, but don't think of this as being different &ndash; it is using the same driver code (the C++ one) as clients would if they were connecting to the replica set directly.

