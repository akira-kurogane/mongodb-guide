+++
title = "The find command"
menuTitle = "find"
description = "The find command"
weight = 10
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

## find

You know what <tt>find</tt> is about - it's how you read collection data. You send a **query filter** (the WHERE clause of SQL) and it returns a cursor with documents matching that filter argument. If you omit the query filter it will return all documents.

Unlike SQL SELECT query a <tt>find</tt> command can only operate on a single collection or view. 

Excluding the scope of the collection name the [find](https://docs.mongodb.com/manual/reference/command/find/) command has _no required arguments_, only optional ones.

In practice the **query filter** argument is usually set - it's not often you want to read the entire collection. The **field projection** argument or the **sort order** argument are the next most commonly-used ones. After that are ones like _limit_, _skip_, _collation_ and index _hint_ that also in SQL. There are also ones that more specialist. E.g. using <tt>tailable</tt> and <tt>awaitData</tt> to make a tailable cursor.

### The alternative to find

The find command is not the only way to read documents from collection. The [aggregation pipeline]({{< ref "rw_data_guide/aggregation_pipeline/_index.md" >}}) also returns documents, with the same cursor concept that a find provides.

The result from the classic find command:
```text
db.collection.find(filter_arg, projection_arg, sort_order)
```
will be indentical to that of the following aggregation pipeline.
```text
db.collection.aggregate([
  {$match: filter_arg},
  {$sort: sort_order},
  {$proj: projection_arg}
])
```

The **query engine** of MongoDB will create an internal plan that is either identical, or logically identically at any rate. Exactly the same documents will be returned. It will also follow the same sort order.

The order of some the pipeline stages in the aggregation above don't matter, by the way. It could have been the $sort first, $match second. If the <tt>$proj</tt> doesn't remove any of the fields that the <tt>$match</tt> or <tt>$sort</tt> stages reference then any of the other four permutations would also be OK. Aggregation pipeline optimization will collapse logically equivalent pipeline links internally to the same plan the query engine.

### No collection joins. Oh wait, yes, collection joins.

It's not too hard to argue that NoSQL databases' biggest paradigm change was that they didn't support table ( / collection) joins.

This is still true of the find command. The [aggregation pipeline]({{< ref "rw_data_guide/aggregation_pipeline/_index.md" >}}) on the other hand does support joins through the [$lookup](https://docs.mongodb.com/manual/reference/operator/aggregation/lookup/) operator.

## Inserts, Updates and Deletes

...

