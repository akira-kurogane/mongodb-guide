---
title: "Top page"
---

# Akira's guide to MongoDB

A guide aimed towards:

- Server / database administrators who will be running MongoDB servers, or
- Application developers who want a deep understanding of the performance, communication and high-availability behaviour of MongoDB clusters.  

The 'light' version:
Read chapters 1 -3.

- This is enough for application developers who want to get started quickly. The skimming of the latter chapters should give you awareness of the limitations/possibilities that will matter later when your application is a roaring, supernova-size success ;) with data storage and performance needs that have grown accordingly.

Differences between this guide and currently available guides/texbooks available I've seen in stores until now are:

- The chapter structure and topic emphasis is shaped by my experience working for MongoDB support. That is it is weighted according to what sort of questions and conceptual gaps I know are more common in the user-base of professional MongoDB users.
Features and facets that are intuitive or common-sense concepts, or are rarely used ones, will not appear or at most have just a note it is uncommonly used plus a link out to MongoDB's documentation.
- The more verbatim details that we all forget (and have to look up later anyway) are _not_ included here either. Instead there will only be links to the right page for it in the official https://docs.mongodb.com/manual/ documentation site. Viva la internet!
- I also happily link out to the MongoDB documentation for the stuff such as the _Getting Started_ tutorials which are well-polished texts that need no redoing.
- I'll emphasize legacy 'gotchas'. E.g. not to use deprecated features like the old <= v2.4 config file format.
- Driver API usage will be explained in tandem with Mongo Wire Protocol, as this is the common reality underlying all of them. It is also the key piece of the picture when understanding how and when client requests and the server responses enter and leave the <tt>mongod</tt> and <tt>mongos</tt> server processes.
