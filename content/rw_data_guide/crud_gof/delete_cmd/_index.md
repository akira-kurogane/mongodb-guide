+++
title = "The delete command"
menuTitle = "delete"
draft = true
weight = 40
+++

<tt>delete</tt> is simple - the only argument it takes usually is the "q" (query) filter one. The only other options are <tt>limit</tt> (think of this as a boolean - 1 to limit to 1, 0 for limitation to be disabled) and the uncommonly-used collation option.

I really only want to point out three things:

- Set an empty filter argument and you will delete all documents. For some this is anti-intuitive: 'I specified nothing, nothing should be deleted' is the idea. Lose this idea! This is a filter - "filter nothing" == "do it to everything".
- Deletes are not 'cheap'. They must do approximately the same I/O that an update command does. The human concept is 'forgetting about those documents', which is easy! Think of it as a clean-up that is done immediately.<br>Dropping a whole collection at once is quick and 'cheap' for the size of data being released.

----

The documentation says "New in version 2.6.". What!? So MongoDB was an append-only database before then?

No, before v2.6 you sent an OP\_QUERY, OP\_INSERT, OP\_UDPATE or OP\_DELETE mongo wire protocol message. The entry into the DB server went through the same code path that a <tt>{ delete: &lt;collection\_name&gt;, ... }</tt> command does (more or less).
