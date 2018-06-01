+++
title = "Making MongoDB fast"
date = 2018-05-31T13:59:10+10:00
weight = 160
chapter = true
draft = true
pre = "<b>6. </b>"
+++

### Chapter 6

# Making MongoDB fast

## How fast? A db request lifecycle in microseconds.

A _to-the-nearest-power-of-10_ guestimate of the execution time of a small query

- on a well-tuned, high spec VM in well-tuned network,
- with minimal write or read concern and
- no transaction:

timespan (μs) | action
---------|----------------------------------------------------
10 | native datatype to BSON command marshalling
10 | us transfer to NIC via kernel
1000 | client -> db server LAN transfer
100 | execution within the mongod query engine
1000 | LAN transfer back to client
10 | NIC -> kernel -> client app memory in userspace
10 | marshalling BSON back to native data type


\[picture of the bar of the above, with ms scale]

#### A note about write and read concerns

TODO

{{% children  %}}
