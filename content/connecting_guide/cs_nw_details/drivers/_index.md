+++
title = "Drivers and 'the wire'"
description = "Putting perspective on what a MongoDB driver is through a description of the shape and behaviour of your client requests (and server replies) as TCP traffic"
date =  2018-05-30T23:25:38+10:00
weight = 15
+++

From the perspective of the _driver developer_ a MongoDB driver:

- Marshalls data from the language's native types into the format the MongoDB server requires (== a BSON payload proceeded by a few classically simple network fields in each packet's header area).
- Sends and receives that info, keeping track of which reply from a server matches which request.
  - When using a connection pool it also keeps a track of which thread the requests were sent from
- Goes to error handling when there are network interruptions like abrupt socket closure and other TCP casuality situations
- Implements a _lot_ of detail in the 'Meta' API driver specification for <a href=https://github.com/mongodb/specifications/tree/master/source/server-discovery-and-monitoring">server discovery and monitoring</a> ("SDAM") and <a href="https://github.com/mongodb/specifications/tree/master/source/server-selection">server selection</a>.

From the _application developer's perspective_ the MongoDB driver:

- Presents the database as an object you can push data in and pull data out of.
- The API provided is idiomatic for your language. E.g. where Java programmers run a _find()_ method on a collection object, C driver users run a _mongoc\_collection\_find()_ function that takes a mongoc_collection_t\* pointer argument, etc.

To look at it from another side this is what the driver API _doesn't do_:

- Involve the application programmer in maintaining the TCP socket connections.
- Involve the application programmer in determining which remote servers are the current primaries (i.e. the one that the writes happen on first)
- Expose network packet data in the wire protocol format

Apart from the fact that you open a connection, and there can be exceptions thrown when a server crashes or the network is disconnected, there is limited expression in the API that the database is on a remote server.
There are no network-conscious concepts the user must engage with such as 'queue this request', 'pop reply off incoming message stack', etc.

## Many drivers; one Wire Protocol

Regardless of which driver you are using, at the Wire Protocol layer they are all the same fundamentally. If they are contemporary versions there's a good chance the BSON payload in each Wire protocol packet is identical excluding ephemeral fields like a timestamps.

The format of data in MongoDB Wire Protocol requests and responses is relatively simple, but it is a binary one and is far from being human-readable. The below comes from TCP payloads captured using tcpdump, manually unwrapped using command line tools <tt>od</tt> and <tt>bsondump</tt> according to the info in the <a href="https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/">MongoDB wire protocol documentation</a>.

Example _find_ in various APIs |     | MongoDB wire packet |     | <tt>mongod</tt> code
------------------------------ | --- | ------------------- | --- | ----------------
**mongo shell** db.foo.find({"x": 99};<br>**PyMongo** db.foo.find({"x": 99})<br>**Java** db.getCollection("foo").find(eq("x", 99))<br>**PHP** $db->foo->find(['x' => 99]);<br>**Ruby** client[:foo].find(x: 99) | → | **<a href="https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/#op-msg">OP_MSG</a>**<br>length=180;requestID=0x1b73a9;responseTo=0;opCode=2013(=OP_MSG type)<br>flags=0x00.0x00<br>section 1/1 = <tt>\{<br>&nbsp; "find":"foo",<br>&nbsp; "filter":\{"x":99.0\},<br>&nbsp; "$clusterTime":\{ ... }\},<br>&nbsp; "signature":\{ ... \},<br>&nbsp; "$db":"test"<br>\}</tt> | → | <a href="https://github.com/mongodb/mongo/blob/v3.6/src/mongo/db/commands/find_cmd.cpp">mongo::FindCmd::run</a>
 (A cursor object with first batch results) | ← | **<a href="https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/#op-msg">OP_MSG</a>** (as a reply)<br>length=180;requestID=0xb5a;responseTo=0x1b73a9;opCode=2013(=OP_MSG type)<br>flags=0x00.0x00<br>section 1/1 = <tt>\{<br>&nbsp; "cursor":\{<br>&nbsp; &nbsp; "id":\{"$numberLong":"0"\},<br>&nbsp; &nbsp; "ns":"test.foo",<br>&nbsp; &nbsp; "firstBatch":[<br>&nbsp; &nbsp; \{"\_id":ObjectId("5b3433ad88d64ee7afb5dc80"), "x":99.0,"order_cust_id":"AF4R2109"}<br>&nbsp; ]<br>&nbsp; \},<br>&nbsp; "ok":1.0,<br>&nbsp; "operationTime":\{ ... \},<br>&nbsp; "$clusterTime":\{ ... \},<br>&nbsp; "signature":\{ ... \},<br>&nbsp; "keyId":\{"$numberLong":"0"\}\}\}<br>\}</tt> | ← |  ↲

#### OP\_QUERY and early generations

