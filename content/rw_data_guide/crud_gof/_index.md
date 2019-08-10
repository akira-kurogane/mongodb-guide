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

Variations such as insertOne(), updateMany() are just syntactic sugar.

E.g. 1. There is no such thing as an 'insertOne' command etc. in a wire protocol message. The driver will construct a <tt>{ **insert**: &lt;collection\_name&gt;, documents: [ ... ] }</tt> BSON command object that has only one document in the "documents" array.

E.g. 2. An updateMany(&lt;query&gt;, u: &lt;update&gt;) function call will become a <tt>{ **update**: &lt;collection\_name&gt;, updates: [ q: &lt;query\_spec&gt;, u: &lt;update\_spec&gt;, **multi: true** ] }</tt> command.

E.g. 3. An upsert is also really an update command like just above, but with a <tt>upsert: true</tt> flag present and set to true.

{{% children %}}

_To come:_

- The insert command
- The update command
- The delete command
