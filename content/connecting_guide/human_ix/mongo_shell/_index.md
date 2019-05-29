+++
title = "The mongo shell"
description = "The simple truth about the mongo shell"
date =  2018-05-30T23:26:59+10:00
weight = 20
+++

## What it is

The mongo shell is just another client application. There, I said it. 

It is _not_ a special node within a MongoDB replica set or cluster. It is an application that connects and communicates with the mongod (or mongos) nodes with the same MongoDB Wire protocol TCP traffic that any other application could. If it was a black box rather than being open source, you could reverse-engineer it even without super-dooper elite hacker skills. It has no special sauce that gives it elevated privilege or better performance compared to what any MongoDB driver-using application can have.

What is unique about the mongo shell compared to the thousands of other MongoDB-connected applications you might install on your computer is that is an interactive CLI (command line interpreter) a.k.a. REPL (read-evaluate-print loop). It's not the only MongoDB CLI that has ever existed, but it is the only popular one to date.

### Why use it

Having an interactive shell is a practical requirement for doing administration, so basically everyone will use it for that reason at least. Most people will also use it for learning. The MongoDB documentation uses mongo shell syntax all over too.

### Connection examples

On the unix (or windows) shell you can specify connection options, and optionally input (a script file to run or a single string to run).

If you are not already familiar with the command-line arguments the mongo shell accepts please expand the following section.

{{%expand%}}
The examples beneath show how to connect to:

- A replicaset named "**merch_backend_rs**" 
- It has two normal, data-bearing nodes running at
  - **dbsvrhost1:27017** (the current primary),
  - **dbsvrhost2:27017** (currently a secondary), 
- And an arbiter on a third host somewhere.
- The main user database is "**orderhist**".
- There is a user "**akira**" with password "**secret**", and the usual "**admin**" db is the authentication database (i.e. where the _system.users_ and related system collections are).

Common usage forms shown below. See <a href="https://docs.mongodb.com/manual/reference/program/mongo/">here</a> for the all the options.
```sh
# Most typical
mongo --host dbsvrhost1:27017/orderhist -u akira -p secret --authenticationDatabase admin

# Specify the replicaset name to guarantee a proper replset connection
mongo --host merch_backend_rs/dbsvrhost1:27017,dbsvrhost2:27017/orderhist -u akira -p secret --authenticationDatabase admin

# Using a mongodb URI connection string, the same as in your application code.
mongo --host 'mongodb://akira:secret@dbsvrhost1:27017,dbsvrhost2:27017/orderhist?authSource=admin&replicaSet=merch_backend_rs'

# If you have disabled authentication in the mongod configuration, and it is 
#  running on port 27017 on localhost, and you want to use the "test" db ...
#  Bingo!, the naked command will work.
mongo

# Execute a javascript script file
mongo --host dbsvrhost1:27017/orderhist -u akira -p secret --authenticationDatabase admin daily_report.js

# Execute a javascript statement as a command-line argument.
mongo --host dbsvrhost1:27017/orderhist_db -u akira -p secret --authenticationDatabase admin --eval 'var acnt = db.collection_a.count(); var bcnt = db.collection_b.count(); if (acnt != bcnt) print("Reconcilliation error: Collection a and b counts differ by " + Math.abs(acnt - bcnt));'
```

In the case of sharded cluster do _not_ add a replicaset parameter in the connection arguments. Just provide the hostname(s) and por(s) of the mongos node(s) you are connecting to.
{{%/expand%}}

## Internals

Although it is made with C++ the language that this CLI interprets is Javascript. Apart from a very small number of legacy, imperative-style command expressions such as "show databases", "exit", etc. everything is Javascript.

### Shell parsing

#### Legacy MySQL-like commands

```text
use <database_name>
show databases
show collections
```

Apart from "use _database\_name_", which sets the database namespace the client sends in the Wire Protocol requests, these legacy command expressions are all translated internally to a Javascript function. For example "show collections" is really:

```js
//From mongo/shell/utils.js
//The real code behind "show collections":
if (what == "collections" || what == "tables") {
    db.getCollectionNames().forEach(function(x) {
        print(x);
    });
    return "";
}
```

#### Plain Javascript

The mongo shell will process javascript with referring to any database context if you want to! Below are some client side-only expressions and functions, pretty much identical to those you can do in the native Javascript supported in web browsers etc.

```js
var x = 1;
for (i = 0; i < 100; i++) { print(i); }
function max(a, b) { return a > b ? a : b; }
```

#### Javascript that acts with database connection objects

Unless you use the --no-db argument there will be the "db" special global object which can be used to send db command messages over the connection to a MongoDB server.

