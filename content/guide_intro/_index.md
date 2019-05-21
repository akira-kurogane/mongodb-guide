+++
title = "What you can do with MongoDB"
date = 2018-05-24T15:23:42+10:00
weight = 110
chapter = true
draft =  true
pre = "<b>1. </b>"
+++

### Chapter 1

# What you can do with MongoDB

### Develop faster

Mostly everyone who has used one of the 'NoSQL' databases which came into popularity post-2010, of which MongoDB is the most popular, already appreciate this. But for those of you still using relational databases the key reasons for the higher development productivity are:

- Reduced lines of code
- You don't need to perform a full mental switch between the paradigm of your application's data structure v.s. the server-side data storage mechanism.

You are a <a href="https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3900881/">glucose-powered computer</a> and context change is expensive. Only so much glucose can be converted by your neurons into thought-sparks a day, so save your sparks for things that are more valuable to you.

#### Broadest client language support

Want to do things quicker by using more developers / tools? For example your Web front-end has been created in language _X_, but the data scientists that will mine gold from the big data need to use language _Y_? MongoDB has got you covered - C, C++, C#, Erlang, Go, Java, Node.js, Perl, PHP, Python, Ruby and Scala are supported.

The simplicity of the client API will also reduce the _technical debt_ of your codebase significantly. To the original developer this may seem unimportant, but for the development department that owns the technology it is more important than the speed of new feature development.

### Write and read data faster

This has always been my favourite feature of MongoDB.

Let's take a trip back in time, to 2010 or so. The first MongoDB version I was using was 1.6, and I had a task to load a dataset of some 10's of GB. I can't remember the client program, but it might have been mongoimport.

As the data load progressed:

1. I was pleasantly surprised by the rate of document inserts.
2. I was a little shocked by the rate of inserts.
3. I was getting suspicious of the insertion rate. Was the counter just a client-side lie? (No, I confirmed server-side.)
4. I started sanity-checking the numbers, by datasize too. I arrived at a figure ~30 MB/s.
5. 30 MB/s reminded me of something. At the time commodity HDD specs advertised 30MB/s write speeds. I checked the server's disk specs. They were the same 30 MB/s rate.

The takeaway for me was _the hardware specs were no longer some sort of fantasy numbers way above the user's reality_, which was a given for RDBMS-using application developers until then. If the hardware manufacturers have engineered their equipment to flick _x_ million or billion electrons per second from one silicon nano-suburb to another, I could now use _all_ those electrons for my data purposes.

With the change in hardware-land to SSDs, and furthermore MongoDB's change to the WiredTiger storage engine, MongoDB users now enjoy throughput and latency somewhat higher than the puny 30MB/s figure above. But the key point is to expect MongoDB to redline your _hardware's_ throughput and/or latency by the volume of _your_ data being moved, without the database software eating a noticeable chunk of the server capacity for itself.

### Go big

The growth of e-commerce and social networking in the noughties lead to many thousands of businesses having a problem that was limited to few before. This was dataset sizes that exceeded the capacity of the biggest server you could afford to buy. If your user base was large, well, you either became one of the few companies that engineered around this by getting good at _distributed data_ in your server application, or you limited data detail and panicked about whether you'd last the next 2 months before the server RAM and disk upgrades were delivered.

The NoSQL databases for the most part came with a huge benefit for this businesses / websites - easy data partitioning. You don't program the distribution logic in your application, instead you leave it to the database driver or the db server node you connect to.

The NoSQL databases mostly also included TODO LINK replication, making automatic database failover another thing that happens on the other 'side' of the database driver.

