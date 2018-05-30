+++
title = "The mongo shell"
date =  2018-05-30T23:26:59+10:00
weight = 20
+++

## What it is

The mongo shell is just another client application. There, I said it. 

It is _not_ a special node within a MongoDB replica set or cluster. It is an application that connects and communicates with the mongod (or mongos) nodes with the same MongoDB Wire protocol TCP traffic that any other application could. If it was a black box rather than being open source, and free, you could reverse-engineer it even without super-dooper elite hacker skills. It has no special sauce that gives it elevated privilege or better performance compared to what any MongoDB driver-using application can have.

What is unique about the mongo shell compared to the thousands of other MongoDB-connected applications you might install on your computer is that is an interactive CLI (command line interpreter). It's not the only one that has ever existed, but it is the only popular one to date.

Although it is a C++ program the language that this CLI interprets is Javascript. Apart from a very small number of legacy, imperative-style command expressions such as "show databases", "exit", etc. everything is Javascript.

_Legacy MySQL-like commands:_
```text
use <database_name>
show databases
show collections
```
_Normal Javascript. Some client side-only expressions and functions, pretty much identical to the native Javascript supported in web browsers etc._
```js
var x = 1;
for (i = 0; i < 100; i++) { print(i); }
function max(a, b) { return a > b ? a : b; }
```
_Javascript that uses "db" special global object to send commands to the connection to a MongoDB server_

```javascript
use <database_name>  //set current database namespace
db.getVersion()    //database namespace doesn't affect this particular command
//Because I did not capture the result into a variable (i.e. I didn't put "var version_result = …" at the front)
//  the shell will capture the return value from db.getVersion() and auto-print it here
3.4.4
db.serverStatus()    ///database namespace doesn't affect this particular command
//As before, the return value from the statement will be auto-printed.
db.serverStatus()
{
    "host" : "myhost.mydomain",
    "version" : "3.4.4",
    "process" : "mongod",
    "pid" : NumberLong(2175),
    ...
    ...
    "ok" : 1
}

var cursor = db.<collection_name>.find({"customer_id": 10034});     //this command is affected by the database namespace
while (cursor.hasNext()) {
  var doc = cursor.next();
  printjson(doc);
}
...
```

By the way apart from "use <database_name>", which sets the database namespace the client sends in the Wire Protocol request, those legacy command expressions are just translated internally to a Javascript function. For example "show collections" is really:
```js
//From mongo/shell/utils.js
if (what == "collections" || what == "tables") {
    db.getCollectionNames().forEach(function(x) {
        print(x);
    });
    return "";
}
```

To recap the mongo shell:

- Uses the MongoDB wire protocol to communicate with MongoDB servers the same as any application
- It is C++ internally
- Makes use of javascript engine library and "readline"-style line editor library to provide a live Javascript command line interpreter
- Can be used to run Javascript code for the sake of Javascript alone, but the purpose is communicate with the database
- There is one "db" MongoDB connection object created which represents the connection to the mongod or mongos host you specified with the --host argument when you began the shell
  - You are not forced to use the "db" global and the "db" global alone. You can manually create other live MongoDB connections objects with connect(\<conn_uri\>), or "new Mongo(\<conn_uri\>)". It would be an untypical way to use the shell however.
- The behind-the-scenes flow every time you execute a db.XXX() command:
  1. You create documents as Javascript objects, and execute Javascript functions in the interpreter. 
  2. The mongo shell converts the Javascript objects to BSON, and the functions to known MongoDB server commands also as BSON objects, ones that includes the BSON-converted javascript argument values (if any), puts it into the OP_COMMAND and sends it over the network
  3. The server responds with a reply in BSON
  4. The mongo shell converts the reply to a javascript result, and the BSON data is converted to a Javascript object
  5. The converted-to-Javascript-binary-format result is assigned into javascript variable if you set one, or auto-printed into the shell terminal if you did not.

_**Q.** "But what about server-side Javascript? That's what MongoDB uses right?"_

No, that's not what MongoDB uses. Well it can interpret and execute some javascript functions you send to it, but there only for running within 

- a MapReduce framework command, or 
- if using a $where operator in a find command, or
- as the "reduce", "keyf" or "finalize" arguments in a "group" command.


The $where operator and db.collection.group() command are uncommon ones, they're not MongoDB's equivalent of same keywords in SQL.

These functions are javascript, but they get packed inside a special BSON datatype to be sent to the server and the mongod is the only program I know that has ever been programmed to unpack that format. Being javascript it is a lot slower that the native C++ processing in the mongod process.

I can't call it with certainty, but server-side Javascript looks to be a target for deprecation. The group command is already marked as deprecated as of version 3.4.

### Why use it

Having a CLI is a practical requirement for doing administration, so basically everyone will use it for that reason at least. Most people will also use it for learning. The MongoDB documentation uses mongo shell syntax all over too.

### How you use it

\[TODO: Connection example; Oh look, a javascript sandbox. With auto-magic printing of returned vals. Initial poke via an isMaster command as another example. db.createUser()?\]

https://docs.mongodb.com/manual/reference/program/mongo/