An optional detour for those who knew the original Wire protocol messages (OP\_QUERY, OP\_INSERT, etc.) and are interested in what traffic looked like with these.

{{% expand %}}

The above is latest-and-greatest OP_MSG format. At time of writing only the 3.6+ mongo shell and dev-branch drivers would be using it. In truth most driver versions are still being shoe-horned into the legacy **OP_QUERY** message type.

Per its name OP_QUERY was meant to only be for queries, but was repurposed for mostly any type of request message. In its network packet fields it included a "fullCollectionName" field because queries always need a a db and collection name scope). But there are commands that don't have a collection scope (eg. replicaSetGetStatus, createUser)  but don't have a dedicated wire protocol message type either. How to send them? The workaround for those cases was that "$cmd" was used as a _dummy collection name_ at the end of the "fullCollectionName" field. This workaround became so standard that it is even set this way for commands such as _find_ which do need a collection scope. You can see in the example below that the collection name "foo" has moved inside the BSON and is absent outside.


| Legacy wire packet examples |
| --------------------------- |
| <a href="https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/#op-query">OP_QUERY</a><br>length=215;requestId=0x6633483;responseTo=0;opCode=2004(=OP_QUERY type)<br>fullCollectionName="test.$cmd" _//N.b. the dummy "$cmd" collection name_ <br>numberToSkip=0;numberToReturn=0xffff<br>document = <tt>\{<br>&nbsp; "find":"foo",<br>&nbsp; "filter":\{"x":99\},<br>&nbsp; "lsid":\{ ... \},<br>&nbsp; "$clusterTime":\{ ... \},<br>&nbsp; "signature":\{ ... \},<br>&nbsp; "keyId":\{"$numberLong":"0"\}\}\}<br>\}</tt> | 
| <a href="https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/#op-reply">OP_REPLY</a><br>length=301;requestId=0xbb8;responseTo=0x6633483;opCode=1(=OP_REPLY type)<br>responseFlags=0x08(=AwaitCapable)<br>cursorID=0 _//important for getMore cmds that follow, if any_;<br>startingFrom=0;numberReturned=1<br>document = <tt>\{<br>&nbsp; "cursor"<br>&nbsp; \{<br>&nbsp; &nbsp; "firstBatch":[<br>&nbsp; &nbsp; &nbsp; \{"_id":ObjectId("5b3433ad88d64ee7afb5dc80"), "x":99.0,"order_cust_id":"AF4R2109"\}<br>&nbsp; &nbsp; ],<br>&nbsp; &nbsp; "id":\{"$numberLong":"0"\},<br>&nbsp; &nbsp; "ns":"test.foo"\},<br>&nbsp; &nbsp; "ok":1.0,<br>&nbsp; &nbsp; "operationTime":\{ ... \},<br>&nbsp; &nbsp; "signature":\{ .. \}<br>&nbsp; \}<br>\}</tt> |

My way of looking at is:

- In the beginning there were just collection editing or reading commands (query, insert, update, delete) and four wire packet types for those, plus a reply message type. The db+collection namespace was put in a network field, outside the BSON payload document.
- Soon there many more command types that the database server accepted. A generic command wire packet format was needed. The existing drivers (that needed to be supported for some time) started using OP_QUERY overloaded for this purpose.
- A generic command wire packet type OP_COMMAND was invented! And used by mongo shell v3.4(?) and between nodes in clusters and replica sets. But it didn't go mainstream.
- Instead the OP_MSG type has become the new standard, to be used by 4.2? era drivers. Neither the collection name or database name is in the network header fields - they'll be in "ns" (namespace) inside the BSON payload instead.
{{% /expand %}}

### Database command type

You might have noticed that there's no primary / headlined / specially labeled value in the BSON command object that indicates what sort of command the client is sending.

You might be wondering 'Does the server run through a list of key-value pairs in fixed order until it gets a match?' (E.g. _if (commandMessage.hasKey("find") then --> FindCmd:run(), else if commandMessage.hasKey("update") -> UpdateCmd::run()_, etc. ....?).

Nope, a simpler mechanism is used. From <tt>util/net/op_msg.h</tt>:
```C++
    StringData getCommandName() const {
        return body.firstElementFieldName();
    }
```

Take the key name from the first key-value pair. End of function.

A lesson from this is that order in BSON can matter (at least to MongoDB). Important for driver developers, but not application programmers as the driver API will take care of this point for you.

#### What it looks like to the programmer

I don't want to re-invent the documentation wheel for this part. MongoDB's official documentation tutorials are good and cover many language samples in one page. Some links for a couple of types of operations:

- <a href="https://docs.mongodb.com/manual/tutorial/insert-documents/">Document insert example</a> (Python, Java, Node.js, PHP, C#, Perl, Ruby, Scala)
- <a href="https://docs.mongodb.com/manual/tutorial/query-documents/">Query example</a> (Python, Java, Node.js, PHP, C#, Perl, Ruby, Scala)