```js
use <database_name>  //set current database namespace
db.version()    //database namespace doesn't affect this particular command
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

In the example above:

1. _&lt;database\_name&gt;_ is set as the db scope. This will go in command objects put into MongoDB Wire protocol messages sent from here. It won't be changed there is another "use xxxxx" statement or something that implies it, like a _db.getSiblingDB(...)_ function.
2. _db.getVersion()_ will create a <tt>buildinfo</tt> command as BSON object. Through javascript-interpreter-to-C++-code boundary and then the C++ driver library that is put that in wire protocol message message and send it the db server. The response travels those layers in reverse, finally ending with the <tt>buildinfo</tt> result in Javascript object, from which the _version_ property is picked and printed.
3. _db.serverStatus()_ is a helper function that executes _db.adminCommand({serverStatus: 1})) instead. I.e. this time the BSON object being packed and set is _{serverStatus: 1}_ compared to _{hostinfo: 1}_. At the return the whole object (rather than just one scalar value property) is pretty-printed onto the terminal output.
4. A similar pattern at first to the last two comands, just that a _{find: "database\_name.collection\_name"}_ BSON object is being sent. However this time there will be a cursor with results. Through the driver API each document in the cursor results will be passed separately with each iteration of the cursor. If more results need to be fetched from the server side <tt>getMore</tt> requests holding the cursor id value from the <tt>find</tt> command's result will be sent and read repeatedly until the cursor is exhausted (or times out) on the server side.

#### Ever-present db namespace

The sent commands always includes a database namespace. You can change it at will ("use _another\_db\_name_") so it is variable, but it can't be empty/null. Default is "test".

Some commands don't logically require a db namespace &ndash; eg. isMaster, addShard, replSetGetStatus &ndash; but they won't work unless it is set to "admin". Many a time I've had those fail until I typed "use admin" and tried again. Some like isMaster you don't notice because you're probably never call it except by the a shell helper function (_db.isMaster()_) that sets it.

_Crystal ball gazing:_ Having said all this it isn't out the question that what is unnecessary will be removed in the future. The [OP_MSG](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/#op-msg) message format in particular doesn't require or even permit a db namespace in the network fields, so once older messages formats stop being supported some rationalization is possible. E.g. the db server (mongod or mongos) could just silently ignore the db name scope from the client when it is a command such as isMaster, serverStatus, etc.

### Explicit db connection objects

You don't have to use the "db" global var if you don't want to. You can manually create other live MongoDB connections objects with <tt>connect(&lt;conn_uri&gt;)</tt>, or <tt>new Mongo(&lt;conn_uri&gt;)</tt> and give those whatever variable name you like. It would be an untypical way to use the mongo shell however.

**TODO** expand on what the wire protocol traffic is for all commands in the example above.

### Recap

To recap the mongo shell:

- Uses the MongoDB wire protocol to communicate with MongoDB servers the same as any application
- It is C++ internally
- Makes use of a javascript engine library and "readline"-style line editor library to provide a live Javascript command line interpreter / REPL.
- It doesn't handle the wire protocol 'raw' or control TCP primitives itself. It uses the standard C++ MongoDB client driver for that.
- Can be used to run Javascript code for the sake of Javascript alone, but the purpose is communicate with the database
- There is one "<tt>db</tt>" MongoDB connection object created which represents the connection to the standalone mongod or replicaset of mongod nodes or mongos host you specified with the --host argument when you began the shell. (TODO LINK to connection URI page)
- The behind-the-scenes flow every time you execute a db.XXX() command:
  1. You create documents as Javascript objects, and execute Javascript functions in the interpreter. 
  2. The mongo shell converts the Javascript objects to BSON, and the functions to known MongoDB server commands, which are also serialized in a BSON format. These include the argument values (if any), puts it into the OP_MSG request (or legacy OP_QUERY or the v3.2(?) experimental OP_COMMAND format requests) and sends it over the network
  3. The server responds with a reply in BSON
  4. The mongo shell converts the reply to a javascript result, and the BSON data is converted to a Javascript object
  5. The converted-to-Javascript-binary-format result is assigned into a javascript variable if you set one, or auto-printed into the shell terminal if you did not.

_**Q.** "But what about server-side Javascript? That's what MongoDB uses right?"_

No, that's not what MongoDB uses. Well it can interpret and execute some javascript functions you send to it, but they're only for running within:

- a [MapReduce](https://docs.mongodb.com/manual/core/map-reduce/) command, or 
- _(Superseded by $expr in v3.6; removed v4.2):_ if using a $where operator in a <tt>find</tt> command, or
- _(Deprecated v3.4; removed v4.2):_ as the "reduce", "keyf" or "finalize" arguments in a <tt>group</tt> command.

These functions are javascript, but they get packed inside a special BSON datatype to be sent to the server and the mongod is the only program I know that has ever been programmed to unpack that format. Being javascript it is a lot slower than the native C++ processing in the mongod process.
