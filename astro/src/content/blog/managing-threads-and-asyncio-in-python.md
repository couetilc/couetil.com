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
