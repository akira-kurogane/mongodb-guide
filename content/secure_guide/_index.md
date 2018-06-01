+++
title = "Making MongoDB secure"
date = 2018-05-31T14:01:46+10:00
weight = 170
chapter = true
draft = true
pre = "<b>7. </b>"
+++

### Chapter 7

# Making MongoDB secure

There are five main ways to raise the security of your MongoDB deployment. Authentication and Authorization must be activated in unison, and Auditing requires Authentication as a prerequisite, but otherwise they can be used independently of each other.

- Authentication of user connections (== Identity)
- Authorization (== DB command permissions)
- Auditing _(Enterprise version only)_
- Network Encryption
- Storage Encryption

### The table of 'bad guys'

   | The type of 'bad guy' being repelled
---|---
Authentication | An unknown person, whom you didn't realize had network access to the database server, who just 'walks in' and looks at (or damages) the database data.
Authorization | A user who (or an application that) reads or alters or destroys data other than what they were supposed to.<br>The 'bad guy' is usually a friend who does it by accident so it's mostly for Safety rather than Security, but it also prevents malicious cases too.
Auditing | A privileged database user who knows how to cover up their tracks after altering database data.
Network Encryption | Someone who takes a copy of data being transferred over a network link somewhere between your application server A and your database server B, then decodes it from the Mongo Wire protocol format to something human-readable.
Storage Encryption | Someone who breaks in and steals your server's hard disk so that can read the data files on it.<br>In practice they would probably steal the file data over the network, but the concept is still someone who steals a copy of the database files.

_**Q.** "These Authxxxx and Authyyyy words … the_ same _thing right?"_

_**A**_. No, Yes. Yes, No.

**No**: Because they are two parts of the software that do different things

Authentication  == User Identity, by means of credential checking.

Authorization == Assigning and enforcing DB object and DB command permissions.

**Yes**: Because enabling Authentication automatically enables Authorization too.

Why I think MongoDB does this:

Why authenticate if you don't want to stop unknown users for accessing or changing data? Authorization is enabled in unison with authentication so connections from unknown users will have no privilege to do anything with database data. 

Authorization requires the user name (verified by Authentication) to know which privileges apply to a connection's requests.

**Yes**: In unfortunate, legacy naming of configuration options

The commandline argument for enabling authentication (which forces authorization to be on too) is simply "--auth". Even worse the configuration file option name for the same thing authentication is `security.authorization` rather than `security.authentication`. When you use it though the first thing that is being enabled is Authentication, and Authorization is only enabled as an after-effect.

**No**: Because during Authentication's initial setup it is disabled for localhost connections.

Briefly, when you enable them for the first time, Authentication is enabled but Authorization is ineffective. This is because there needs to be a chance to define the first user.

\[TODO: screen of using mongo shell to create the first user with userAdminAnyDatabase via the localhost exception]

Another situation, which readers of this guide are unlikely to encounter, is when a 3.6+ replica set or cluster with authentication off has it enabled node-by-node in two phases of rolling restart that ensures the cluster as whole is always up. 

{{% children  %}}
