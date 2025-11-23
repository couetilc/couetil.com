---
title: 'Creating QEMU images for pytest'
description: 'Creating a Virtual Machine image for test runs of my faas platform using QEMU and cloud-init.'
pubDate: 2025-11-19
draft: false
---

Today I'm creating QEMU images and configuring them using cloud-init, all to
create a virtual machine image to run the pytest suite for "faas", my educational
implementation of a function-as-a-service platform.

## Cloud-init and Ubuntu cloud image

I'm going to use Ubuntu cloud images for our virtual machines. They come with
cloud-init already installed, and skip any desktop installation steps, perfect
for the server application I'm developing.

You can download the release at https://cloud-images.ubuntu.com/. I'm using
the "noble" release, and I'm running these VMs on an M1 Mac so I'll select an
arm64 architecture.

```sh
curl -fsSL -o ubuntu.img "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-arm64.img"
```

I noticed that if you boot up the VM without cloud-init configuration files the
initialization hangs after `Started systemd-timedated.service` at `Job
systemd-networkd-wait-online.service/start running`. Not sure why, but let's
define the cloud-init files and bootstrap the VM.

There are two files to create:
- `user-data`: "cloud-config" style YAML that declaritively configures the VM.
- `meta-data`: per-instance details for configuration (instance-id, local-hostname)

Cloud-init has templating built in, where key-values from a JSON object in a
[`instance-data` file] are interpolated into a final user-data configuration
file from a Jinja-templated user-data file. I don't have a complex
configuration for this image, nor do I plan to generate variations on this
user-data configuration, so I won't template the file. 

[`instance-data` file]: https://cloudinit.readthedocs.io/en/latest/explanation/instancedata.html#instance-data 'Cloud-init instance-data'

I'll start by mentioning the `meta-data` file. This is required by cloud-init,
and is usually fetched from a cloud-provider's metadata system that manages
on-platform VMs. Since we're running this locally, I manually define
it.

```yaml
instance-id: faasvm-test-runner
local-hostname: faasvm
```

The `instance-id` is required. Cloud-init uses it to know if the virtual
machine has been initialized already. If the `instance-id` matches what is
stored on the VM's disk at `/var/lib/cloud/data/instance-id`, cloud-init
skips running per-instance modules from the user-data config (identified by
["Module Frequency" in the docs]).

Let's turn to the user-data configuration. Cloud-init supports a lot of
different [user-data formats], we're using the ["cloud-config" format]. The
file MUST start with `#cloud-config` to distinguish it to cloud-init's parser.

["Module Frequency" in the docs]: https://cloudinit.readthedocs.io/en/latest/reference/modules.html 'Cloud-init Module Reference'
[user-data formats]: https://cloudinit.readthedocs.io/en/latest/explanation/format.html#user-data-formats 'Cloud-init user-data formats'
["cloud-config" format]: https://cloudinit.readthedocs.io/en/latest/explanation/about-cloud-config.html 'About "cloud-config" user-data format'

```yaml
#cloud-config
hostname: faasvm
package_update: true
package_upgrade: false
write_files:
  - path: /usr/local/bin/setup.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -euo pipefail
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y --no-install-recommends ca-certificates curl git \
        openssh-client python3 python3-pip python3-venv rsync
      curl -LsSf https://astral.sh/uv/install.sh | sh
      install -m 0755 -o root -g root /root/.local/bin/uv /usr/local/bin/uv
runcmd:
  - /usr/local/bin/setup.sh
  - rm -f /usr/local/bin/setup.sh
power_state:
  mode: poweroff
  delay: now
users:
  - name: faas_user
    sudo: ['ALL=(root) NOPASSWD: /sbin/poweroff']
    ssh_authorized_keys:
```

The VM is simple. It's meant to run the pytest suite, that's it, so make
sure to install `uv` (the package manager for Python) and any of its
dependencies. I'll also be using `rsync` to copy the project source code and
test files into the VM, and `ssh` to send commands to the VM.

I'd like to call out a couple cloud-init modules: ["power_state"] and ["users"].

"power_state" runs after all other modules have finished and handles shutdown
and reboot. I'm initializing a virtual machine image so I can create overlay
images for pytest runs, so I want the VM to immediately exit when its done
initializing, signaling the base image is ready. So, I set it to "poweroff", "now",
which will cause QEMU's emulator process to exit without delay when cloud-init
finishes.

"users" gives me an opportunity to define permissions for the VM user that I'll
run the tests as. I haven't discussed the security policy or threat
model for this project, but I'll avoid giving the user membership in the "sudo"
group, except for the ability trigger a poweroff. Without that
[sudoers rule], running `poweroff` over SSH will provoke a password prompt for
the _password-less_ user. Finally, ssh_authorized_keys let's me specify the SSH
keypair I'll use to connect to the running instance. I generate them separately
from the VM, and `cat` the public key to the end of the `user-data` config when
I create the `seed.iso` with the cloud-init seed data created by
`cloud-localds` (touched on later). The `instance-data` file format I mentioned
earlier is a great way to interpolate public keys into your cloud-init config,
but sometimes messy is fun 😄.

