+++
title = "Hardware - the simple answer"
date =  2018-05-31T16:03:04+10:00
draft = true
weight = 10
+++

## Hardware - the simple answer, as far as RAM allows

My first recommendation for upsizing is MongoDB-agnostic. Although MongoDB supports distribution with Sharding, don't jump the gun to use it if it would be simple to replace your servers with bigger ones, or stick more RAM into them, or attach faster disks to them. I don't mean upgrade to non-commodity servers or get bleeding-edge peripherals for them &ndash; stay on approximately the same $$-per-GB level &ndash; just get more of those gigabytes.

Because MongoDB uses replica sets it's easy to add a new larger server into it, remove one of the smaller ones when the new one's initial sync is complete, and repeat until all your old servers have been replaced by their upgrades. No downtime at all except for the 'blip' of a primary switch.

Stepping up server size may not help if the database _write load_ is already reaching a _disk write bottleneck_ that is caused by the volume of updates alone. A bigger server with disks that are excxactly the same specs as the older server's will be no improvement. In fact it could be worse - improved throughput in CPU and memory is likely to make the 'traffic jam' for disk even more spectactular. In this case you should A) shard (to get more write capacity through parallelization) or B) attach significantly better disk to your servers.

If your disk is saturated by a high _read load_ on the other hand, getting more memory will immediately reduce that. Well, it wont reduce reads at times that the mongod process must inevitably read everything. Eg. #1 directly after a restart when it is fetching document data from disk to RAM cache. Eg. #2 if the data storage size > file buffer cache in RAM and you run a full dump say for the nightly backups. But outside of those cases more RAM is a big, and quick, win.

If you only have the option of getting more servers of the same size rather than bigger ones &ndash; (TODO LINK) sharding.

### Caveat

Hardware improvements are linear. Applications with bad database access patterns are exponentially greedy. If the db resource usage isn't sane hardware upsizing will win a battle but you'll still lose the war.
