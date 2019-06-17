+++
title = "'MQL' vs. SQL"
description = "'MQL' vs. SQL"
date =  2018-05-31T14:47:29+10:00
weight = 5
+++

# Call a function; don't write a statemen

## 1. There is no MongoDB query _language_

The "L" in SQL is "Language". A syntax that defines how you can write a sentence such as "SELECT usr\_id, COUNT(\*) AS count FROM TableA GROUP BY usr\_id" that can be parsed to become query or update plans.

MongoDB driver API's don't require that. They don't require you to 'program' a piece of text for the remote database server to parse (and potentially throw a syntax error on).

## 2. Call a function and give it arguments.

Depending on which language you are programming your client application the API will be different, but the common thing is that you make database requests by calling a function.

Here are some examples covering one OOP and one imperative style language:

```
//Python
my_collection.insert_one(doc)

//C
mongoc_collection_insert_one(my_collection_pointer,
                             doc_pointer, NULL, NULL, &err);
```

The library that provides the functions is the MongoDB driver. The above are provided by [PyMongo](https://api.mongodb.com/python/current/) and [mongoc](http://mongoc.org/). The Java MongoDB driver is idiomatic for Java, the NodeJS MongoDB driver is idiomatic for NodeJS, the C# MongoDB driver is idiomatic for C#, etc, etc.

### Think of collection name as an argument too

In the example above there are two arguments, although the OOP example makes it easy to miss. There is the collection that will be inserted to (whi database namespace), plus the doc that will be inserted.

A database namespace will always be in scope too. Database name is typically set when you created the db connection so it wont be in function-calling code line, but the driver will be packing it in every request for you behind the scenes.

## 3. Receive the result

Nothing new here for database-using programmer. When you call the function there will be a call over the network to the MongoDB server and it will return a result of some type. The format of that result object will be once again idiomatic to the language you are programming in.

In the examples above the result was ignored so the driver's good work marshalling that BSON data returned from the network was in vain.

```python
>>> posts = db.posts
>>> post_result = posts.insert_one(post)
>>> post_result
TODO
```

# RPC-ish

## More like an RPC-using lib than a language

People who call it "MQL" reminds us of the 19th century people who used the term "horseless carriage" for the newly-invented automobile. Terms from incompatible old concepts were recycled to describe the new ones.

The automobile was truly something new. But a MongoDB driver is not - it packs requests as command objects (your client program language's data -> BSON command object) and an 'X' command is executed through the matching function just for 'X' in the mongod server code. It's not generic enough to be an RPC, but it's something like that.

## The 'language' is knowing the function reference

You can't just put anything in the _X(...)_ function of course. It expects certain input, some required and some optional, and without the required arguments the driver will reject it even before sending it. At compile time, if it's a compiled language.

For example an update command in it's canonical, MongoDB Wire Protocol and server-side format has the following fields:

- collection namespace (set via the scope of a collection object; a collection object pointer; etc.)
- An array of one or more composite update objects
  - A filter object to find the document(s) to update
  - The update modifications
  - Optional: upsert true/false
  - Optional: "multi" true/false
  - Optional: collation
  - Optional: filters controlling which nested array items can be affected
- Optional: ordered processing only true/false
- Optional: writeConcern
- Optional: bypassDocumentValidation true/false

Your job as the MongoDB-using programmer is:

1. To remember the required arguments. E.g. that an update needs at least two arguments on top of it's collection namespace scope - one "filter" argument that finds the doc(s) to update; another to set the new value(s) in it. 
1. When an argument is an object it expressed whatever it is a key-value object way. Your MongoDB driver API will accept those in different ways, depending on what the idiomatic way to pass or make dictionary/map objects is for the language. These cannot be intuitively guessed by any first-timer i.m.o.
   - E.g. the filter argument used in many commands is equivalent to the WHERE clause in SQL. The clause _"... WHERE a = 1 AND b = 'TEX'"_ would be `{"a": 1, "b": "TEX"}` in JSON format.
   - E.g. the update modification object to, say, set field "c" to 100 and "d" to boolean true will be `{"$set": { "c": 100, "d": true } }`.
1. Work out there are some differences in what you see with your programming language's MongoDB driver API vs. the db server-side command spec. E.g. the reference for the [update server command](https://docs.mongodb.com/manual/reference/command/update/) shows it takes an _array_ of update objects. It can be used flexibly to make one sort of update or can accept multiple different types of update, like a bulk write situation. Using the API of the Java driver as an example:
   - _collection_.updateOne(.., ..) -> has one modification, and it will be applied to only one document at most
   - _collection_.updateMany(.., ..) -> has one modification, which will be applied to as many documents as the filter matches. This will also put one object in the updates array argument.
   - _collection_.bulkWrite(...) -> takes an array list of updates (and/or inserts and deletes), each with their own filter and modification argument (and other optional args)
1. Keep in your fuzzy memory there are other args, so when you truly need to answer, say, the question 'does an update command update all the docs it matches or just the first one?' you'll be able to find that quick. (The answer is: it'll stop at the first unless you set "multi" to true.
