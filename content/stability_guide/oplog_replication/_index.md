+++
title = "MongoDB Oplog"
date =  2019-10-14T06:23:26+09:00
weight = 10
draft = true
+++

## The Oplog collection

User updates to the user collections are tied, in synchronous-executing code, with making a matching **oplog document** that describes the same user insert, update or delete A) in its true _effect_ and B) in an _idempotent_ style. The commit in the storage engine for the user collection writes only happens after the oplog documents are created, I believe.

The documents appear in the _local_ db's _oplog.rs_ collection. This is a more-or-less normal and user-accessible collection.

It wasn't necessary that this been done &dnash; it could have been left in a human-unreabled binary format, and/or unreachable by any user interface. But that it was done this way has made it very easy to see and understand it.

### Idempotency

`db.my\_collection.update({"fstate": "xyz"}, {"$set": {...}})`

becomes the following in the oplog if we assume that the clause `{"fstate": "xyz"}` matches just the two documents shown.

`....`
`....`
TODO

### Replication process from primary to secondaries

The latency for reading oplog from the primary (or another secondary acting as the sync source) is very low.
_TODO find the python test with microsecond averages_
 
If nothing else this demonstrates 10gen's claim that BSON format allows fast serialization and deserialization is true.
