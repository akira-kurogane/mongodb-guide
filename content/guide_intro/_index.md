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

Mostly everyone who has used one of the 'NoSQL' databases which came into popularity post-2010, of which MongoDB is the most popular, already appreciate this. But for those of you still using relational databases the key points are

- Reduced lines of code
  - Making a connnection is a small number of lines (maybe only one). The details, and the way the connection is used, barely change whether it is to a single standalone <tt>mongod</tt> process, or the largest cluster with failover capability and security options.
  - Writing an object is typically a single line, and very rarely more than few.
  - Querying data and updating data requires passing filter clauses that specify _what_ should be read/updated, so that is not much reduced i.m.o., but it is not larger either.
- You don't need to perform a full mental switch between the paradigm of your application's logic and the paradigm of the server-side data storage mechanism when you're programming a part that writes to or reads from the database.
You are a <a href="https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3900881/">glucose-powered computer</a> and context change is expensive. Only so much glucose can be converted by your neurons into thought-sparks a day, so save your sparks for things that are more valuable to you.

Want to do things quicker by using more developers / tools? For example your Web front-end has been created in language _X_, but the data scientists that will mine gold from the big data need to use language _Y_? MongoDB has got you covered - C, C++, C#, Erlang, Go, Java, Node.js, Perl, PHP, Python, Ruby and Scala are supported.

The simplicity of the client API will also reduce the _technical debt_ of your codebase significantly. To the original developer this may seem important, but for the development department that owns the technology it is more important than the speed of new feature development.

### Write faster, read faster

This has always been my favourite feature of MongoDB.

Let's take a trip back in time, to 2010 or so. The first MongoDB version I was using was 1.6, and I had a task to load a dataset of some 10's of GB. I can't remember the client program, but it might have been mongoimport. As the data load progressed:

1. I was pleasantly surprised by the rate of document inserts.
2. I was a little shocked by the rate of inserts.
3. I was getting suspicious of the insertion rate. Was the counter just a client-side lie? (No, I confirmed server-side.)
4. I started sanity-checking the numbers, by datasize too. I arrived at a figure ~30 MB/s.
5. 30 MB/s reminded me of something. At the time commodity HDD specs advertised 30MB/s write speeds. I checked the server's specs. It had the same 30 MB/s rate.

The takeaway for me was _the hardware specs were no longer some sort of fantasy numbers way above the user's reality_, which was a given for RDBMS-using application developers until then. If the hardware manufacturers have engineered their equipment to flick _x_ million or billion electrons per second from one silicon nano-suburb to another, I could now use _all_ those electrons for my data purposes.

At the time MongoDB's only storage engine was MMAP, which doesn't use compression. So the database process was bottlenecked _only_ on the storage layer. This was a huge difference compared to inserting to a RDBMS.

With the change in hardware-land to SSDs, and furthermore MongoDB's change to the WiredTiger storage engine, MongoDB users now usually enjoy throughput and latency will be somewhat higher than the figures above. But the key point is to expect MongoDB to redline your _hardware's_ throughput and/or latency by the volume of _your_ data being moved, without the database software eating a noticeable chunk of the server capacity for itself.

### Go big
(sharding)

### Get bigger quickly 
(flexible sharding)

### Be small
(and save hardware spend)

### Get smaller quickly
(just kidding)

### Survive server, data center failures
Whenever (not If-ever) they occur

### Know the inside out
(because it's open source)