["power_state"]: https://cloudinit.readthedocs.io/en/latest/reference/modules.html#power-state-change 'Module Reference: Power State Change'
["users"]: https://cloudinit.readthedocs.io/en/latest/reference/modules.html#power-state-change 'Module Reference: Users and Groups'
[sudoers rule]: https://www.sudo.ws/docs/man/sudoers.man/ 'Sudoers Manual'

## qcow2 format

The Ubuntu image is in qcow2 format. That stands for "QEMU Copy-on-Write 2",
where copy-on-write means storage is not reserved ahead of time and is only
allocated when needed. You can observe this by examing our Ubuntu image:

```shellsession
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
image only takes 591MiB on-disk. So we can set total limits on VM storage use without
paying the cost of pre-allocation on the host, which is not the case for raw disk images like .iso.

The old qcow v1 format is deprecated. qcow2 introduced a new header format and
better snapshot features. There was an extension to qcow2 some years after it
was introduced (originally called qcow3, identified with `compat: 1.1` in the
image info) that added optional header extensions, enabling compression,
encryption, improved clustering, and easier snapshots.

## qemu-img create

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
environment each time, and build a set of assertions on top of this stable
foundation to verify program correctness. One solution is to have a clean
image, our ubuntu.img release from Canonical, and simply copy it (`cp
ubuntu.img test_run.img`) before each test. Voilà, a fresh OS for each run.
However, revisiting our distinction between virtual size and disk size, we're
copying the bytes on disk so our disk usage will double from 591MiB to >1Gib.
Plus we have to pay the time cost (IOPS) to write 591MiB to disk. It's better than paying
the pre-allocation cost for raw image formats, but can we do better?

Looking closely, there is no difference between the base image and the derived
image. The name of our image format, copy-on-write, gives us a clue. What if we
didn't have to copy the whole image, and only copied the new blocks we write
to? Then our new image would only contain the different blocks against a
read-only base image. These space-saving images are often called overlay
images, and they're enabled by the qcow2 format. Let's take a look how.

## qcow2 header

Each qcow2 file has a clearly defined [header format]. For each overlay image
to only contain the differences between itself and a base image (called a
backing image by QEMU), it stores the path to the backing image in the file.

[header format]: https://www.qemu.org/docs/master/interop/qcow2.html 'QEMU qcow2 header format'

Bytes 8-15 describe the offset into the image where the backing image name is
stored, and bytes 16-19 store the size of the backing file name in bytes. The
theoretical maximum size of the filename is the maximum size for a 32-bit
integer, which corresponds a 4+ billion character filename, but QEMU
specification limits this to 1023 characters.

Let's take a look at the `qemu-img info` for an overlay image. Here's the command to make a overlay image from a backing image:

```shellsession
$ qemu-img create -f qcow2 -B qcow2 -b ubuntu.img test_run.img
$ qemu-img info test_run.img
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
```shellsession
qemu-system-aarch64: -drive if=virtio,format=qcow2,file=test.img: Could not open backing file: Could not open 'ubuntu.img': No such file or directory
```

We get an error that QEMU can't find the backing file. So, anytime we make overlay images, we need the base image to be accessible by QEMU to run them.

## cloud-localds and seed images

The overlay image is backed by the Ubuntu release image, and I'll apply the
project's specific configuration to this overlay. I can then re-use the
initialized test runner overlay image for test run instance images we can
discard or debug.

How do I initialize the overlay image? I've already describe the desired
configuration of the VM in the `user-data` section above, but I haven't applied
it to any image. In order to do that, I have to make the `user-data` and
`meta-data` files available to cloud-init at boot-up time. This strategy has
two steps. First, store the configuration files inside a separate raw image.
Second, mount that raw image when you boot the VM for the first time using
QEMU. Cloud-init should then read them, perform initialization, and shutdown
the VM, leaving it in the desired state.

The raw image containing our `user-data` and `meta-data` files is typically
called a seed image. This image contains static read-only files and is not meant to
be written to, so there is no point in using a qcow2 format.

A convenient utility [`cloud-localds`] is used to make seed images for
cloud-init. It's [distributed] and [maintained] by Canonical. The utility is
simple, mostly handling different permutations of options: what disk format for
the image, the filesystem choice, or specifying a remote metadata provider. My
need is simple and the defaults work well, so I will focus on the core
functionality.

`cloud-localds` creates a temporary directory and copies over the `user-data`
and `meta-data` files. It then uses `genisoimage` to create our raw image using
the following command:

