+++
title = "'MQL' vs. SQL"
description = "'MQL' vs. SQL"
date =  2018-05-31T14:47:29+10:00
weight = 5
+++

# Call a function; don't write a statement

## 1. There is no MongoDB query _language_

The "L" in SQL is "Language". A syntax that defines how you can write a sentence such as "SELECT usr\_id, COUNT(\*) AS count FROM TableA GROUP BY usr\_id" that can be parsed to become query or update plans.

MongoDB driver API's don't require that. They don't require you to 'program' a piece of text for the remote database server to parse (and potentially throw a syntax error on).

## 2. Call a function and give it arguments.

Depending on which language you are programming your client application in the API will be different, but the common thing is that you make all database requests by calling separate functions for the matching database commands.

Here are some examples of doing the insert command, covering one OOP and one imperative style language:

```
//Python
my_collection.insert_one(doc)

//C
mongoc_collection_insert_one(my_collection_pointer,
                             doc_pointer, NULL, NULL, &err);
```

The above use the API provided by [PyMongo](https://api.mongodb.com/python/current/) and [mongoc](http://mongoc.org/) MongoDB drivers. If you use Python or C you can see the syntax is very normal for them. Likewise the Java driver is idiomatic for Java, the NodeJS driver is idiomatic for NodeJS, the C# driver is idiomatic for C#, etc.

A database-side command of _xXxx_ will be called by executing the API function probably named _xXxx(..)_ or _Xxxx(..)_ or _mongo\_xxxx(..)_, etc. It might be a synonym too, e.g. "find" <--> "query" or "delete" <--> "remove".

Some of the functions in the driver API are extra wrappers that provide some kind of syntactic convenience. The _insert\_one(..)_ function and its partner _insert\_many(\[..\])_ are an example. Underneath both is just one command, [insert](https://docs.mongodb.com/manual/reference/command/insert/), which requires that the document(s) being inserted be passed in an array. _insert\_one_ saves you the tiny bit of boilerplate work of instantiating an array to put your one document inside.

### In one sense db and collection names are arguments too

In the example above there are two arguments, although the OOP example especially makes it easy to miss. There is the collection that will be inserted to, plus the doc that will be inserted.

A database namespace will always be in scope too. Database name is typically set when you created the db connection so it wont be in the function-calling code line, but the driver will be packing it in every request for you behind the scenes.

As a matter of semantics you might call both the database and collection scope or you might call them arguments.

I would say: In the wire protocol packed format they are just string names (argument), but in the code they are scope.

On the driver side the scope is kept mostly for tracking which db name and collection to pack in requests. On the server-side the db or collection name strings received from a wire protocol request are immediately used to reopen or instantiate memory structures with pointers to existing collection names for a given db, pointers to existing indexes for a collection, etc.

## 3. Receive the result

Nothing new here for any who has programmed a database-using application before. When you call the function there will be a call over the network to the MongoDB server and for any given function in the API there will be one type of result.

To choose the simplest example this is the response from some deletes executed using PyMongo. The response confirms they ran OK; in the case of the second it shows that 5 documents matched the filter clause and were deleted.

```python
...
>>> del_result = posts.delete_one({})
>>> del_result
<pymongo.results.DeleteResult object at 0x7f7580fa9ec8>
>>> del_result.raw_result
{'n': 1, 'ok': 1.0}
>>>
>>> del_result = posts.delete_many({"z": "test string"})
>>> del_result.raw_result
{'n': 5, 'ok': 1.0}
```

Next example: The _find_ (or however it is spelled) function returns a cursor object which can be used to iterate the 0 or more BSON documents the server matched in the query. A _find\_one_ (a.k.a. _findOne_) doesn't oblige to you to first take the cursor reference, then enter a loop to get the BSON results. Instead the result is a single BSON document (or null), once again saving you a little boilerplate code for the common case when you know you should only have one result (or don't care about supplementaries).

The various result types that exist are an interesting topic ... no, they're not. I lied. Whichever driver API you're using it is intuitive, but unchallenging and uninteresting as a result. Cursors iterate documents, writes return write results, the 'list database / collection / index names' functions return a cursor of those names, count returns a integer, etc., etc.

# RPC-ish

## More like an RPC-using lib than a language

People who call it "MQL" reminds us of the 19th century people who used the term "horseless carriage" for the newly-invented automobile. Terms from incompatible old concepts were recycled to describe the new ones.

The automobile was truly something new. But a MongoDB driver is not - it packs requests as command objects (your client program language's data -> BSON command object) and an 'X' command is executed through the matching function just for 'X' in the mongod server code. It's not generic enough to be an RPC, but it's something like that.

## The 'language' is knowing the function reference

You can't just put anything in the _X(...)_ function of course. It expects certain input, some required and some optional, and without the required arguments the driver will reject it even before sending it. At compile time, if it's a compiled language.

For example an update command in it's canonical, MongoDB Wire Protocol and server-side format has the following fields:

- db + collection namespace (set via the scope of a collection object; a collection object pointer; etc.)
- An array of one or more composite update objects with these fields:
  - A filter object to find the document(s) to update
  - The update modifications
  - Optional: upsert true/false
  - Optional: "multi" true/false
  - Optional: collation
  - Optional: filters controlling which nested array items can be affected
- Optional: ordered processing only true/false
- Optional: writeConcern
- Optional: bypassDocumentValidation true/false

Whichever programming language you are using the MongoDB driver API for it will, in it's update function (or update_one and update_many functions), be setting these same required fields and optionally setting the optional fields.

## Your job as the MongoDB-using programmer

### 1. Remember the required arguments.

E.g. that an update needs at least two arguments on top of it's collection namespace scope - one "filter" argument that finds the doc(s) to update; another to set the new value(s) in it. 

### 2. Get familiar with the object-packing format of arguments

When an argument is a scalar value, whether a universal programming datatype such as a string, number, boolean, or MongoDB extended type such as Datetime, ObjectId, etc., its obvious how to pass that.

But when an argument is an object (such as query filter, update modification rule, shard zone tag range) that's not obvious because those design choices are arbitrary. (This applies to any language/system; this is not a MongoDB-specific issue).

```python
//mongo shell javascript example
db.my_collection.find({"x": {"$lt": 100}}, {"_id": true, "dept": true})
```

The line above is equivalent to "SELECT \_id, dept FROM my\_collection WHERE x < 100".

The command-delimted field name list "\_id, dept" directly after the keyword "SELECT" in the SQL query becomes {"\_id": true, "dept": true}. What was "x < 100" put after the "WHERE" keyword in the SQL becomes {"x": {"$lt": 100}}.

Learning the right order of the arguments is trivial, but the choices made on how to represent filter clauses, field lists, update operations are not necessarily the first one you might guess.

So learn the [query filter](https://docs.mongodb.com/manual/tutorial/query-documents/), [field projection](https://docs.mongodb.com/manual/tutorial/project-fields-from-query-results/), [update specification](https://docs.mongodb.com/manual/tutorial/update-documents/) and [index specification](https://docs.mongodb.com/manual/reference/method/db.collection.createIndex/index.html#examples) documents so you have fluent recall of them. The aggregation pipeline stages and operators are also deserve studying until you can at least remember $match, $project and $group fluently too.

The query filter, update specification and aggregation pipeline stages have more-commonly used operators (e.g. $in, $sum, $set) and less-commonly used ones (too many to list). For the less common operatos and other object types (e.g. zoning shard tag ranges) just look them up on the rare occasions you use them.

### 3. Notice when client-side is presenting a pretty picture differing from the server command reality

Plenty of times the client-side function matches up without any noticeable difference to what the server command really is.

But in other cases, particularly for the most-used commands, there are differences in what you see with your programming language's MongoDB driver API vs. the db server-side command spec.

E.g. the reference for the [insert](https://docs.mongodb.com/manual/reference/command/insert/), [update](https://docs.mongodb.com/manual/reference/command/update/) and [delete](https://docs.mongodb.com/manual/reference/command/delete/) server commands show they all take _arrays_ of the new insert / update specification / delete filter docs.

Your (recent version) MongoDB driver has insert-one or insert-many, update-one or update-many, and delete-one or delete-many functions though.

If you're aware that these are really calling the same server-side command it'll prevent you from various worries you might have. For example don't be concerned that calling _insert\_many(\[new\_doc\])_ with a single item in the array is going to have worse performance. It's exactly the same thing as _insert\_one(new\_doc)_ to the server side.

### 4. Keep the optional args in your fuzzy memory

So there's enough in your subconscious to guide you later do make an point of skimming all the options to find things that are novel or otherwise surprising.
