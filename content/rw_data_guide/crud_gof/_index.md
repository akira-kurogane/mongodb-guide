+++
title = "Queries, Inserts, Updates and Deletes"
menuTitle = "The CRUD G.o.F."
description = "The classic gang of four"
weight = 20
+++

## Translation table

The most fundamental commands for reading and writing unfortunately have a slightly different names in different contexts. It's the same gang of four all the time though:

| Context | Query | Insert | Update | Delete |
|---------|------|--------|--------|--------|
| [CRUD](https://docs.mongodb.com/manual/crud/) names | Read | Create | Update | Delete |
| SQL equivalent | SELECT | INSERT | UPDATE | DELETE |
| `mongod` server-side commands | **[find](https://docs.mongodb.com/manual/reference/command/find/)** | **[insert](https://docs.mongodb.com/manual/reference/command/insert/)** | **[update](https://docs.mongodb.com/manual/reference/command/update/)** | **[delete](https://docs.mongodb.com/manual/reference/command/delete/)** |
| `mongo` shell | [find()](https://docs.mongodb.com/manual/reference/method/db.collection.find/)<br>findOne() | [insert()](https://docs.mongodb.com/manual/reference/method/db.collection.insert/)<br>insertOne()<br>insertMany() | [update()](https://docs.mongodb.com/manual/reference/method/db.collection.update/)<br>updateOne()<br>updateMany() | [remove()](https://docs.mongodb.com/manual/reference/method/db.collection.remove/)<br>deleteOne()<br>deleteMany() |
| pymongo driver | find()<br>find\_one() | insert\_one<br>insert\_many | update\_one()<br>update\_many() | delete\_one()<br>delete\_many() |
| mongoc driver | mongoc\_collection\_find | ...\_insert | ...\_update | ...\_delete |
| Java driver | find() | insertOne()<br>insertMany() | updateOne()<br>updateMany() | deleteOne()<br>deleteMany() | 
| (Mostly) extinct aliases | query() | | upsert\*<br>save | | |
| Legacy Wire<br>Protocol msgs | OP\_QUERY | OP\_INSERT | OP\_UPDATE | OP\_DELETE |

Variations such as insertOne(), updateMany() are just syntactic sugar.

E.g. 1. There is no such thing as an 'insertOne' command etc. in a wire protocol message. The driver will construct a <tt>{ **insert**: &lt;collection\_name&gt;, documents: [ ... ] }</tt> BSON command object that has only one document in the "documents" array.

E.g. 2. An updateMany(&lt;query&gt;, u: &lt;update&gt;) function call will become a <tt>{ **update**: &lt;collection\_name&gt;, updates: [ q: &lt;query\_spec&gt;, u: &lt;update\_spec&gt;, **multi: true** ] }</tt> command.

E.g. 3. An upsert is also really an update command like just above, but with a <tt>upsert: true</tt> flag present and set to true.

{{% children %}}

_To come:_

- The update command


#### Historical detour

The documentation for the delete command says _"New in version 2.6"_. 'What! Was MongoDB an append-only database before then?'

Actually the same version info is written for the other two write commands (insert, update). And the find command has _"New in version 3.2"_!

What this points out is that before v2.6 did not accept BSON command objects that were formatted like <tt>{"insert": &lt;collection\_name&gt;, ...}</tt>, <tt>{"update": &lt;collection\_name&gt;, ...}</tt>, <tt>{"delete": &lt;collection\_name&gt;, ...}</tt>. Instead the clients sent an OP\_INSERT, OP\_UDPATE or OP\_DELETE mongo wire protocol message. The target collection name was up a level in a field in the wire protocol message object, whilst every other field was still in the same format in the BSON object packed within.

The difference may seem merely lexical, but the introducing a BSON format spec to allow an array of writes in each wire request (rather than just one) improved the way that bulk writes could be done.

<tt>{"find": &lt;collection\_name&gt;, ...}</tt> likewise wasn't recognized by the server until v3.2. Before then queries were always sent in an OP\_QUERY wire protocol message. The OP\_QUERY wire protocol is still used a lot as a legacy workaround that won't be resolved until OP\_MSG becomes standard. Until then a query might be a classic OP\_QUERY with the target collection in the wire protocol field, or it might be an OP\_QUERY with the fake "$cmd" name string in the wire protocol field for collection, and the packed BSON object will have <tt>"find": &lt;collection\_name&gt;</tt> as it first key-value pair (indicating that is the command name and what its scope is).

FYI in v3.2 an OP\_COMMAND message type was introduced in tandem with the packing of queries in a more generic command BSON object, but it never became mainstream. It was considered deprecated by v3.6 and is removed completely by v4.2.
