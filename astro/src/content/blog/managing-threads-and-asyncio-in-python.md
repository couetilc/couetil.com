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

## Real-world Application: Running Tasks Concurrently

I had been motivated to explore concurrency in Python when trying to integrate
an async-based library into a thread-based system I had been building. The
question I asked then was, how do threads, processes, and asyncio work
together? The practical application of these ideas came when building a test
suite runner for a project of mine.

I had a set of steps to perform to prepare a virtual machine for a test run.
Some steps required data from other steps, other steps required starting other
executables and waiting for them to finish, and while coding them up I found
myself wanted a delcarative syntax for these task definitions along with
standardized metrics and logging, while retaining the flexibility of Python
syntax for defining _what_ the steps should do.

I started to develop two abstractions, a *Task* and a *TaskGroup*. A Task is a
single Python function to execute, while a TaskGroup is a collection of Tasks
which orchestrates their execution and enables data sharing and standardized
monitoring.

Tasks have a simple definition:

```py
task = Task() # a Task that performs no operations
```

and can be assigned a function to run:

```py
def hello(subject = 'world'):
  print(f"hello {subject}"!)
greet = Task(target=hello)
```

Each task is *threaded*. The target function will be executed in its own
thread. This allows the main thread to continue executing other tasks until a
particular task is `wait()`ed. Let's take a look at that.

```py
greet.start()
print(
  "this is the main thread, the task is running asynchronously, this message may "
  "be printed before or after the greeting")
greet.wait()
print("now this message is guaranteed to come after the greeting")
```

The `.wait()` method blocks the main thread until the task thread has
completed. So, we have simple concurrency, where the main thread can start
subthreads and have a mechanism to coordinate with them.

I wanted to write unit tests for these features, so I had to come up with a
method of tracking Python threads from pytest. I developed an assertion helper
that would track threads over a window of execution. The trouble is, if you
don't clearly define when to start and stop tracking threads, you can run into
race conditions. Let's take a naive approach:

```py
def test_races():
    task = Task()
    task.start() # short-running task
    assert_tasks(nthread = 1) # may or may not run before the task finishes
    task.wait()
```

I want to assert there is a subthread running, but I can't be sure the
statement will run before or after the thread has finished executing.

So, I define an execution window, and check the number of spawned threads at
the end, rather than trying to catch a thread during its execution.

```py
def test_doesnt_race():
    task = Task()
    with assert_tasks(nthread = 1):
        task.start() # short-running task
        task.wait()
```

Now I can clearly state my expectations for the contained statements, track
execution state over the context, and assert on that state at the appropriate
endpoint.

Let's take a look at the implementation of that test helper as its heavily used
in the test suite and provides some insight into Python's threading module.

````py
@contextlib.contextmanager
def assert_tasks(*, nthread = None, order = None):
    """
    Tracks threads over the execution window of a "with" block.

    USAGE:

    Pass "nthread" to assert on the number of expected threads:

    ```py
    def test_property():
        task = Task()
        with assert_tasks(nthread = 1):
            task.start()
            task.wait()
    ```

    Pass "order" to assert on the task execution order

    ```py
    def test_property():
        group = TaskGroup()
        task1 = Task()
        task2 = Task()
        group.add_precedence(task1, task2)
        with assert_tasks(order = [task1, task2]):
            group.start()
            group.wait()
    ```
    """
    class ThreadTracker:
        def __init__(self):
            self.lock = threading.Lock()
            self.threads = set()
            self.tasks = collections.defaultdict(list)
        def track(self, thread):
            if thread.name == 'TaskGroup.control_loop':
                return
            with self.lock:
                if thread.id not in self.threads:
                    self.threads.add(thread.id)
                    self.tasks[thread.task_id].append(thread.id)
        @property
        def nthread(self):
            return len(self.threads)
        def assert_nthread(self, n):
            assert self.nthread == n, (
                f"Started {tracker.nthread} non-main thread(s), expected {nthread}")
        def assert_order(self, before: Task, after: Task):
            assert min(self.tasks[before.id]) < min(self.tasks[after.id]), (
                'task "{1}" came before "{0}", expected "{0}" to come before "{1}"'.format(before, after))

    tracker = ThreadTracker()

    def trace_function(frame, event, arg):
        tracker.track(threading.current_thread())

    threading.settrace(trace_function)
    yield tracker
    threading.settrace(None)

    if nthread != None:
        tracker.assert_nthread(nthread)

    if order != None:
        if len(order) < 2:
            raise Exception("Invalid order argument to assert_tasks. order must contain two or more tasks.")
        for i in range(len(order) - 1):
            tracker.assert_order(order[i], order[i + 1])
