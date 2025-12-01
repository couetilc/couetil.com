---
title: 'Managing Threads and asyncio in Python'
description: 'Exploring how to manage threads and asyncio together in Python'
pubDate: 2025-11-28
draft: false
---

Exploring how to manage threads and asyncio together in Python, plus signal
handling for graceful shutdowns.

## types of asynchronous tasks

short-running
```py
def task_short_run():
  time.sleep(.1)
threading.Thread(target=task_short_run).start()
```

long-running
```py
def task_long_run():
  time.sleep(10)
threading.Thread(target=task_long_run).start()
```

short-looping
```py
def task_short_loop():
  while True:
    time.sleep(.1)
threading.Thread(target=task_short_loop).start()
```

long-looping
```py
def task_long_loop():
  while True:
    time.sleep(10)
threading.Thread(target=task_long_loop).start()
```

loops introduce a point to interrupt work and respond to asynchronous signals.
```py
event = threading.Event()
def task_interruptible_loop():
  while True and not event.is_set():
    time.sleep(.1)
threading.Thread(target=task_interruptible_loop).start()
event.set()
```

Interruptible loops are useful when responding to signals.
```py
flags = {'stop': threading.Event()}
def signal_handler():
  flags['stop'].set()
signal.signal(signal.SIGINT, signal_handler)
def task_interrupted_by_signal():
  while True and not flags['stop'].is_set()
    time.sleep(.1)
threading.Thread(target=task_interrupted_by_signal).start()
```

In time-sensitive tasks, timeouts can also be implemented in a cooperative
manner.
```py
event = threading.Event()
timer = threading.Timer(30, lambda: event.set())
def task_interruptible_loop():
  while True and not event.is_set():
    time.sleep(.1)
threading.Thread(target=task_interruptible_loop).start()
timer.start()
```

Why would you use `threading.Event` over a boolean flag? `threading.Event`
enables CPU-efficient `wait()`ing, where a thread defers CPU time until the
signal is triggered. Using a boolean for this method requires CPU-inefficient
busy polling of the boolean. This difference is only significant in a scenario
where a thread is waiting on an event to occur, rather than working until the
event occurs. In the examples so far, it hasn't made a difference.

Let's look at a loop that can be paused and restarted, using `wait()`.

```py
green_light = threading.Event()
def task_pausable_loop():
  while True:
    if green_light.is_set():
      time.sleep(.1)
    else:
      green_light.wait()
threading.Thread(target=task_pausable_loop).start()
green_light.set() # starts execution
time.sleep(2) # thread runs concurrently
green_light.clear() # thread is paused and waits.
```

Long-running tasks need some way to be canceled or killed. Threads are a
cooperative multi-tasking pattern in Python. You cannot interrupt or stop a
thread without it yielding control unless you use a platform-specific API. In
this scenario, there are a few approaches to exercising control over
long-running tasks.

You can run the task as a daemon thread. Daemon threads cannot be interrupted
or stopped, but if the main process exits the daemon thread will be terminated.

```py
def task_noninterruptible():
  time.sleep(10)
threading.Thread(target=foo,daemon=True).start()
sys.exit()
```

You can upgrade the task from a thread to a process. A process can be
terminated and can have its own signal handlers.

```py
def task_noninterruptible():
  time.sleep(10)
proc = multiprocesing.Process(target=task_noninterruptible)
proc.start()
proc.terminate()
```

You can't escape a law of multi-tasking: each task must use resources
responsibly, and to interrupt a task is to accept responsibility for cleaning
up the resources it was using at that moment. Using `proc.terminate()` and
`proc.kill()` will not trigger signal handlers in the child process. It's
better to use `proc.interrupt()`, and have the child handle the signal
responsibly by cleaning up before exiting, otherwise you risk corrupting shared
data structures, for example, by having the child not release a lock before
exiting, causing a deadlock.

```py
def task_interruptible_loop():
  stop = False
  signal.signal(signal.SIGINT, lambda: stop = True)
  while not stop:
    time.sleep(10)
proc = multiprocessing.Process(target=task_interruptible_loop)
proc.start()
proc.interrupt()
```

Keeping track of multiple threads, processes, and event loops.
```py
def log(*args):
  process_id = os.getpid()
  thread_id = threading.get_ident()
  loop_id = id(asyncio.get_running_loop())
  print(
    f"[pid: {process_id}]",
    f"[tid: {thread_id}]",
    f"[lid: {loop_id}]",
    *args,
  )
log("Hello, World!")
```

## how to execute a thread

