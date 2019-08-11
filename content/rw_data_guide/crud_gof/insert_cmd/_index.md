+++
title = "The insert command"
menuTitle = "insert"
weight = 20
+++

The <tt>insert</tt> command requires the collection name it will be operating on, and then just the new document (or documents - technically it accepts an array of them) that should go into the collection.

If the documents can't be inserted an error will be returned. As the insert command can contain multiple documents to insert the error field is not one error code and/or message, but rather the <tt>writeError**s**</tt> array.

When it succeeds the server response _does not_ return the \_id value of the document. But the MongoDB driver usually has saved it before being sent (maybe making a new one itself if it was not specified). So usually the driver can give it to you as property. See the section below for more details.

Errors that incur can be access control ones (no write privilege on that collection), document validation rejection (if you are one of the relative few using them), writeConcern errors (such as might happen the moment secondaries are lost to the point of not having a majority in a replica set), etc. By far the most common too see is _E11000 duplicate key error_. This will arise both for duplicate values in user-made unique indexes and the compulsory primary key index on "\_id".

### The <tt>\_id</tt> primary key field

Documents that lack an "\_id" field will be given a new ObjectId as the \_id value.

- Typically the MongoDB driver will generate the new ObjectId and add it before sending. There is no need that it be done server side. That's the beauty of the GUUID-style ObjectId datatype &ndash; it's so easy to generate unique values.
- Even if the driver didn't create and add a new ObjectId value for \_id then as a final line of policy implementation the server will.<br>I think in this case you will have no information client-side about what the new \_id value is, unless the insert was (opaquely to you) changed to be an update command in _upsert_ mode and then getLastError command was used correctly (according to the oldest protocol conventions) and gets it from the _upserted_ value there.

The server will also force that \_id be the first field by BSON ordering if it wasn't already. I.e. if you had sent <tt>{"a": true, "\_id": 999, "b": false}</tt> you will find it is <tt>{"\_id": 999, "a": true, "b": false}</tt> when you get it back in a query.

#### No auto\_increment data type / function

If you don't like the GUUID-like ObjectIds and insted would prefer an unbroken chain of auto-incrementing integers as the primary key, sorry, that can only be performant in unpartitioned database designs and MongoDB does not provide it.

Well, a performant way could exist for distributed databases that are always partitioned on the primary key, but MongoDB supports data partitioning by any secondary index as well. So n'th- and n+1'th-created documents can be on different shards. As an unavoidable result of allowing for that an implementation of an auto-incrementing integer value would have to use a software lock that waits out the responses from all shard primaries to make sure that the next integer isn't being 'double-booked' in 2+ shards simultaneously. That doesn't scale when you have a collection spread across multiple servers.
