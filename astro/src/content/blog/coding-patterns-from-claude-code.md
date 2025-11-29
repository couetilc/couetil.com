---
title: 'Claude Coding Patterns'
description: 'Interesting patterns claude-code has used in various programming languages.'
pubDate: 2025-11-28
draft: true
---

# Claude Coding Patterns

Here are some interesting patterns I've seen Claude use in various programming
languages.

## Python

### Signal handling

```py
if __name__ = '__main__':
  stop_flag = {'stop': False}
  def signal_handler():
    stop_flag['stop'] = True
  try:
    for event in event_generator():
      if stop_flag['stop']:
        raise KeyboardInterrupt
  except KeyboardInterrupt:
    stop()
```

This minimizes time spent out-of-band in the signal handler and simply flags a
shutdown, which the main control loop has to handle. Minimizing time in the
interrupt clears the interrupt queue quickly, lessening the risk of
non-reentrant code occurring in a signal handler (possibly corrupting global
data structures).

By simply setting a flag in the handler, in-progress shutdown procedures
continue without a lengthy pause, and repeated signals are handled gracefully.

Not sure why it uses a dictionary instead of a regular boolean? It is useful
for managing multiple signal flags in the same object.