````

The key idea is to use the `threading` module's `settrace` method to set a
trace function for each function call in a thread. When the trace function is
triggered from within a thread, we check the thread's unique id (created by the
Thread class) and store it along with the task id in a data structure. We can
use this information to derive how many threads were executed, what tasks, and
in what order.

To accomplish this, the Task class had to subclass Python's Thread class to
assign the unique id when the task is defined.

```py
class Task:
    # ...
    class Thread(threading.Thread):
        count = itertools.count(0) # not sure what maximum value is, internet suggests infinite
        lock = threading.Lock()
        def __init__(self, task: Task, *args, **kwargs):
            super().__init__(*args, **kwargs)
            with Task.Thread.lock:
                self.id = next(Task.Thread.count)
            self.name = f"TaskThread-{self.id}"
            self.task_id = task.id
    # ...
```

We have a basic Task at the moment, but at this moment I wanted to define what
the API for defining a TaskGroup would look like. The API would inform the
implementation, and it wasn't clear at first what the ideal declarative syntax
was from my perspective. I evaluated several options, both top-down
(TaskGroup-oriented) and bottom-up (Task-oriented) approaches, and settled on a
mix of the two, moving the responsibility of declaring an execution constraint
to the salient object.

At first, dependencies were defined by tasks, and a TaskGroup would be
concerned with orchestrating Task execution based on a starting task.

```py
group = TaskGroup()
task1 = Task()
task2 = Task()
group.add_start_task(task1)
task2.depends_on(task1)
group.run()
group.wait()
```

There was a suggestion to allow tasks to specify "before" or "after"
dependencies, and the TaskGroup would infer the order based on a set of tasks.

```py
group = TaskGroup()
task1 = Task()
task2 = Task()
task2.after(task1)
# OR
task1.before(task2)
group.add_task(task1)
group.add_task(task2)
group.run()
group.wait()
```

The issue here is that ordering is not a concern of the Task, but of the
TaskGroup, so I settled on a precedence declaration to set the order, but not
necessarily the precise sequence.

```py
group = TaskGroup()
task1 = Task()
task2 = Task()
group.add_tasks(task1, task2)
group.add_precedence(task1, task2) # declaration of ordering
group.run()
group.wait()
```

With simple ordering specified, I wanted to declare data dependencies between
Tasks in a natural manner. Python is delightfully introspectible, and I hoped
to piggy-back on the same feature that powers type hints, that is,
"annotations". Perhaps I could annotate the arguments to a Task and the
TaskGroup could infer data dependencies from those annotations.

We can inspect Python function signatures in the following manner, and could
declare the "exported" data values, i.e. available interdependencies, on the
subclass of a Task

```py
class OverlayImageTask(Task):
  # publish "image" as a possible data dependency
  image: str
# QemuTask consumes the image parameter from OverlayImageTask
class QemuTask(Task):
  def __init__(image):
    self.image = image
# TaskGroup would inspect function signatures in the following manner.
import inspect
for p in inspect.signature(QemuTask.__init__).parameters:
  print(p.name, p.kind, p.annotation)
```

This gets messy though, as there is no explicit connection between the
published value and consumed parameter except for the name. Annotations are
nice, and I may return to them in the future, but instead I decided to couple
Task and TaskGroup through a "TaskGroup.Dependency" class, which will act as
the explicit data dependency between Tasks.

```py
run_once = TaskGroup(name = 'run tests once')
overlay_image = OverlayImageTask(base_image = 'foo.img')
qemu_vm = QemuVmTask(image = TaskGroup.Dependency(overlay_image, 'image'))
ssh_ready = PortReadyTask(port = TaskGroup.Dependency(qemu_vm, 'ssh_port'))
run_once.add_tasks(overlay_image, qemu_vm, ssh_ready)
```

Now we have methods for defining the two execution constraints, order and data
dependency.

Let's look at the implementation of the constraints. I'm using networkx to
manage our TaskGraph as a directed acyclic graph (DAG). A DAG let's me be sure
there are no circular dependencies between Task operations which would
interfere with sequencing the Task operations in a natural order, without
putting a more complicated default value and layered result system on top.

Ordering constraints are specified using the "add_precedence" method, and data
dependencies are specified with the "add_tasks" method. Each method will roll
back any data structure updates if the graph constraints are not preserved.