- what are the different ways?

## how to execute asyncio co-routines

- the default asyncio event loop (the one for the main thread?)
- thread pool executor
- anything else?

threads will need a reference to asyncio thread pool execute to run async tasks

```py
async def fn():
  time.sleep(10)
asyncio.run(fn()) # blocks until async function is done
```

## subprocess runs

- popen vs run vs anything else?
- how subprocess runs interact with threads and async co-routines
- how to collect and combine debugging output for subprocesses

## signal handling

To handle signals in a main thread, then:
- close threads
- close threadpoolexecutor for async functions

signal handling will just be a flag, but need to check flag in main control
loops

## communicating with threads

- sempahore
- queue.Queue

## application: qemu serial monitor

I am going to have a thread, that waits on a queue for message to send over
qemu monitor's serial port. I have to start a QEMU vm subprocess, a connection

```py
```

## Tips and Tricks

Read the source code for modules from the command line:

```py
import threading, inspect
with open('./threading.py', 'w') as f:
    f.write(inspect.getsource(threading))
```

```shellsession
$ cat threading.py
"""Thread module emulating a subset of Java's threading model."""

import os as _os
import sys as _sys
import _thread
import _contextvars

from time import monotonic as _time
from _weakrefset import WeakSet
from itertools import count as _count
try:
    from _collections import deque as _deque
except ImportError:
    from collections import deque as _deque

# Note regarding PEP 8 compliant names
#  This threading model was originally inspired by Java, and inherited
# the convention of camelCase function and method names from that
# language. Those original names are not in any imminent danger of
# being deprecated (even for Py3k),so this module provides them as an
# alias for the PEP 8 compliant names
# Note that using the new PEP 8 compliant names facilitates substitution
# with the multiprocessing module, which doesn't provide the old
# Java inspired names.
...
```

But you won't be able to inspect the compiled modules.

```py
$ python
>>> import _thread, inspect
>>> print(inspect.getsource(_thread))
Traceback (most recent call last):
  File "<python-input-39>", line 1, in <module>
    print(inspect.getsource(_thread))
          ~~~~~~~~~~~~~~~~~^^^^^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.0_1/Frameworks/Python.framework/Versions/3.14/lib/python3.14/inspect.py", line 1155, in getsource
    lines, lnum = getsourcelines(object)
                  ~~~~~~~~~~~~~~^^^^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.0_1/Frameworks/Python.framework/Versions/3.14/lib/python3.14/inspect.py", line 1137, in getsourcelines
    lines, lnum = findsource(object)
                  ~~~~~~~~~~^^^^^^^^
  File "/opt/homebrew/Cellar/python@3.14/3.14.0_1/Frameworks/Python.framework/Versions/3.14/lib/python3.14/inspect.py", line 957, in findsource
    file = getsourcefile(object)
  File "/opt/homebrew/Cellar/python@3.14/3.14.0_1/Frameworks/Python.framework/Versions/3.14/lib/python3.14/inspect.py", line 861, in getsourcefile
    filename = getfile(object)
  File "/opt/homebrew/Cellar/python@3.14/3.14.0_1/Frameworks/Python.framework/Versions/3.14/lib/python3.14/inspect.py", line 822, in getfile
    raise TypeError('{!r} is a built-in module'.format(object))
TypeError: <module '_thread' (built-in)> is a built-in module
```

## API design for TaskGroup and Task


TODO: some type of TaskThread class
- needs to specify dependencies:
  - parent dependencies: thread does not execute until condition from parent is satisfied.
  - child dependencies: communicate conditions somehow
- holds reference to a cancel event used by each TaskThread
- maybe Queue for communication between parents/childs? (instead of single Event, could have queue that receives event messages, and also shuts down when parent finishes)
  - queue's can send messages: (like "ready")
  - queue's can end. See "Queue.shutdown()"
- timing tracking (start time, end time, duration)
- automatic resource cleanup after completion.
- handles interrupts well and across all tasks
- task's childrens execute concurrently.

TODO: maybe TaskGraph stores a global context dictionary, that each task receives as
an argument?

