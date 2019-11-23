---
title: "Replication"
date: 2019-11-23T21:45:46+09:00
---

No write in a user database happens without a idempotent form of the same write being committed into the _oplog.rs_ collection in the _local_ db. This is also true for any write in the _admin_, or _config_ databases &ndash; i.e. all databases except the "local" database itself.

It can be accessed like a normal collection, but obviously the oplog is special. The idempotent operation log it contains is a safe source by which data can be identically replicated to secondaries.

- Even if those secondaries lag a lot behind (just so as long as they are not beyond the oldest oplog doc)
- Even if they are stopped and restarted cold
- Even if there are intermittent network errors that force the secondary to read again
- Even if there was a split-microsecond kill between a storage-engine applying the writes in the storage layer and the same being applied in the secondary's oplog. (The first oplog fetching after the secondary is restarted will apply the same update.)

### Sync source / Chained replication

Typically a secondary replicates from the primary, but it doesn't necessarily have to be so. Secondaries can select another secondary if the ping times to the secondary are 'good' (presumably when it less than the ping time to the primary).

This will potentially increase the replication lag of the secondary lower down in the change, but only by network lag (e.g. 10's of ms for cross-continental cases). Potentially it will make it better &ndash; there might have been network congestion making the primary ping time slower in the first place. If you want you can disable it, but it's hard for it go wrong.

### Oplog trivia 

The _oplog.rs_ has some other special properties. They are not important to the topic of stability but I thought I should mention them here.

- It is the only collection that doesn't have an "\_id" index, or any index at all.
- It is a capped collection, i.e. the oldest documents get automatically deleted.
- The "$natural" order of the capped collection is relied on to serve the oplog documents in the right order. The "ts" field follows this order perfectly by code enforcement, not by a hidden primary-key datastructure constraint or something like that.
- The "ts" field is the MongoDB "[Timestamp](https://docs.mongodb.com/manual/reference/bson-types/index.html#timestamps)" type which can be used in normal collections, but it is not a wall-clock like timestamp. The first 4 bytes are the unix epoch timevalue (seconds) and the last 4 bytes are a monotically increasing counter resetting to 1 each second. (0 never gets used, as far as I've seen.)
- To make deletions off the end of the oplog smoother with the WiredTiger API 'oplog stones' are added to the in-memory representation of the WiredTiger table for the oplog. When you have a big oplog the full scanning of the oplog to create these milestone markers is required after every startup and may take several minutes. (Original ticket: [SERVER-19551](https://jira.mongodb.org/browse/SERVER-19551).)
