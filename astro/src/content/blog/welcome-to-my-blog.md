---
title: 'Creating QEMU images for test runs'
description: 'Creating a Virtual Machine image for test runs of my faas platform using QEMU and cloud-init'
pubDate: 2025-11-19
draft: false
---

Today we're creating QEMU images and configuring them using cloud-init, all to
create a virtual machine image to run the test suite for "faas", my educational
implementation of a function-as-a-service platform.

## Blog Content TODO

### cloud-init and Ubuntu cloud image

- Download ubuntu cloud image from their release page
- If I run this directly using QEMU, it hangs after "Started systemd-timedated.service" on "Job systemd-networkd-wait-online.se…ice/start running (56s / no limit)"
- Have to cloud-init to create a user, for some reason, then the systemd init finishes and I get the login prompt.

### qemu-system-aarch64

break down this command arg by arg.

dive into virtio, and netdev.

Explain trade-off using "user" networking (NAT), how is lower performance because is software-based, but is fine because we are just doing this for initializing the image. Explain the other ways to do it (bridged mode or socket/taps?) but they are more complex, especially on Mac.

Also `-nographic` is apparently a shortcut for `-display none -serial mon:stdio`? And what is difference between `-serial mon:stdio` and `-serial stdio`?

### qcow2 format

Modern QEMU images are in qcow2 format. That stands for "QEMU Copy-on-Write 2",
where copy-on-write means storage is not reserved ahead of time and is only
allocated when needed. You can observe this by examing our Ubuntu image:

```console
$ qemu-img info vm/ubuntu.img
image: vm/ubuntu.img
file format: qcow2
virtual size: 23.5 GiB (25232932864 bytes)
disk size: 591 MiB
cluster_size: 65536
Format specific information:
    compat: 1.1
    compression type: zlib
    lazy refcounts: false
    refcount bits: 16
    corrupt: false
    extended l2: false
Child node '/file':
    filename: vm/ubuntu.img
    protocol type: file
    file length: 591 MiB (620102144 bytes)
    disk size: 591 MiB
```

It has a virtual size and a disk size. The virtual size was set by running
`qemu-img resize ubuntu.img +20G` on Canonical's release distribution, but the
image only takes 591MiB. So we can set total limits on VM storage use without
paying the cost of pre-allocation on the host, which is not the case for raw disk images like .iso.

todo:
- what changed from qcow to qcow2?

### qemu-img create

We have our base Ubuntu image and we've given it permission to consume at least
20GiB of memory on the host, which will be more than enough for our test
runner. Now is a question of cleanliness, or more precisely, organization and
reproducibility. Our tests may have side-effects in cases of errors
and normal development, which means the state of the Ubuntu virtual machine
will be changed such that our tests operate within a different environment on
each run. For example, `faasd` changes OS networking settings in order to route
connections to containers. If the underlying OS settings are different between
test runs, we introduce a source non-determinism to our test suite, which may
cause false-positives, false-negatives, or flaky tests.

How can we address this? Our goal is to run our test suite in the same
environment each time, and build a set of assertions on-top of this stable
foundation to verify program correctness. One solution is to have a clean
image, our ubuntu.img release from Canonical, and simply copy it (`cp
ubuntu.img test_run.img`) before each test. Voilà, a fresh OS for each run.
However, revisiting our distinction between virtual size and disk size, we're
copying the bytes on disk so our disk usage will double from 591MiB to >1Gib.
Plus we have to pay the cost to write 591MiB to disk. It's better than paying
the pre-allocation cost for raw image formats, but can we do better?

Looking closely, there is no difference between the base image and the derived
image. The name of our image format, copy-on-write, gives us a clue. What if we
didn't have to copy the whole image, and only copied the new blocks we write
to? Then our new image would only contain the different blocks against a
read-only base image. These space-saving images are often called overlay
images, and they're enabled by the qcow2 format. Let's take a look how.

### qcow2 header

Each qcow2 file has a clearly defined [header
format](https://www.qemu.org/docs/master/interop/qcow2.html). For each overlay
image to only contain the differences between itself and a base image (called a
backing image by QEMU), it stores the path to the backing image in the file.

Bytes 8-15 describe the offset into the image where the backing image name is
stored, and bytes 16-19 store the size of the backing file name in bytes. The
theoretical maximum size of the filename is the maximum size for a 32-bit
integer, which corresponds a 4+ billion character filename, but QEMU
specification limits this to 1023 characters.

Let's take a look at the `qemu-img info` for an overlay image. Here's the command to make a overlay image from a backing image:

```sh
qemu-img create -f qcow2 -B qcow2 -b ubuntu.img test_run.img
qemu-img info test_run.img
```

```
image: test_run.img
file format: qcow2
virtual size: 23.5 GiB (25232932864 bytes)
disk size: 196 KiB
cluster_size: 65536
backing file: ubuntu.img
backing file format: qcow2
Format specific information:
    compat: 1.1
    compression type: zlib
    lazy refcounts: false
    refcount bits: 16
    corrupt: false
    extended l2: false
Child node '/file':
    filename: test.img
    protocol type: file
    file length: 192 KiB (197120 bytes)
    disk size: 196 KiB
```

The overlay has two extra key values relative to our base ubuntu image:
"backing file", and "backing file format". Also, even though this image is
practically a copy, the disk size is dramatically lower than the base image:
196KiB vs. 591MiB, or more than 3000x smaller than a naive copy would be (note the virtual size is the same).

This comes with a tradeoff though, the overlay image needs a stable reference
to the base image. If we rename our base image

```sh
mv ubuntu.img foo.img
```

And try to run our overlay image

```sh
qemu-system-aarch64 -bios "$(brew --prefix qemu)/share/qemu/edk2-aarch64-code.fd" -accel hvf -cpu host -machine virt,highmem=on -smp 4 -m 4096 -display none -serial stdio -drive if=virtio,format=qcow2,file=test.img -nic user,model=virtio-net-pci
```
```console
qemu-system-aarch64: -drive if=virtio,format=qcow2,file=test.img: Could not open backing file: Could not open 'test_runner.img': No such file or directory
```

We get an error that QEMU can't find the backing file. So, anytime we make overlay images, we need the base image to be accessible by QEMU to run them.

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