```py
class TaskGroup:
    def __init__(self, name = None, *args):
        self.tasks = set(args)
        self.graph = networkx.DiGraph()
    def add_precedence(self, *tasks):
        if len(tasks) < 2:
            raise TaskGroup.Exception(
                'TaskGroup.add_precedence called with fewer than two arguments. '
                'Precedence constraints must be expressed in terms of 2 or more tasks')
        # self.add_tasks(*tasks) # TODO: tasks can be added through add_precedence
        for i in range(len(tasks) - 1):
            self.graph.add_edge(tasks[i], tasks[i + 1])
        if exc := self.verify_constraints():
            for i in range(len(tasks) - 1):
                self.graph.remove_edge(tasks[i], tasks[i + 1])
            raise exc
    def add_tasks(self, *args):
        self.tasks.update(args)
        self.graph.add_nodes_from(args)
        edges = list()
        def check_dependency(arg):
            if isinstance(arg, TaskGroup.Dependency):
                if arg.task not in self.tasks:
                    raise TaskGroup.Exception(
                        'Detected TaskGroup Dependency wrapping unrecognized task. '
                        'TaskGroup Dependencies must be added to the TaskGroup. '
                    )
                edges.append((arg.task, task))
        try:
            for task in args:
                for arg in task.args:
                    check_dependency(arg)
                for key in task.kwargs:
                    check_dependency(task.kwargs[key])
            for edge in edges:
                self.graph.add_edge(*edge)
            if exc := self.verify_constraints():
                raise exc
        except TaskGroup.Exception as e:
            for edge in edges:
                self.graph.remove_edge(*edge)
            self.tasks.difference_update(args)
            self.graph.remove_nodes_from(args)
            raise e
    def verify_constraints(self) -> None | TaskGroup.Exception:
        if not networkx.is_directed_acyclic_graph(self.graph):
            return TaskGroup.Exception(
                'Cycle detected. '
                'Ordering constraints must not introduce cycles. '
                'A TaskGroup must be a directed acyclic graph.')
```

Constraints are expressed as edges in the graph. Resolving ordering constraints
is easy, I just need to make sure tasks are executed in order. Resolving a data
dependency is trickier, I need some way to pass data between Tasks and threads.

I have a custom Thread class, which gives me control over how Task threads are
executed and their result handled. I can use that to implement success and
exception hooks that publish a Task's result to an event queue.

```py
class Task:
    # ...
    class Thread(threading.Thread):
        count = itertools.count(0)
        lock = threading.Lock()
        def __init__(self, task: Task, on_success, on_exception, *args, **kwargs):
            super().__init__(*args, **kwargs)
            with Task.Thread.lock:
                self.id = next(Task.Thread.count)
            self.name = f"TaskThread-{self.id}"
            self.task_id = task.id
            self.result = None
            self.on_success = on_success
            self.on_exception = on_exception
        def run(self):
            """
            Override threading.Thread.run to store return value in self.result.
            (see: inspect.getsource(threading.Thread))
            """
            try:
                if self._target is not None:
                    self.result = self._target(*self._args, **self._kwargs)
                    self.on_success((self.task_id, self.result))
            except Exception as e:
                self.on_exception((self.task_id, e))
            finally:
                del self._target, self._args, self._kwargs

    def __init__(self, target = None, name = None, args = None, kwargs = None):
        # ...
        self.hooks = {'on_success': set(), 'on_exception': set()}
    def start(self, *args, **kwargs):
        self.thread = Task.Thread(
            task=self,
            target=self.target,
            on_success = lambda *a, **kw: self.trigger_hook('on_success', *a, **kw),
            on_exception = lambda *a, **kw: self.trigger_hook('on_exception', *a, **kw),
            args=args,
            kwargs=kwargs,
        )
        self.thread.start()
    def add_hook(self, hook, fn):
        if hook not in self.hooks:
            raise Task.Exception(f'Request to add unknown hook "{hook}" ')
        self.hooks[hook].add(fn)
    def remove_hook(self, hook, fn):
        if hook not in self.hooks:
            raise Task.Exception(f'Request to remove unknown hook "{hook}" ')
        self.hooks[hook].discard(fn)
    def trigger_hook(self, hook, *args, **kwargs):
        for fn in self.hooks[hook]:
            fn(*args, **kwargs)
```

Now that we have a constraints specified and a way to share data between tasks,
let's take a look at task execution.

My first implementation was serial in nature, each task would wait for the previous to complete, regardless of constraint.

