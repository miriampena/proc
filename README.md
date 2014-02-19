proc
====

Helper module for test purposes.
Allows the creation of processes that will wait on a receive loop
for commands.

Example:

1. Create a new process:
 Pid = proc:new(),

2. Perform a syncronous request on a process:
  Now = proc:exec(Pid, {os, timestamp, []}),

3. Perform a non-blocking asyncronous request on a process and then collect the result.

  Ref = proc:async_exec(Pid, {timer, sleep, [500]}).

  %% Do something else while the command is executed in Pid..

  ok = proc:async_collect(Ref, 1000)),