Which field(s) should be chosen to partition data is still a very important decision that you need to make for yourself, but after that your MongoDB cluster will allow you to grow your data up to (<tt>Single server storage size</tt>) x (100's).

### Get bigger quickly 

Starting with a single, unsharded MongoDB replica set is not a problem if suddenly you find you data volume growing. A single replica set can be dynamically converted, in configuration, to being the first shard of a one-shard MongoDB cluster. With no downtime or any reinsertion of your user data you can gain the ability to add new shards. Add one, two, as many as are needed, and the first cluster's data will be redistributed automatically until the number of documents in collections is balanced between the shards.

This has no impact on the logical view of the data to the client. To the client it is as though there is one server with larger capacity. Even document data that might happen to be in the process of being moved from one shard to another as part of shard balancing will not experience an error or delay. (It will delay the background move instead, if the access is write).

### Be small

You can also be small - MongoDB does not hang some performance-lowering burden of distributed data management on your database server, or place configuration burden on you as a database administrator, if you aren't using it.

You don't even have to have a replica set _if_, in a rare sort of use case, you can afford for your database to be down (say if a data center's power goes out) and furthermore don't care if the data is lost (say if the hard disk suffers irreversible corruption). MongoDB can run as a _standalone_ <tt>mongod</tt> process and this lets you forgo the cost of having a second or third server. (Starting from v4.0 technically all nodes must be in a replica set by configuration, but that can be single-node replica set.)

### Get smaller quickly

I'm just kidding. But if you weren't, yes, you can use <a href="https://docs.mongodb.com/manual/reference/method/db.collection.remove/">remove</a> (== document delete), <a href="https://docs.mongodb.com/manual/reference/method/db.collection.drop/">drop</a> (== whole collection drop), <a href="https://docs.mongodb.com/manual/reference/method/rs.remove/">rs.remove(&lt;replica member&gt;)</a> and <a href="https://docs.mongodb.com/manual/reference/command/removeShard/">removeShard</a>.

### Survive server, data center failures

MongoDB replica set members contain copies of each other's data to within whatever limit of time it takes for an update on the primary to be replicated to the secondaries. This can be just a millisecond in the better cases.

An important corollary to this is: the drivers (i.e. the MongoDB API library you use in your code to connect to MongoDB) are all replicaset-aware, regardless of which language you are version.

If you are using sharding, you will connect to a <tt>mongos</tt> node. The <tt>mongos</tt> node does the failover handling in that case.

So if a server dies:

- The remaining replica set nodes will notice this (default is with <= 2 seconds, the 'heartbeat' cycle). If the server that died was the primary, they will hold a new election and one of the prior secondaries becomes the new primary. There is a dynamic replicaset state shared between them which is updated. When the former primary is restarted it will receive and act accordingly to that new state where it is a secondary, not try to continue as it was before it's halt.
- The clients that were connected, with the replica-set aware driver code, will detect the failure of the read/write they were performing at the time.
- Apart from the 'blip' of reads and writes that failed because they were en-route to the former primary just about the time it died, the application's database functionality _remains up_.
E.g. if you were serving 10,000 web page request a minute some, say dozens, will have database errors. The web pages served before and after will be unaffected.
- You don't have to accept that the client fails to perform it's intended logic during the period of time between the first primary's crash and the new one stepping up. The type of error returned in the event of a lost primary will allow you to recognize that a new primary will shortly step up, and that you can try to do the same thing again (say with try-catch block). MongoDB drivers do _not_ automatically retry for a good reason though - whether something should be retried or not depends on your application's requirements. So it is left to programmers to explicity choose what to do - retry, or not. Redo writes assuming the original context is still valid, or not. Just try the write again, and if there is a duplicate error you could assume the write originally succeeded (and was replicated to the secondary node that subsequently became the new primary)

### Know the inside out

#### Diagnostic information 

MongoDB includes diagnostic information.

- Log files
- db.serverStatus()
- Configuration:
  - db.cmdLineOptions()
  - rs.status(), rs.conf()
  - sh.status()
  - The sharding _config_ db.

These are evidence you can examine to learn a _lot_ about the state of your MongoDB instances. 

Graphical tools are _not_ included in the normal server and client installation packages, but you can find them in MongoDB's cloud utlities, or third-party metric monitoring tools.

#### Source code

A nice feature, for the C++ programmers especially, is that the source code (excluding enterprise modules such as LDAP and Kerberos authentication, auditing, etc.) is publicly available.