```sh
# "$img" is the final image file, it will contain the files specified by
# the ${files[@]} array
genisoimage \
  -output "$img" \
  -volid cidata \
  -joliet -rock \
  "${files[@]}" # ("$tmp_dir/user-data", "$tmp_dir/meta-data")
```

The key option is `-volid cidata`, which sets the ISO volume label to `cidata`.
Cloud-init uses this label to find the configuration files at boot-time.
First, cloud-init enumerates all block devices and checks their labels. Raw
images (ISO9660) store the labels starting at sector 16 of the image (sectors
are fixed data segments 2048 bytes in length). `-joliet` and `-rock` are
extensions to the ISO9660 format that are not enabled by default for
compatibility reasons, even though they're both over thirty years old at this
point. They are not strictly necessary for this use-case, but nothing is lost
by enabling the flags.

(Fun fact, the `-rock` extension is called "Rock Ridge
Interchange Protocol", and is named after the town in [Mel Brook's "Blazing
Saddles"])

[Mel Brook's "Blazing Saddles"]: https://en.wikipedia.org/wiki/Blazing_Saddles 'Wikipedia: Blazing Saddles'

Now that I've explained how the `cloud-localds` command works, I'll run it to
create the seed.iso image. `cloud-localds` only runs on Linux and I'm on MacOS,
so I will run it in a docker container and mount the needed files.

```shellsession
# by default docker mounts non-existent paths as directories, so create
# an empty file to force a file mount of our final image
$ touch seed.iso 
$ docker run \
    -v ./seed.iso:/seed.iso \
    -v ./user-data:/user-data \
    -v ./meta-data:/meta-data \
    ubuntu:latest sh -c "
      set -e
      cp /user-data /user-data-copy
      echo '      - $(cat ssh-key.pub)' >> /user-data-copy
      apt-get update && apt-get install -y -qq cloud-image-utils
      cloud-localds /seed.iso /user-data-copy /meta-data
    "
# notice my quick-and-easy way of injecting the ssh public key
```

Now take a look at the volume label of the seed.iso.

```shellsession
# the label is ASCII text stored in sector 16, where a sector is 2048
# bytes in length
$ hexdump -C -s $((16*2048)) -n 256 seed.iso
00008000  01 43 44 30 30 31 01 00  4c 49 4e 55 58 20 20 20  |.CD001..LINUX   |
00008010  20 20 20 20 20 20 20 20  20 20 20 20 20 20 20 20  |                |
00008020  20 20 20 20 20 20 20 20  63 69 64 61 74 61 20 20  |        cidata  |
00008030  20 20 20 20 20 20 20 20  20 20 20 20 20 20 20 20  |                |
00008040  20 20 20 20 20 20 20 20  00 00 00 00 00 00 00 00  |        ........|
00008050  b7 00 00 00 00 00 00 b7  00 00 00 00 00 00 00 00  |................|
00008060  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00008070  00 00 00 00 00 00 00 00  01 00 00 01 01 00 00 01  |................|
00008080  00 08 08 00 0a 00 00 00  00 00 00 0a 14 00 00 00  |................|
00008090  00 00 00 00 00 00 00 16  00 00 00 00 22 00 1c 00  |............"...|
000080a0  00 00 00 00 00 1c 00 08  00 00 00 00 08 00 46 01  |..............F.|
000080b0  01 00 00 00 00 02 00 00  01 00 00 01 01 00 20 20  |..............  |
000080c0  20 20 20 20 20 20 20 20  20 20 20 20 20 20 20 20  |                |
*
00008100
```

`cidata` is present! Now cloud-init will be able to identify our device and
find the user-data and meta-data within.

[`cloud-localds`]: https://manpages.debian.org/testing/cloud-image-utils/cloud-localds.1.en.html 'Debian Manpages: cloud-localds'
[distributed]: https://documentation.ubuntu.com/public-images/public-images-how-to/use-local-cloud-init-ds/ 'Create and use a local cloud-init datasource'
[maintained]: https://github.com/canonical/cloud-utils 'GitHub: canonical/cloud-utils'

## qemu-system-aarch64

break down this command arg by arg.

dive into virtio, and netdev.

Explain trade-off using "user" networking (NAT), how is lower performance because is software-based, but is fine because we are just doing this for initializing the image. Explain the other ways to do it (bridged mode or socket/taps?) but they are more complex, especially on Mac.

Also `-nographic` is apparently a shortcut for `-display none -serial mon:stdio`? And what is difference between `-serial mon:stdio` and `-serial stdio`?

## How to debug QEMU

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

## TODO: instance-data to interpolate ssh pubkey

after i've explained and understood cloud-localds, I need to understand how to
mount instance-data.json with the pubkey at
`/run/cloud-init/instance-data.json` when cloud-init runs during first vm boot.

## threat model

What is the threat model for this VM?

## ssh-key

explain how I am injecting the ssh public key. And how we will drive the test run over ssh.
