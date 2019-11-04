+++
title = "Making MongoDB stable"
date = 2018-05-31T13:47:51+10:00
weight = 140
chapter = true
pre = "<b>4. </b>"
+++

### Chapter 4

# Making MongoDB Stable

**High availability**

MongoDB gives your application high availability through two features:

* [Replication between replica set nodes](the_replicaset/), with automatic switching of the primary role when necessary.
* [Automatic endpoint switching in the drivers](driver_failover/)

A related feature is:

* [Tunable client-side preferences for write and read guarantees](write_and_read_concern/)
