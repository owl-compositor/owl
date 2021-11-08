# Owl

Owl is a portable [Wayland] compositor written in Objective-C, using Cocoa as
its backend. Owl primarily targets Mac OS X, but also supports a variety of
other operating systems thanks to [GNUstep].

[Wayland]: https://wayland.freedesktop.org/
[GNUstep]: http://www.gnustep.org/

Owl makes it possible to run Wayland clients inside OS X's native Quartz
graphics environment. In that sense, Owl plays a role similar to the [XQuartz]
and [XWayland] compatibility layers.

[XQuartz]: https://www.xquartz.org/
[XWayland]: https://wayland.freedesktop.org/xserver.html

# Work in progress

Owl is a work in progress. Some things work, many don't. There's a lot to
improve and figure out!

# Building

First, make sure you have Wayland installed. Please see the other repositories
in [this GitHub organization] for ports of Wayland and related software to
systems that they don't normally support.

[this GitHub organization]: https://github.com/owl-compositor

To build Owl, create a build directory, then run `configure`, then `make`:

```
$ mkdir build
$ cd build
$ ../configure
Owl root directory detected as ..
$ make
```

If the build succeeds, you should find `Owl.app` in the build directory.

# License

Owl is free software, available under the GNU General Public License version 3
or later.
