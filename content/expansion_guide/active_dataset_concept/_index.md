+++
title = "Active dataset - Key concept"
date =  2018-05-31T15:58:46+10:00
draft = true
weight = 5
+++

## Historical data growth v.s. Active data growth

\[Active data set explainer.\]


If your data growth is basically historical only then the nice news you only have to get more disk for now. Your total data size can grow to a new level without provisioning more RAM or CPU power.


You can't grow just total disk size infinitely though. Imagine that one server in your replica set dies and has to be repaired after getting parts shipped in. When the repaired node is added back into the replicaset it will perform an initial sync. That is the total data - not just the active data set. All of it will be read from the disk of the sync source node and written into the disk on the resyncing node. If you have 5 TB but you have slow disks that can only write, say, 30MB/s, then it will take more than 48 hours for that to be copied.


So the maximum size total data size on one server should be the amount that can be comfortably copied in an initial sync of new replica set node.
