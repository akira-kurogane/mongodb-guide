+++
title = "The delete command"
menuTitle = "delete"
weight = 40
+++

<tt>delete</tt> is simple. The command requires the collection name it is operating on, and technically it can be multiple deletes in one command object (like insert and update), but after that the only argument you usually specify is the "q" (query) filter one. The only other options are <tt>limit</tt> (think of this as a boolean - 1 to limit to 1, 0 for limitation to be disabled) and the uncommonly-used collation option.

Like insert and update one delete command accepts an array of delete statements,

I really only want to point out two things:

- Set an empty filter argument and you will delete **all** documents. For some this is anti-intuitive: 'I specified nothing, nothing should be deleted' is the idea. Lose this idea! This is a filter - "filter nothing" == "do it to everything".
- **Deletes are not 'cheap'**. They must do approximately the same I/O that an update command does. Removing the document from secondary indexes efficiently requires knowing the key values it was placed by in those indexes &ndash; and the best way to get those is to read the entire document that you will soon 'destroy' and never read again.<br>The human concept for delete is 'forgetting about those documents'. In mental enery terms nothing could be easier. Instead of that, though, think of it as a clean-up that you must do right now, no excuses, before you do anything else.<br>Dropping a whole collection on the other hand is quick and 'cheap' for the size of data being released.