```py
class TaskGraph:
    def __init__():
        # TODO: manage stdout and stderr for all child tasks.
        # TODO: create some kind of cancel Event, or perhaps a Queue.
        pass
    def __str__(self):
        # TODO: print the TaskGraph as a mermaid diagram representation.
        pass
    def start():
        # TODO: start each start task
        # TODO: store start time of task graph
        # TODO: store end time of task graph
        pass
    def cancel():
        # TODO: will cancel all tasks in the graph
        pass
    def wait():
        # TODO: will wait for all tasks in the graph to complete
        pass
    def set_stdout():
        # TODO: will set stdout file for task group
        pass
    def set_stderr():
        # TODO: will set stderr file for task group
        pass
    def poll():
        # TODO: returns true if still executing, false otherwise (I think this is the convention? I could ask AI for suggestion for this API)
        pass
    def add_precedence():
        # TODO: adds an ordering constraint, arguments proceed from left-to-right in
        # diminishing precedence
        # TODO: raise error if port_ready and ssh_ready have not been added as tasks.
        pass
```


TODO graph stuff edge-cases:
- make sure no cycles? What would this even look like?
- make sure tasks cannot depend on itself?
- any other gotchas from literature or otherwise?
- make sure runtime arguments are valid for the graph, that is, that the dependencies
and their data requirements are satisfied. For example, if the port check node is
dependent on the qemu vm node to publish the vm port.

```py
class Task:
    def __init__(self, name: 'string'):
        self.name = name
        # TODO: create a thread.
    def target():
        raise NotImplementedError(
            'subclasses of class "Task" MUST implement method "target"')
    def start():
        self.thread = threading.Thread(target=self.target,args=(),kwargs={})

class SleepTask(Task):
    def __init__(self, sleep_for):
        self.sleep_for = sleep_for
        super().__init__(f"sleep for {sleep_for}s")
```

My test TaskGroups will be simpler:
First things first:
```py
  task = Task(name: 'sleep for 1s')
  task.run()
  task.wait()
```
Then introduce TasksGroup:
```py
  group = TaskGroup(name: 'sleeps')
  task = Task(name: 'sleep for 1s')
  group.add_start_task(task)
  group.run()
  group.wait()
```
Then introduce dependencies:
```py
  group = TaskGroup(name: 'sleeps')
  task1 = Task(name: 'sleep for 1s')
  task2 = Task(name: 'sleep for 2s')
  group.add_start_task(task)
  task2.depends_on(task1)
  group.run()
  group.wait()
```

The first TaskGroup I will implement is:
TaskGroup(name: 'run tests once')
- Task(name: 'create overlay image')
- Task(name: 'start qemu vm')
- Task(name: 'wait until port is ready')
- Task(name: 'wait until ssh is ready')
- Task(name: 'rsync files once')
- Task(name: 'run tests once')
```py
def main():
  group = TaskGroup(name: 'run tests once')
  task1 = Task(name: 'create overlay image')
  task2 = Task(name: 'start qemu vm')
  task3 = Task(name: 'wait until port is ready')
  task4 = Task(name: 'wait until ssh is ready')
  task5 = Task(name: 'rsync files once')
  task6 = Task(name: 'run tests once')
  group.add_start_task(task1)
  task2.depends_on(task1)
  task3.depends_on(task2)
  task4.depends_on(task3)
  task5.depends_on(task4)
  task6.depends_on(task5)
  group.set_stdout(sys.stdout)
  group.set_stderr(sys.stderr)
  group.run()
  group.wait()
  print(group.stdout)
  print(group.stderr)
```

I need to figure out how the data dependencies between tasks will be expressed,
not just their sequence. In fact, the sequence can be derived by the data
dependencies. That's actually a better and more modern way to express this.
Then you let the graph sort algorithm figure out the sequencing order.

So TaskGroup has to evaluate the sequencing order. And enforce the rules around
data dependencies. So no need for explicit task class I guess? Not quite, the
Tasks are user-defined, and will be re-used.

I still need a wait to manually specify some sequencing rules for tasks that
don't have a data dependency but have a sequencing dependency.

```py
overlay_image = OverlayImageTask(name = 'create overlay image', base_image = 'ubuntu.img')
vm = QemuTask(
  name = 'run test vm',
  image = OverlayImageTask.overlay_image, # data dependency expression
)
port_ready = PortReadyTask()
ssh_ready = SshReadyTask()
ssh_ready.after(port_ready)
# OR
port_ready.before(ssh_ready)
run_once = TaskGroup(name: 'run tests once')
run_once.add_task(vm) # order doesn't matter
run_once.add_task(overlay_image)
print(run_once) # prints mermaid diagram of the execution order
run_once.start()
run_once.wait()
```

```py
Ok, so order will be determined by precedence statements.
port_ready = PortReadyTask()
ssh_ready = SshReadyTask()
run_once = TaskGroup(name: 'run tests once')
run_once.add_task(port_ready)
run_once.add_task(ssh_ready)
run_once.add_precedence(port_ready, ssh_ready) 
```
Perhaps each data dependency will simply be an annotated kwarg to a Task's
__init__ function.

