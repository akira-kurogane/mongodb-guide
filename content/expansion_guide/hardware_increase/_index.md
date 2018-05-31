+++
title = "Hardware - the simple answer"
date =  2018-05-31T16:03:04+10:00
draft = true
weight = 10
+++

## Hardware - the simple answer, as far as RAM allows

My first recommendation for upsizing is MongoDB-agnostic. Although MongoDB supports distribution with Sharding, don't jump the gun to use sharding if you can simply replace your servers with bigger ones, or stick more RAM or attach larger disks to them.


Because MongoDB uses replica sets it's easy to add a new larger server into it, remove one of the smaller ones when the new one's initial sync is complete, and repeat until, say, all your old servers have been replaced by their upgrades.


It may not be the right solution if:

- The database load is already reaching a disk bottleneck that is caused by the volume of updates alone.
  - More RAM will reduce the read load on the disk so this is specifically about the write load.
  - But bigger disk may mean faster disk - it depends on the variety used, e.g. RAID 5, SSD in large size 
  - And a new disk may be faster just as a result of being a newer model. Check the specs.
- The database load has a CPU bottleneck. This is unlikely given the number of cores in today's typical servers, but not impossible either. Simply see your CPU metrics to assess this.


~~It might be a less appealing solution if:~~

- ~~You'd prefer to pay less and buy servers of the same spec as in your starting replica set~~
- ~~In a corporate setting I have seen cases where many servers of a certain size are available without any finance friction, say because a sales contract obtained a certain model at discount, or standardized hardware is preferred as a policy~~
