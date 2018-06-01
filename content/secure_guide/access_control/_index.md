+++
title = "Access control (a.k.a. Authorization)"
date =  2018-05-31T16:28:25+10:00
draft = true
weight = 15
+++

### Action privileges

There are over 50 unique built-in privilege action types. This might seem a bit overwhelming, but don't worry mostly they are fine-grained ones that are 1-to-1 with a single server command type. E.g. the reIndex privilege action type is only for running the reIndex command, and the vice versa relationship also applies: the reIndex command can only be run by a user who has a role that includes the reIndex action privilege.

The main privileges actions are 1-to-n though. The "find" action privilege is the main example. It permits the user to execute find of course, but also to execute approx 20 other commands such count, getmore, listIndexes, etc, that would be pointless to separate. E.g. if I can run a find command (a.k.a. a query) then I am capable of deriving the count by reading all documents and doing nothing with the data except to increment a counter for every document fetch. There's no point to withholding the count action privilege to anyone who has the ability to run a find command.

N.b. MongoDB is more permissive about creating new namespaces than older DBMS have been on average. A user that has the insert action privilege (say through having the "write" role) implicitly has the ability to create any collection in a database they have the action for. And if they have the privilege without restriction to a database namespace then they are also implicitly capable of creating a new database.

### Roles

Users are not granted action privileges directly. Those are always assigned via a role. There's nothing significant about this, just remember that there is no 'grant action y to user x' command. It is 'assign privilege y to role z', then 'grant role z to user x'.

The 'assign privilege y to role z' == db.grantPrivilegesToRole(), or set initial list in db.createRole()

The 'grant role z to user x' == db.grantRolesToUser(), or set initial list in db.createUser().

Most of the time the built-roles already conveniently include precisely the group of actions you want to grant so making a custom role with actions is not common.

Making a custom role that inherits other roles is more common. Functions such as db.grantRolesToRole() are what this is for of course.

The built in roles break up into the following hierarchy:

- Database user roles: Just two: "read" and "readWrite". For typical read and write access to user collections. Listing of databases and collections included. "readWrite" roles also grant index manipulation to the collections they apply.
- Database administrator roles: "userAdmin" and "dbAdmin". N.b. neither grant readWrite, even though they allow you to change user's abilities, or drop or repair collections. You can get both of those plus readWrite by using the "dbOwner" role.
- Cluster administrator roles: These roles give the privilege to run commands for checking or changing the toplogy of replica sets or sharded clusters. Eg. replsetGetStatus, addShard, shardCollection.
- Backup and restore roles: Close to but not exactly the same as the Database administration roles.
- Superuser roles: "root" is the most powerful role, but it is not all-powerful like the unix root user. It is a role that inherits other strong roles (see documentation) but this is an explicit set and there could be privilege gaps for doing some rarely-used actions in the non-user databases (i.e. in admin, local and config).
- "\_\_system" is designed for internal use, to represent other mongod and mongos nodes in a replica set or cluster. It's a bad idea to use it for two reasons.
  1. Too powerful for normal users, just like granting root to a unix user.
  2. As it is 'internal use only' the privileges could be reduced in a new release, i.e. your app might lose an assumed permission when you do a MongoDB update in the future.
- \*AnyDatabase roles: Mostly these mean "Any user database + the admin database", i.e. they exclude the local and config databases.