```py
class SleepTask:
    def __init__(self, sleep_for):
        super().__init__(f"sleep for {sleep_for}")
```
We can inspect function signatures:
```py
import inspect
sig = inspect.signature(Task.__init__)
for p in sig.parameters:
    # https://docs.python.org/3/library/inspect.html#inspect.Parameter
    print(f"Parameter: {p.name}, Kind: {p.kind}, Annotation: {p.annotation}")
class OverlayImageTask(Task):
    image: str # publishes "image" as part of TaskGroup context
class QemuTask(Task):
    # TaskGroup will read Task.__annotations__ and inject arguments by name
    def __init__(image):
        self.image = image
```

Ok, so data dependencies will be identified using class variables and annotations. Any
class variable on the Task subclass will be placed into the TaskGroup context. (that
context should be read-only? for now, yes)

```py
class OverlayImageTask(Task):
    image: str
class QemuVmTask(Task):
    ssh_port: int
class PortReadyTask(Task):
    def __init__(self, ssh_port: DataDependency(QemuVmTask.ssh_port)):
        pass
```

Yeah this is weird because I need a binding between an argument to a Task subclass, 

Hmmm maybe you could be explicit about a data dependency if the name is wrong:
```py
  TwoTask(port = DataDependency(QemuVmTask, 'ssh_port'))
```

This could perhaps be a python "protocol" instead
https://typing.python.org/en/latest/spec/protocol.html

Remember this pattern? Can I have `add_task` both ways?

```py
run_once = TaskGroup(name = 'run tests once')
run_once.add_task(OverlayImageTask(base_image = ''))
run_once.add_task(QemuVmTask, name = 'start test vm', image = 'ubuntu.img')
run_once.add_task(PortReadyTask, port = DataDependency(QemuVmTask, 'ssh_port'))
```

I think is best if like

```py
run_once = TaskGroup(name = 'run tests once')
overlay_image = OverlayImageTask(base_image = '')

qemu_vm = QemuVmTask(image = TaskGroup.Dependency(overlay_image, 'image'))
port_ready = PortReadyTask(port = TaskGroup.Dependency(vm, 'ssh_port'))
ssh_ready = PortReadyTask(port = TaskGroup.Dependency(vm, 'ssh_port'))
# calculate the correctness of the task dependency graph on every add,
# but allow adding multiple tasks at once and have dependency graph correctness
# evaluated with all tasks considered.
run_once.add_tasks(image_task, qemu_vm, port_ready, ssh_ready)
run_once.add_precedence(port_ready, ssh_ready)
```

I don't think there should be automatic injection for Tasks, I think the
argument passing should be explicit. In contrast, `pytest` is more liberal.
There's an argument for convenience, but in the case of asynchronous tasks,
coherence persuades. `pytest` fixture computations are cached, then copied
on-demand. Task orders are influenced by data dependencies, which left implicit 
allows task group re-ordering simply by changing an `__init__` parameter's
name.

Now I need to be able to list all the "self.*" instance variables, to check if
any of them are a "TaskGroup.Dependency" type. I can do that using `vars()`.

```py
class TaskGroup:
  class Dependency:
    def __init__(self, task, var):
      self.task = task
      self.var = var
  def add_precedence(self, *tasks):
    self.precedences.append(tasks)
  def add_tasks(self, *tasks):
    self.tasks.extend(tasks)
    for task in tasks:
      self.identify_data_dependency(task)
  def identify_data_dependency(self, task):
    for key, val in vars(task):
      if isinstance(val, TaskGroup.Dependency):
        if val.task in tasks:
          return True
        else
          raise Exception('data dependency relies on a task not in the task group')
```

What's next? I've identified all constraints. Now I need to construct a task
graph and check the TaskGroup constraints are preserved.

I need to make sure:
- task data dependencies have the corresponding task in the task group.
- tasks are ordered by data dependencies
- tasks are ordered by precedence rules

Likely, there will be multiple candidate graphs that match all constraints. How
do I narrow these down to a single execution plan? Is there a "minimal" graph
that maximizes concurrency? Maybe where the average path length for all paths
through the graph is the shortest?

So, I've developed the API for expressing a TaskGroup's constraints, now, to
determine the algorithms that use those constraints to develop an execution
graph.

I could use networkx to implement the graph parts. Makes my life a lot easier.
https://networkx.org/documentation/stable/reference/introduction.html
