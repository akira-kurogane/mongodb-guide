+++
title = "Network encryption"
date =  2018-05-31T16:32:06+10:00
draft = true
weight = 20
+++

TODO make overview of client <-> db encryption, node-to-node encryption ..

Todo question: is node-to-node encrypted?

## TLS/SSL setup
Setting up a set of SSL certificates is not an easy business, and I've never seen a production deployment that used the same SSL options as another, so I won't give a demonstration purporting to be a standard case.

But once you have created/obtained a set of certificates and have confirmed they mutually authenticate each other, then configuring the mongod and mongos nodes to use those certificates is simple. 

Another way of putting it would be: If you're an SSL expert you're going to be pleasantly surprised how easy it is enable TLS/SSL in MongoDB. But if you're a DBA who is doing a SSL setup for the first time it's going to be hard.

There are different arrangements that can be used.

SSL validation scheme | Servers required option: | Client uses: | mongo shell example
----------------------|--------------------------|--------------|----------------------
Simple, shared PEM | net.ssl.PEMKeyFile | The same PEM file | --sslPEMKeyFile
Server-only? PEM with Certificate Authority | net.ssl.PEMKeyFile net.ssl.CAFile | The same CA file | --sslCAFile \<ca.pem\>
Separate client and server certificates | net.ssl.PEMKeyFile net.ssl.CAFile | Client's certificate PEM file and the same CA file | --sslPEMKeyFile \<client.pem\> --sslCAFile \<ca.pem\>

Create / obtain your certificates (whether they're CA'ed, or you use client certificates or not) first; test with SSL utilities next; then add them as options to your mongod servers and clients after.

