+++
title = "Auditing"
date =  2018-05-31T16:32:55+10:00
draft = true
weight = 35
+++

The audit module is only included in the Enteprise edition of MongoDB. It creates an extra append-only log that tracks certain actions (which ones exactly is configurable) and provides guarantees that writes won't be lost except possibly those in the last moments before a sudden crash.

What this really covers against is a DBA who is malicious, and whom would otherwise have all the database permissions they need to cover up the tracks of some sort of dirty work. They can change data, user permissions, etc. at will, but in the process of doing actions such as:

- connecting and authenticating
- altering users
- creating or dropping collections
- removing or adding new hosts into a replica set cluster 

they will leave the trace of that in the audit log, and there's no 'hack' any MongoDB connection, regardless of it's privilege, can do to reverse that.

Nothing's perfect - this type of Audit Log won't prevent a malicious DBA who is working with in collusion with a Server administrator who can rewrite the filesystem the audit log is saved to. But clearly it makes it harder.

The downside to auditing is that it makes the database slower. The guarantee that audit log writes are never lost, and never out of order, is achieved by using a global lock to add messages plus performing a disk flush for more or less every audit log write. A disk flush is 10^3, 10^4 slower than the typical in-memory write of a document
