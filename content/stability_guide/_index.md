+++
title = "Making MongoDB stable"
date = 2018-05-31T13:47:51+10:00
weight = 140
chapter = true
draft = true
pre = "<b>4. </b>"
+++

### Chapter 4

# Making MongoDB Stable

MongoDB gives your application high availability through three features:

* Replication between replica set nodes
* Automatic endpoint switching in the drivers
* Tunable client-side preferences for write and read guarantees

Backup and restore: There is no _inbuilt_ backup command (at least in MongoDB's own versions). It is up to you to create them by executing commands externally. Restoring is even more difficult.

Performance stability: A MongoDB DBA does not tune this, but there are implementation details to know (especially the flush-to-disk cycle) that both application developer and DBAs should know.

{{% children %}}
