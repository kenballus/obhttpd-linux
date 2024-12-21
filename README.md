# obhttpd-linux

This is a port of OpenBSD's httpd to GNU/Linux.

It's been tested on aarch64 Fedora 41 and amd64 Debian 13 (testing), and basic functionality is good.

## Building

This project's Debian requirements are

- bmake
- byacc
- libbsd-dev
- libtls-dev
- libssl-dev
- groff
- libevent-dev

For other distributions, it's similar.

To build, run
```
./patch.sh && bmake
```

This will

1. fetch the OpenBSD src repo (which is big!),
2. copy the necessary files from it,
3. patch those files to work on Linux,
4. and build the httpd.

## Missing Functionality

I had to patch out two features from upstream:

1. The CLI flags having to do with TCP SACK are disabled, because they rely on `setsockopt` flags that aren't present on Linux.
2. All HTTP authentication attempts are denied, because they would rely on `crypt_checkpass`, which isn't available on Linux.
