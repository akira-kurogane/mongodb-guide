---
title: "Top page"
---

# Akira's guide to MongoDB

A guide aimed towards:

- Server / database administrators who will be running MongoDB servers, or
- Application developers who want a deep understanding of the performance, communication and high-availability behaviour of MongoDB clusters.  

The chapter structure and topic emphasis is shaped by my experience working for MongoDB support. That is it is weighted according to what sort of questions and conceptual gaps I know are more common amongst professional MongoDB users, including those with many years experience of relational databases.

Driver API usage will be explained in tandem with Mongo Wire Protocol as it is the common reality underlying all of the drivers. It is also the key piece of the picture when understanding how and when client requests and the server responses enter and leave the <tt>mongod</tt> and <tt>mongos</tt> server processes.

