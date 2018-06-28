+++
title = "Drivers"
date =  2018-05-30T23:25:38+10:00
weight = 15
+++

From the perspective of the driver developer the MongoDB driver:

- Marshalls data from the language's native types into the format the MongoDB server requires (== a **BSON payload** proceeded by a few classically simple network fields in each packet's header area).
- Sends and receives that info, keeping track of which reply from a server matches which request.
  - When using a connection pool it also keeps a track of which thread the requests were sent from
- Goes to error handling when there are network interruptions like abrupt socket closure and other TCP casuality situations
- There is a _lot_ of detail in the 'Meta' API driver specification about <a href=https://github.com/mongodb/specifications/tree/master/source/server-discovery-and-monitoring">server discovery and monitoring</a> ("SDAM") and <a href="https://github.com/mongodb/specifications/tree/master/source/server-selection">server selection</a> which _all_ the supported drivers follow. 

From the application developer's perspective the MongoDB driver:

- Presents the database as an object you can push data in and pull data out of.
- The API provided is idiomatic for your language. E.g. where Java programmers run a _find()_ method on a collection object C driver users run a _mongoc\_collection\_find()_ function that takes a mongoc_collection_t\* pointer argument, etc.

What the driver API _doesn't_ do:

- Explicity involve you with how the connections are maintained, or which remote servers in the replica set are the primary (i.e. the one that the writes happen on first), etc. Apart from the fact that you open a connection, and there can be exceptions thrown when a server crashes or the network is disconnected, there is little expression in the API that the database is on a remote server.
There are no network-conscious concepts the user must engage with such as 'queue this request', 'pop reply off incoming message stack'.

#### What it looks like to the programmer

I'd like to direct you to MongoDB's official documentation tutorials for a couple of types of operations:

- <a href="https://docs.mongodb.com/manual/tutorial/insert-documents/">Document insert example</a> (Python, Java, Node.js, PHP, C#, Perl, Ruby, Scala)
- <a href="https://docs.mongodb.com/manual/tutorial/query-documents/">Query example</a> (Python, Java, Node.js, PHP, C#, Perl, Ruby, Scala)

Regardless of which driver you are using, at the Wire Protocol layer they are all the same fundamentally. If they are contemporary versions there's a good chance BSON payload in each Wire protocol packet is identical excluding ephemeral fields like a timestamp.

Example _find_ in various APIs |     | BSON payload 'on the wire' |     | <tt>mongod</tt> code
------------------------------ | --- | -------------------------- | --- | ----------------
**mongo shell** db.foo.find({"x": 99};<br>**PyMongo** client["test"].foo.find({"x": 99})<br>**Java** xxx | → | <tt>\{<br>&nbsp; "find":"foo",<br>&nbsp; "filter":\{"x":99.0\},<br>&nbsp; "$clusterTime":\{ ... }\},<br>&nbsp; "signature":\{ ... \},<br>&nbsp; "$db":"test"<br>\}</tt> | → | <a href="https://github.com/mongodb/mongo/blob/v3.6/src/mongo/db/commands/find_cmd.cpp">mongo::FindCmd::run</a>

