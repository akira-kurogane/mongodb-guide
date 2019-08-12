+++
title = "The update command"
menuTitle = "update"
weight = 30
+++

In any database I can think of an update has two fundamental pieces of work to do &ndash; a query to find the matching documents' place in the underlying storage, and the write modification that is done upon them.

Accordingly the query filter and the object modification spec object are the two compulsory but separate arguments of a MongoDB <tt>update</tt> command. An example as mongo shell function:

```json
db.cc_status_collection.update(
  { /* query filter: */
    "client_code": "R8THH",
    "expiry": {"$exists": false }
  },
  { /* update spec: */
    "$set": { "expiry": ISODate("2019-08-31T00:00Z"), "plevel": 0 },
    "$unset": {"active_contacts": "" },
    "$inc": { "admin_op_transaction_count": 1 }
  }
  /* (other option fields exist; not used in this example) */
)
```

#### Query filter

The update command's query filter (a.k.a. predicate) is exactly the same as the find command's.

Just as with find it can be an empty object &ndash; this means match any/all documents, as with a find command. Whether it matches just one or all depends on the "multi" flag discussed in the other options subsection below. find's equivalent is the "limit" option which can be any number, but update's multi is a boolean - 1 or all, no inbetween. N.b. options are not part of query filter or the object modification spec; they are set to the side of those two.

#### Object modification spec

The object modification spec cannot simply be the new object, or just some key-value pairs within it, in verbatim key-value pairs like the document given to an insert command. It must be a set of **update operators** which will objects that specify the target fields and the new value or increment amount or array modifications etc. that will be performed on them.

Hence rather than supplying just: <tt>"expiry": ISODate("2019-08-31T00:00Z")</tt>

You must have a $set operation: <tt>"$set": { "expiry": ISODate("2019-08-31T00:00Z"), ... }</tt>

$set is the most fundamental [update operator](https://docs.mongodb.com/manual/reference/operator/update/) but it is only one of many:

- Approximately a dozen operators for updating scalar value fields.
- Approximately half a dozen operators for modifying nested arrays.
- Three 'operators' that provide a syntax for access specific values in nested arrays (<tt>$,</tt> <tt>$\[\]</tt>, <tt>$\[&lt;identifier&gt;\]</tt>).

And there are about half a dozen operator _modifiers_ (eg. $each, $sort). Documentation note: the modifiers are confusingly shown in the MongoDB document navigation list as operators, at least as of Aug 2019.

Update operators are statements - you are instructing what to do with a field (or list of fields) with a mini-command, you might say.

```json
    "$set": { "expiry": ISODate("2019-08-31T00:00Z"), "plevel": 0 },
```

Nearly every operator can iterate through a list of fields, doing the same thing for each. The "$set" operation above shows how that syntax works with two fields but it could be hundreds or thousands probably. Only $bit is an exception I believe &ndash; if you needed to do it for multiple fields and a <tt>{ "$bit": ... }</tt> operation for each in the object modification spec.

There is no operator that will iterate all fields, or all fields matching a regex. The array reference operators provide some ways to iterate/find values regardless of which array index they are at, but as for key-value pairs you must supply the exact key names when you submit the update request.

In summary: the object modification spec is a sequentially-executed list of operations, each with a list of fields that will be modified, that will transform a copy of the old document to the new one.

#### Multi, Upsert, Collation

For every update there is a <tt>multi</tt>, <tt>upsert</tt> and <tt>collation</tt> option. This means that in a bulk updates you can mix and match these modes for each update separately.

**multi** 

In short, if you were to use updateOne(...) in the mongo shell (or whatever driver API's equivalent) <tt>multi</tt> will be <tt>false</tt>. If you use updateMany(...) it will be <tt>true</tt>. If you use the legacy _update(...)_ that existed before there were the new ...One() / ...Many() variants it will be **false**. I.e. if you leave the multi option unset the update commands only affects one (or zero) documents.

**upsert**

From the documentation: _"Optional. If true, perform an insert if no documents match the query."_

If an upsert applies (i.e. no existing documents matched that query) the multi value has no relevance - one document will be inserted.

The way to tell if you command created a new document or not is to look in the "upserted" nested array that is returned. It will contain the \_id value of the new document. If you have multiple updates in a single <tt>{"update": ..., "updates": \[ ... \], ... }</tt> request you'll need to do matching to the original request to determine which ones exactly became upserts and which didn't. This is low-level (or at least semi-low) detail though. Possibly your driver does this automatically and you can access the original updates vs. new upsert \_id idiomatically.

#### Ordered batch writes, writeConcern, document validation

The "ordered", "writeConcern" and "bypassDocumentValidation" options are set at the same level as the array and hence apply to all the updates, if there are more than one. See batch writes for more information regarding "ordered".

### Performance

As with a find command you should be sure there is an index that makes the query part efficient. There is no way (or need) to make the update part more efficient - once the real address to the document(s) is found the same amount of work is going to be performed.

The objection modification work might seem to be the bigger part of the work - it is usually the harder of the two main arguments to write, and it seems the software must take many more steps to execute than the query part.

The work to modify the BSON object is usually less time-consuming than the query part, however. Thousands of CPU steps can be performed faster in first-level cache than even one out-of-cache memory access to get a part of the storage engine's data structure (e.g. the next B-tree node) and that will probably be repeated several times before the existing document is fully accessed. And that's with a perfect index - think how high the cost will be if you have to document-scan _N_ documents before finding the one to update.
