+++
title = "What MongoDB lacks between here and perfection"
menuTitle = "Not perfect yet"
date = 2019-11-10T21:00:00+09:00
draft = true
weight = 30
+++

Having used MongoDB for a long time, and having helped a _lot_ of other people use it too, I've come to picture what would need to be better about MongoDB for it to be perfect.

In software perfection means being taken for granted, in most cases. And this page is along those lines. I'm imagining what MongoDB would be if it was so good that nobody noticed any issues that weren't about hardware/physics.

## Distributed system admin

There is too much manual effort left in MongoDB still. Peoples lives are being wasted a little bit by it &ndash; they might not care because for the most part they get paid for that wastage &ndash; but given how many MongoDB DBA's there are around the world that is a couple of human lifetimes lost and that's not really excusable is it? On the spectrum of software MongoDB is currently on the good end, there is lot more that is dead guilty of eating human lives in the hundreds (I'm looking at you, framework developers). But it will be legacy software soon enough.

To do maintenance of MongoDB still requires too much time because the steps involved require synchronous MongoDB and OS modification steps, spread over various servers. They must be separate physical servers for HA guarantee, but that means server inaccess block OS steps from being run from one spot.

The logical DB (whether NSRS or cluster) is a conceptually a single process to the app, just that it's access jumps around between different IP addresses. So why can't the DBA operate it the same way?

The reason why it can't now is:

- OS steps can't be executed for all nodes in one spot
  - A mongod user on one server isn't going to have the unix access to other servers, especially new ones. Unix admins need to create the user, install the binaries, set up the storage and mount it for the new mongod's data directory. For reconfig the config file needs to be rewritten, and the mongod process restarted. For restarting the process the mongod or mongos node can't do it itself, again a local unix user must.
- A unix user cannot gain MongoDB privileges (userAdmin, dbAdmin, root, \_\_sytem, etc.) for the whole cluster. Even if you did have distributed unix shell without restriction you'd have to do hack doing a rolling restart with disconnected, manipulate-whilst-standalone user admin to get that in whilst keeping the cluster up. It's possible manually and definitely with downtime, I don't want to suggest that MongoDB prevents this against hackers, but it is unsuitable as an automation technique.

Ideally you could do all these from not just one spot, but any single spot (preferably not even having to be a db server itself:

- Add or remove new nodes by mongo shell functions with just the new hostname and port as the minimal argument. (This is imagining the new node is prepared prepared with passwordless access (presumably SSH) and has storage already set suitably, OR the mongod can use a VM or MAAS API to get to the same point)
- Reconfigure the static config (i.e. what will be used at restart of the mongod/mongos process) from any node via mongo commands, not unix ones
- Restart mongod nodes (even if they have full config and data live reset modes there will still need to be whole process kill and rebirths at times for some unexpected reason) 

## Inbuilt backup and restore, with smart remote store format

Clusters don't have an inbuilt, consistent-snapshot-making backup function.

They don't have a re-init-from-snapshot command either.

And on top of the above we would like continuous oplog capture and PITR feature as well.

The remote storage archive format should be something we can pull collection-level metadata data from accurately, instantly (i.e. size, count) and hopefully pull the data by arbitrary order. I.e. should be something that allows exact data to be dumped by itself. To BSON files as well, not just inside a mongod's data directory.

## Inbuilt metric visualization tools

A timeseries server over FTDC data, with automatic conversion to lower resolutions. By default the resolutions is 1s, this should down-rezed to say to 10s for > 4 days, 60s for > 7 days to 32 days.

Plus a GUI to view it. It should be a client for the timeseries servers in the whole cluster?

A third party metrics server that stores it someplace outside the db servers (because they might be moved) is usually needed to, say something like prometheus. Third-party metric servers like prometheus should be able to consume it too.

## At-a-glance client DB load analysis

An ability to picture which db commands (by signature) add the load. Including historically - eg. to have the ability to figure out what it is that starting 73 mins ago that made the shit hit the fan.

## HW cost visulation

An ability to picture what it would take to hit the HW bottlenecks.

## Centralized diagnostic log access, log file management.

MongoDB clusters have a lot of nodes which have their own log files. It should be possible to fetch them all to any one location. More ideally it would be possible to to tail and/or grep them inplace and only send the matching lines to the requestor.

Being able to determine the total size of log files (included the archived ones) and truncating would also be needed to make this less timeconsuming.

## A better shell, for admin

The mongo javascript shell is more useful than a no-web-technologies db engineer would probably think. But it just hasn't evolved at all since a few years in. This doesn't hurt people looking to access the user dbs and collections, but an administrator can't access all the nodes in parallel for example. There is a way to open extra connections but that is awkward and not well-documented. E.g. if you wanted to write a script that resized the oplog, or starts and stops profiling on all nodes, the best way to do that now is to make a unix shell script that opens up a different mongo shell session to each node.
