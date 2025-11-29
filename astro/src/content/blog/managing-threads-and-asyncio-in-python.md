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
def task():
  time.sleep(.1)
threading.Thread(target=task).start()
```
long-running
```py
def task():
  time.sleep(10)
threading.Thread(target=task).start()
```
short-looping
```py
def task():
  while True:
    time.sleep(.1)
threading.Thread(target=task).start()
```
long-looping
```py
def task():
  while True:
    time.sleep(10)
threading.Thread(target=task).start()
```

loops introduce a point to interrupt work and respond to asynchronous signals.

long-running tasks need some way to be canceled or killed.
- based on timeout
- based on interrupt/kill event during signal handling

How does each loop look when:
- process should exit in <1s when ctrl-c is received.
- process should exit if execution time >20s

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
