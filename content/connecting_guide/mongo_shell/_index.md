+++
title = "The mongo shell"
date =  2018-05-30T23:26:59+10:00
weight = 20
+++

## What it is

The mongo shell is just another client application. There, I said it. 

It is _not_ a special node within a MongoDB replica set or cluster. It is an application that connects and communicates with the mongod (or mongos) nodes with the same MongoDB Wire protocol TCP traffic that any other application could. If it was a black box rather than being open source, you could reverse-engineer it even without super-dooper elite hacker skills. It has no special sauce that gives it elevated privilege or better performance compared to what any MongoDB driver-using application can have.

What is unique about the mongo shell compared to the thousands of other MongoDB-connected applications you might install on your computer is that is an interactive CLI (command line interpreter) a.k.a. REPL (read-evaluate-print loop). It's not the only one that has ever existed, but it is the only popular one to date.

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
_Javascript that uses a "db" special global object to send commands to the connection to a MongoDB server_

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
//The real code behind "show collections":
if (what == "collections" || what == "tables") {
    db.getCollectionNames().forEach(function(x) {
        print(x);
    });
    return "";
}
```

To recap the mongo shell:

- Uses the MongoDB wire protocol to communicate with MongoDB servers the same as any application
- It doesn't handle the wire protocol 'raw' or control TCP primitives itself. It uses the standard C++ MongoDB client driver for that.
- It is C++ internally
- Makes use of a javascript engine library and "readline"-style line editor library to provide a live Javascript command line interpreter / REPL.
- Can be used to run Javascript code for the sake of Javascript alone, but the purpose is communicate with the database
- There is one "db" MongoDB connection object created which represents the connection to the mongod or mongos host you specified with the --host argument when you began the shell
  - You don't have to use the "db" global var if you don't want. You can manually create other live MongoDB connections objects with connect(\<conn_uri\>), or "new Mongo(\<conn_uri\>)" and give those whatever variable name you like. It would be an untypical way to use the mongo shell however.
- The behind-the-scenes flow every time you execute a db.XXX() command:
  1. You create documents as Javascript objects, and execute Javascript functions in the interpreter. 
  2. The mongo shell converts the Javascript objects to BSON, and the functions to known MongoDB server commands also as BSON objects, ones that includes the BSON-converted javascript argument values (if any), puts it into the OP_MSG request (or legacy OP_QUERY or v3.2(?) experimented OP_COMMAND format requests) and sends it over the network
  3. The server responds with a reply in BSON
  4. The mongo shell converts the reply to a javascript result, and the BSON data is converted to a Javascript object
  5. The converted-to-Javascript-binary-format result is assigned into javascript variable if you set one, or auto-printed into the shell terminal if you did not.

_**Q.** "But what about server-side Javascript? That's what MongoDB uses right?"_

No, that's not what MongoDB uses. Well it can interpret and execute some javascript functions you send to it, but they're only for running within  (TODO confirm these (or at least the first two) are deprecated in 4.0 and removed in 4.2)

- a MapReduce framework command, or 
- if using a $where operator in a find command, or
- as the "reduce", "keyf" or "finalize" arguments in a "group" command.


The $where operator and db.collection.group() command are uncommon ones, they're not MongoDB's equivalent of same keywords in SQL.

These functions are javascript, but they get packed inside a special BSON datatype to be sent to the server and the mongod is the only program I know that has ever been programmed to unpack that format. Being javascript it is a lot slower that the native C++ processing in the mongod process.

I can't call it with certainty, but server-side Javascript looks to be a target for deprecation. The group command is already marked as deprecated as of version 3.4.

### Why use it

Having a CLI is a practical requirement for doing administration, so basically everyone will use it for that reason at least. Most people will also use it for learning. The MongoDB documentation uses mongo shell syntax all over too.

### Common Examples

#### Connection

On the unix (or windows) shell you can specify connection options, and optionally input (a script file to run or a single string to run). The examples beneath show how to connect to.

- A replicaset named "**merch_backend_rs**" 
- It has two normal, data-bearing nodes running at
  - **dbsvrhost1:27017** (the current primary),
  - **dbsvrhost2:27017** (currently a secondary), 
- And an arbiter on a third host somewhere.
- The main user database is "**orderhist**".
- There is a user "**akira**" with password "**secret**", and the usual "**admin**" db is the authentication database (i.e. where the _system.users_ and related system collections are).

Common usage forms shown below. See <a href="https://docs.mongodb.com/manual/reference/program/mongo/">here</a> for the all the options.
```sh
# Most typical. "-u" and "-p" are short for --username, --password.
# The long "--authenticationDatabase" argument can be replaced with
#  "?authSource=admin" as a parameter. But you need to specify that
#  "admin" is the database with the user credentials unless you used
#  the legacy method of creating authentication users in the "orderhist" db.
mongo --host dbsvrhost1:27017/orderhist -u akira -p secret --authenticationDatabase admin

# With an explicit replica set conn string. The benefit compared to default, automatic
#  detection of replica set topology (that you probably unknowingly used all the time 
#  until now) is this method will:
#   1. Change to be connected to the PRIMARY node, so you will be able to make writes
#   2. The connection will succeed even if dbsvrhost1 is down a.t.m.
# So use this type of connection string in your batch scripts.
# (Don't include the arbiter in the host list - it wont authenticate users.)
mongo --host merch_backend_rs/dbsvrhost1:27017,dbsvrhost2:27017/orderhist -u akira -p secret --authenticationDatabase admin

# Using a mongodb URI connection string, the same as in your application code.
#  This will require that you execute "use orderhist" after connecting to get into that
#  db namespace. In this method, with no database name argument specified, "admin" 
#  is the default db namespace for authentication.
mongo --host 'mongodb://akira:secret@dbsvrhost1:27017,dbsvrhost2:27017/?replicaSet=merch_backend_rs'

# If you have disabled authentication in the mongod configuration, and it is 
#  running on port 27017 on localhost, and you want to use the "test" db ...
#  Bingo!, the naked command will work.
mongo

# Execute a javascript script file
mongo --host dbsvrhost1:27017/orderhist -u akira -p secret --authenticationDatabase admin daily_report.js

# Execute a javascript statement as a command-line argument.
mongo --host dbsvrhost1:27017/orderhist_db -u akira -p secret --authenticationDatabase admin --eval 'var acnt = db.collection_a.count(); var bcnt = db.collection_b.count(); if (acnt != bcnt) print("Reconcilliation error: Collection a and b counts differ by " + Math.abs(acnt - bcnt));'
```
