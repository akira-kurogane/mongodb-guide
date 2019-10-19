+++
title = "Performance stability"
date =  2018-05-31T15:23:26+10:00
weight = 70
+++

This chapter's title implies that MongDB has a performance stability issue. It does not.

MongoDB performance stability is primarily about application load stability. And this is true of all database's I've worked with.

DBAs: you must not take responsibility **EVER** for application load instability. Unless it is your responsibility to be the development team's manager as well, in which case make sure you get that in writing and a pay rise to match.

### Exceptions to the above

#### Checkpoints

When there are a lot of writes (think many GB/s per minute as a rough guide) there is variation in the MongoDB performance during checkpoints. Checkpoints are when the changes that have been made in memory are flushed to disk. If you get slow command latency appearing once per minute for a second or several, and you see disk utilization rising to 100% at the same time, this would be what it is.

#### Shard balancing

One internal thing that can add real load to a given pair of shards is the movement of data (and deletion clean-up after) between shards to balance the number of chunks for sharded collections between them. ("chunks" are ranges of docs up to a certain size, default 64MB.)

One chunk being moved is barely noticeable. But when you shard a collection for the first time, or add a new shard, they will happen continuously for a long time. This means there will be batch inserts on the recipient shard(s) and deletes on the donating shard(s). A signficant impact if there is already continually heavy load from the users on the database.

Don't overlook the cost of deletes, and be aware they get asynchronously scheduled to run after. ASAP if not too much load, but it could be delayed for a long time.

#### TTL Indexes

Two things to be aware of regarding time-to-live indexes

* Once per minute. The TTL index deletes are executed by a background thread that sleeps for 60 secs by default before iterating all indexes with the "expireAfterSeconds" field. If the deletes take, say, 0.3s in total each minute there will be 60.3s cycle of deletes appearing. This is a different cycle to checkpoints. Eventually they will overlap, then move apart, then move over again, etc.
* If a large number of docs match the TTL clause there will be no mercy - the mongod node will process the deletes for all them at once. And deletes are basically as costly as updates (they have to be - the documents have to be read to get the values that are the keys that should be removed from the secondary indexes). It is a common mistake to create a new TTL index to keep a collection smaller and not think that the first TTL 'pass' might be deleting a huge fraction of the collection in one go.

If you would like a much more constant cost and can accept a policy based on _size_ rather than a timestamp-value limit, please use capped collections.

#### The OS performance is unstable

This is not really a DB issue of course. But if your DB server is a shared physical server you may have other big applications competing for the same resources, affecting the mongod process's top processing rate.

Another form of OS instability is when the kernel or library performance is not even. This is rare given how well-written the Linux kernel is, but I can think of at least two known issues.

* Memory alloc libs manage large page lists - when there is large memory (say 256GB+) the number of pages can be large, and an occasional defrag of those pages can be heavily blocking to user processes until it completes.
* Filesystems are not all equal. Ext4 (or Ext3) are not as good as XFS, because they can also block when managing large number of file pages.
