---
title: 'Creating QEMU images'
description: 'Creating a Virtual Machine image for test runs of my faas platform using QEMU and cloud-init'
pubDate: 2025-11-19
draft: false
---

Today we're creating QEMU images and configuring them using cloud-init, all to
create a virtual machine image to run the test suite for "faas", my educational
implementation of a function-as-a-service platform.

## Blog Setup todo

- Is this a good font for this page? Maybe choose a nice serif font?
- should I consider a dark mode?
- need to tweak styles, and also clean up the AI code

## Blog Content TODO

### qemu-system-aarch64

break down this command arg by arg.

dive into virtio, and netdev.

Explain trade-off using "user" networking (NAT), how is lower performance because is software-based, but is fine because we are just doing this for initializing the image. Explain the other ways to do it (bridged mode or socket/taps?) but they are more complex, especially on Mac.

Also `-nographic` is apparently a shortcut for `-display none -serial mon:stdio`? And what is difference between `-serial mon:stdio` and `-serial stdio`?

### qemu-img create

We don't "cp ubuntu.img test_runner.img", we "qemu-img create" because that makes an overlay img? Need to explain this.

### qcow2 format

There is a difference between the virtual disk, and the physical storage. It's a cool format, learn more about it.

### seed.iso vs ubuntu.img

seed.iso contains the user-data and meta-data I think.

ubuntu.img is the OS release.

### cloud-localds

Explain what it is. It's just a bash script.

Had to run it in Docker, because MacOS uses another utility for creating iso (those are CD-rom files, maybe explain?)

### How to debug QEMU

Try to get logs and block the VM from shutting itself down:
```
-D qemu-log.txt -no-shutdown
```

enable QEMU monitor:
```sh
qemu-system-aarch64 \
  -serial stdio \
  -monitor unix:qemu-monitor.sock \
  ...
nc -U qemu-monitor.sock
# run "info status" to see current VM state
```

I had been missing the UEFI, so QEMU was just hanging (TODO: explain the issue, basically, I had mounted the seed.iso but without UEFI there were no instructions to execute?)

### user-data

File has to start with "#cloud-config" or something bad happens.

Go through the user-data file and explain what is going on.

the `sudo: ['ALL=(ALL) NOPASSWD:ALL ...']` you need to trigger shutdown in non-interactive as a user (by running `sudo shutdown`, otherwise running `shutdown` without `sudo` will cause the vm to prompt for sudo password, which will fail in non-interactive mode). Would also be good to describe the syntax of this statement "ALL=(ALL)" etc it's weird.

### meta-data

I guess this names the instance and informs cloud-init whether it needs to run on boot? A little fuzzy here, what else does meta-data do?

### threat model

What is the threat model for this VM?

### ssh-key

explain how I am injecting the ssh public key. And how we will drive the test run over ssh.
