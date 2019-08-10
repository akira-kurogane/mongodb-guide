+++
title = "The find command"
menuTitle = "find"
weight = 10
+++

You know what <tt>find</tt> is about - it's how you read collection data. You send it with a **query filter** (like the WHERE clause of SQL) and it returns a cursor with documents matching that filter. If you omit a query filter it will return all documents.

Unlike SQL SELECT query a <tt>find</tt> command can only operate on a single collection or view. 

Excluding the scope of the collection name the [find](https://docs.mongodb.com/manual/reference/command/find/) command has no required arguments, only optional ones.

In practice the **query filter** argument is usually set - it's not often you want to read the entire collection. The **field projection** argument or the **sort order** argument are the next most commonly-used ones. After that are ones like <tt>limit</tt>, <tt>skip</tt>, <tt>collation</tt> and index <tt>hint</tt> that also in SQL. There are also ones that more specialist and/or don't have a SQL equivalent. E.g. setting <tt>batchSize</tt>, or using <tt>tailable</tt> and <tt>awaitData</tt> to make a tailable cursor.

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

The order of some the pipeline stages in the aggregation above don't matter, by the way. It could have been the $sort first, $match second. If the $proj doesn't remove any of the fields that the $match or $sort stages reference then any of the other four permutations would also be OK. Aggregation pipeline optimization will collapse logically equivalent pipeline links internally to the same plan the query engine.

### No collection joins. Oh wait, yes, collection joins.

It's not too hard to argue that NoSQL databases' biggest paradigm change was that they didn't support table ( / collection) joins.

This is still true of the find command. The [aggregation pipeline]({{< ref "rw_data_guide/aggregation_pipeline/_index.md" >}}) on the other hand does support joins through the [$lookup](https://docs.mongodb.com/manual/reference/operator/aggregation/lookup/) operator.

