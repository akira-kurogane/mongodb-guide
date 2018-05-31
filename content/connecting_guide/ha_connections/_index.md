+++
title = "Automatic failover"
date =  2018-05-30T23:41:54+10:00
weight = 25
+++

Although it hasn't been discussed in the book in detail so far, in the typical situation your client will be connected to a replica set, that is it will be sending writes to one node (the Primary) whilst also being connected to other nodes that are Secondaries. As long as the Primary is alive, accepting commands, and the other nodes continue to agree that it is the primary, that will continue without change.

But if the original primary node dies, or get cuts off network-wise from the other nodes, they will initiate a replica set election and one of them will become the new primary.

There be may some writes to the original primary that will have to be rolled back, particularly in an unbalanced network partition situation. That is an issue that means the rolled back operations will have to be examined manually and re-applied manually by administrators after the incident.

The election would take a fraction of a second usually (2 seconds at most), faster than any human is going to be able to react, so you want the application to automatically switch to use the new primary. What do you do to make sure this happens and avoid having every single thread in every single process throw endless repeating 'socket exception' or 'write rejected not primary' errors?

The answer is nothing. You don't have to do anything. All the drivers have replica set automatic failover logic programmed into them.

~~As well as all the drivers having the failover logic built into it is the same between all of them, at least for the officially-supported ones. The earliest versions of the drivers maybe were not so close but since the time the 3.4-compatible versions were released all the officially supported drivers follow the same Server Selection and Server-discovery and Monitoring specifications.~~

From the point of view of the application code using a MongoDB connection, database, or collection object it can continue to use the same object. The driver will route the reads and writes to the new primary. If you have explicitly requested reads to come from a non-primary node (possible with a feature called readPreference, to be discussed later) the connection for those will be changed away from the new primary node too.

So the challenge of staying connected is solved for you out of the box whichever driver you use. What is not handled is what to do with rolled back data. Rollbacks can occur in the case that the original primary doesn't step down immediately, and accepts some writes in the brief time before it determines it has lost the status updates from the other nodes and steps itself down. This will be explained more in the "Making MongoDB stable" chapter.
