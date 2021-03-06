+++
title = "MongoDB Diagnosis"
date = 2018-05-31T14:02:39+10:00
weight = 180
chapter = true
draft = true
pre = "<b>8. </b>"
+++

### Chapter 8

# MongoDB Diagnosis

There are four sources of diagnostic information of mongod:

0. (Yeah, I didn't include this in "four sources) The mongod (or mongos) is an OS process. It consumes resources - memory, CPU time, IO ops - and uses a number of OS primitives - threads, file handles (including network sockets) - and how much those resources are used, and the deltas from one second to next, gives a picture of the movements of the mongod process _if_ you have a conceptual picture of the software. At a more advanced level back traces and perf analysis can be done.
1. serverStatus. 600+ metrics included! Most monotonic counters (e.g. number of updates executed, number of pages read into cache), some current-value (e.g. number of connections), a few derived calculations (e.g. op latency). This data saved into FTDC every second.
2. Log. The mongod/mongos log is composed of lines generated by "LOG() << ..." or "log << " code lines in the mongod/mongos C++ code. Each one is a ISO-8601 date-and-time string, a 'severity' (D, I, W, E, F), component (SHARDING, ACCESS, COMMAND, etc), thread name ("\[rsBackgroundSync\]", "\[conn123456\]", etc.), then free text. But the majority of that free text comes from COMMAND lines that share a certain pattern - command type, db and collection name, command arguments, execution stats and always including the execution time at the end in a ' [0-9]\*ms$' pattern. Not shown in the log lines is the _logLevel_ of the line. Raise the logLevel above default to start seeing deeper debugging levels. Default is 0, so 0 is 'normal' not 'nothing'. Level 1 mostly has the effect 'log all commands regardless of their runtime'. Level 2 is where the real verbosity starts. Hardly anything is added at levels 3 and 4. Level 5 is programmer's debug level. Should only be used when running a reproducible bug in brief reproduction test. Level 1 is lots of log; Level 2 is 'for good's sake don't forget to revert to 0 before you go home tonight (or maybe even go to lunch because this will fill your disk asap' level.
3. Administrative information that can be requested through the db connection. hostInfo, connInfo, replSetGetStatus, replSetGetConf, dbStats, collStats, getIndexes(), getIndexStats. None of these are magic diagnosis tools - You need to record what the status is and analyse it (e.g. "The primary changed from A to B to C to A to B, and the timeline of restarts for A is t1, t2, for B t3 and t4, ... so that means XYZ?"), or have an eye for spotting something out of place, to use them for this purpose of problem diagnosis.
4. Explain plans. There are three levels of verbosity - queryPlan, executionStats, and allPlansExecution. If you find the information a little lacking, that is the time to remember the default is the lowest level.

There are also 2 features that are composites of the above:

5. FTDC (full-time data capture) a.k.a. "the diagnostic data metrics files". This serverStatus + replSetGetStatus + OS CPU, memory and disk stats in compressed file. Each file includes one set of the static hostInfo, buildInfo and getCmdLineOpts info as well.
6. Database profiler. The documents saved into the _system.profile_ collection profile every command that completes. It is composed of the command type, namespace, arguments, basic stats (roughly the same as in a COMMAND component log line), the explain plan (at "executionStats" verbosity), and authentication context (i.e. user and role).
and the profiler. (Grouping together because the latter is more or less a set of all explain plans captured in a circular buffer.)

Transient info:

* (0) OS process info
* (1) serverStatus
* (3) Some admin info commands (replSetGetStatus, currentOp)
* (4) Explain plans
* (6) system.profile docs (whilst the profile runs it quickly overwrites the capped collection)

File-persisted:

* (2) mongod/mongos log
* (3) Admin info commands that retrieve or report on data persisted in collections (replSetGetConf, collStats)
* (5) FTDC
* (6) system.profile docs (when halted)

Where in the code?

1. The global stats vars per stats.h. Note that these are updated at the end of a service_entry_point.cpp function. serverStatusCmd (?)
2. OpDebug::debug? Called at the end of a service_entry_point.cpp function
3. Various \*Cmd classes, accessing various in-memory datastructures (or in the case of replset and sharding conf, collection data).
4. QueryEngine code
5. The same global stats per 1, plus parts of 3.
6. Profiler class? (TODO find out. Again done at the end that service_entry_point.cpp function?)

{{% children  %}}