```py
class TaskGroup:
    # ...
    class ControlLoop:
        # ...
        def loop_serial(self):
            """
            This control loop is serial. It executes tasks one by one, and must wait for the
            current task to finish before starting the next.
            """
            for task in networkx.topological_sort(self.graph):
                if self.flag_cancel.is_set():
                    break
                self.task_register_hooks(task)
                args, kwargs = self.task_get_args(task)
                task.start(*args, **kwargs)
                task_id, result = self.eventq.get()
                with self.lock_result:
                    if isinstance(result, Exception):
                        self.errors.append(result)
                    else:
                        self.results[task_id] = result
            for task in self.tasks:
                task.wait()
                self.task_unregister_hooks(task)
    def start(self):
        """
        This function starts all nodes in the graph.

        Not all nodes are guaranteed to have finished executing when .start() returns.
        Must call .wait() for that. Because if the last nodes were started (they have no
        successors) this function returns without waiting.
        """
        if len(self.graph.nodes) == 0:
            raise TaskGroup.Exception(
                'Called start() on an empty TaskGroup. '
                'You cannot start an empty TaskGroup.')

        # want to isolate state related to a single TaskGroup.start(). Allows tasks in
        # group to be modified while a TaskGroup is running concurrently.
        self.control_loop = TaskGroup.ControlLoop(
            tasks = self.tasks.copy(),
            graph = self.graph.copy(),
        )
        self.control_loop.start()

```

Note the "topological_sort" method on the DAG is what enforces execution order.

Note the ControlLoop class. It's set up to isolate data for a single TaskGroup
run. The control loop also runs in its own thread, so it doesn't block the main
thread from executing while it sequences and handles the Task threads. The
ControlLoop thread will stop when all the Task threads in the group have
stopped, i.e. the TaskGroup run has completed.

The test for data dependencies clearly shows the API, let's take a look

```py
def test_task_group_data_dependencies_share_data_args():
    group = TaskGroup()
    task1 = Task(name = '1', target=lambda: 'foo')
    def assert_foo(data):
        assert data == 'foo'
    task2 = Task(name = '2', target=assert_foo)
    task2.set_args(TaskGroup.Dependency(task1))
    group.add_tasks(task2, task1)
    with assert_tasks(nthread = 2, order = [task1, task2]):
        group.start()
        group.wait()
```

The issue with serial execution is that nodes with no dependencies will not be
started concurrently, which theoretically slows execution. What would a
concurrent model of execution loop like?

```py
class TaskGroup:
    # ...
    class ControlLoop:
        # ...
        def loop_concurrent(self):
            """
            This control loop is concurrent. It starts independent tasks immediately
            without waiting and then starts dependent tasks when their predecessor has
            finished.
            """
            waiting = next(networkx.topological_generations(self.graph))
            while not self.flag_cancel.is_set():
                # make sure to copy the set, otherwise items are skipped.
                for task in waiting.copy():
                    if self.task_is_ready(task):
                        self.task_register_hooks(task)
                        args, kwargs = self.task_get_args(task)
                        task.start(*args, **kwargs)
                        waiting.remove(task)
                        waiting += self.graph.successors(task)
                if len(waiting) > 0:
                    task_id, result = self.eventq.get() # blocks and defers CPU time
                    with self.lock_result:
                        if isinstance(result, Exception):
                            self.errors.append(result)
                        else:
                            self.results[task_id] = result
                    self.eventq.task_done()
                else:
                    # exit early, no more data dependencies to wait and resolve
                    break
            for task in self.tasks:
                task.wait()
                self.task_unregister_hooks(task)
```

It uses the concept of a "waiting" Task set to manage in-flight and pending
tasks. Note the "topological_generations" method is used to enforce ordering.
It differs from the topological sort in that it returns a set of nodes in the
same generation, or the nodes with the same depth in the graph. Nodes in the
same generation don't have dependencies with each other, and can be executed
concurrently when their parent nodes (if any) have finished executing. When a
task is started, its successor nodes get added to the waiting set, and the
control loop will periodically check if the parent node has finished executing
before starting them. The control loop defers CPU time until a Task has
finished and published a result event to the event queue. This avoids
inefficient busy polling.

The test for concurrent execution is straightforward:

```py
def test_task_group_start_concurrently():
    """
    To test threads are started concurrently, we start two sleeping threads and check
    the started thread count before the sleeps elapse. If the tasks are executed
    concurrently, thread count should be greater than one. If the tasks are executed
    serially, thread count should only be one, the second task isn't started until the
    first task has finished, which will be after our test thread checks the thread
    count.
    """
    group = TaskGroup()
    task1 = Task(name = '1', target = lambda: time.sleep(.2))
    task2 = Task(name = '2', target = lambda: time.sleep(.2))
    group.add_tasks(task1, task2)
    with assert_tasks(nthread = 2) as tracker:
        group.start()
        # give time for threads to start
        time.sleep(.1)
        # at this point threads are started but sleeping.
        assert tracker.nthread == 2
        # assertion is not true when serial, not enough time elapsed for a task to
        # finish, implying the next one was not started.
        group.wait()
```
