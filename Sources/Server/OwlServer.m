/* This file is part of Owl.
 *
 * Copyright © 2019-2021 Sergey Bugaev <bugaevc@gmail.com>
 *
 * Owl is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License,
 * or (at your option) any later version.
 *
 * Owl is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Owl.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "OwlServer.h"
#import "OwlRunLoopSource.h"
#import "OwlFeatures.h"
#import "OwlCompositor.h"
#import "OwlSubcompositor.h"
#import "OwlWlShell.h"
#import "OwlZxdgShellV6.h"
#import "OwlXdgWmBase.h"
#import "OwlSeat.h"
#import "OwlWlDataDeviceManager.h"
#import "OwlZwlrDataControlManagerV1.h"
#import "OwlPasteboardDataDevice.h"
#import "OwlSelection.h"

#ifdef OWL_PLATFORM_APPLE
    #import "OwlZowlMachIpcV1.h"
    #import "OwlZowlIOSurfaceManagerV1.h"
#endif

@implementation OwlServer

- (BOOL) setUpSocket {
    // Set up a socket on the filesystem that the clients can connect
    // to when they want to talk to us. Normally, it's placed at a path
    // like /run/user/1000/wayland-0. Here, /run/user/1000 is the value
    // of the XDG_RUNTIME_DIR environment variable, and wayland-0 is the
    // WAYLAND_DISPLAY. libwayland-client tries to automatically pick
    // an unused display number, but in order for this to work at all,
    // XDG_RUNTIME_DIR has to be set, and the directory has to exist
    // at that path, and we shouldbe able to write there.
    const char *socket_name = wl_display_add_socket_auto(_display);

    if (socket_name == NULL) {
        // So if that failed, let's display an error message to the user.
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText: @"Failed to grab a socket"];

        // See if XDG_RUNTIME_DIR is even set.
        NSDictionary *environment = [[NSProcessInfo processInfo] environment];
        NSString *runtimeDir = [environment objectForKey: @"XDG_RUNTIME_DIR"];
        if (runtimeDir == nil) {
            [alert setInformativeText: @"XDG_RUNTIME_DIR is unset"];
        } else if (![[NSFileManager defaultManager] fileExistsAtPath: runtimeDir]) {
            NSString *s = [NSString stringWithFormat: @"XDG_RUNTIME_DIR (%@) does not exist", runtimeDir];
            [alert setInformativeText: s];
        }
        [alert runModal];

        return NO;
    }

    NSString *socketName = [NSString stringWithUTF8String: socket_name];
    NSLog(@"Running compositor on Wayland display %@", socketName);
    return YES;
}

- (id) init {
    // When a Unix process tries to write into a broken pipe (one that
    // has no readers attached to it anymore), the kernel sends it the
    // SIGPIPE signal, whose default action is to kill the process. This
    // makes some sense for command-line programs whose stdout is piped
    // to another command that has already concluded it doesn't need to
    // read any more of it, such as when piping a command into head(1),
    // but not for a Wayland compositor trying to talk to a disconnected
    // client. So ask the kernel to make this signal harmless for us.
    signal(SIGPIPE, SIG_IGN);

    // Create the Wayland display. This does not yet set up a socket on
    // the filesystem or start serving clients.
    _display = wl_display_create();

    // Wayland uses its own implementation of event loop (also known as
    // run loop and main loop). Of course, only one event loop can actually
    // serve as the *main* loop, but it's possible to integrate the two
    // loops so that one of them (the Cocoa run loop) watches for the events
    // the other one (the Wayland event loop) is interested in, and calls
    // it back when these events happen. In Owl, this integration is
    // implemented in the OwlRunLoopSource class. Set up that integration now.
    struct wl_event_loop *event_loop = wl_display_get_event_loop(_display);
    _runLoopSource = [[OwlRunLoopSource alloc] initWithEventLoop: event_loop];
    [_runLoopSource addToRunLoop];

    // Now, try to set up a socket on the filesystem. This method will
    // display error messages itself, so we just need to check its return
    // code.
    if (![self setUpSocket]) {
        // We could not set up the socket. Give up and let the caller know.
        [self release];
        return nil;
    }

#ifdef OWL_PLATFORM_APPLE
    // On Darwin, check in with the bootstrap service.
    [OwlZowlMachIpcV1 bootstrapCheckInWithName: @"io.github.bugaevc.Owl"];
#endif

    // Enable the built-in implementation of wl_shm. Among other things,
    // this does add the wl_shm global to the display.
    wl_display_init_shm(_display);

    // Add various globals to the display.
    [OwlCompositor addGlobalToDisplay: _display];
    [OwlSubcompositor addGlobalToDisplay: _display];
    [OwlWlShell addGlobalToDisplay: _display];
    [OwlZxdgShellV6 addGlobalToDisplay: _display];
    [OwlXdgWmBase addGlobalToDisplay: _display];
    [OwlWlDataDeviceManager addGlobalToDisplay: _display];
    [OwlSeat addGlobalToDisplay: _display];

    [OwlZwlrDataControlManagerV1 addGlobalToDisplay: _display];

#ifdef OWL_PLATFORM_APPLE
    // On Darwin, add some Mach-related globals.
    [OwlZowlMachIpcV1 addGlobalToDisplay: _display];
    [OwlZowlIOSurfaceManagerV1 addGlobalToDisplay: _display];
#endif

    // Create the pasteboard data device, telling it to connect
    // the general Cocoa pasteboard to the Wayland clipboard.
    [[OwlPasteboardDataDevice alloc] initWithPasteboard: [NSPasteboard generalPasteboard]
                                              selection: [OwlSelection clipboard]];

#ifdef OWL_PLATFORM_GNUSTEP
    // On GNUstep, create another pasteboard data device for the
    // primary selection. Here, "Selection" is the pasteboard name
    // that GNUstep handles specifically, mapping it to XA_PRIMARY.
    // See https://github.com/gnustep/libs-back/blob/master/Tools/xpbs.m
    // for more details.
    [[OwlPasteboardDataDevice alloc] initWithPasteboard: [NSPasteboard pasteboardWithName: @"Selection"]
                                              selection: [OwlSelection primary]];
#endif

    return self;
}

- (void) dealloc {
    [_runLoopSource removeFromRunLoop];
    [_runLoopSource release];
    wl_display_destroy(_display);
    [super dealloc];
}

- (uint32_t) nextSerial {
    return wl_display_next_serial(_display);
}

// Get the current timestamp suitable for using in Wayland events.
//
// The returned timestamp is in milliseconds. Wayland leaves
// the base unspecified (i.e. implementation-defined), so a
// compositor can pick whatever base is most convenient for
// its implementation. For us, it's the reference date used
// by -timeIntervalSinceReferenceDate, i.e. 1 January 2001.
+ (uint32_t) timestamp {
    NSTimeInterval ti = [[NSDate date] timeIntervalSinceReferenceDate];
    return ti * 1000;
}

// Explicitly flush our clients.
//
// Normally, this is done by OwlRunLoopSource after dispatching
// the events, so most request handlers don't have to call this
// explictly. This does have to be called explicitly upon sending
// Wayland events when handling a Cocoa event such as -mouseDown:.
//
// Please note that calling this may lead to crashes if a client
// connection is found to be broken, and its resources get destroyed
// on the spot; normally the code around the Cocoa event being
// handled doesn't expect the object to be destroyed immediately.
// To prevent this, call -flushClientsLater instead.
- (void) flushClients {
    wl_display_flush_clients(_display);
}

// Schedule to flush our clients sometime soon.
//
// This arranges to call -flushClients on the next iteration of the
// Cocoa run loop. See the comment on -flushClients for why you would
// want to use this method instead of that one.
- (void) flushClientsLater {
    NSArray *modes = [NSArray arrayWithObject: NSDefaultRunLoopMode];
    NSRunLoop *loop = [NSRunLoop currentRunLoop];
    // The order argument below represents which order these delayed
    // selectors should be executed in; lower values go first. We do
    // not care, so pass some large number.
    [loop performSelector: @selector(flushClients)
                   target: self
                 argument: nil
                    order: 1000
                    modes: modes];
}

// Get the singleton serever instance.
//
// There's normally only one OwlServer object in the program, and it
// can be accessed using this method. This method will automatically
// create and initialize the server the first time it gets called.
+ (OwlServer *) sharedServer {
    static OwlServer *shared;
    if (shared == nil) {
        shared = [OwlServer new];
    }
    return shared;
}

@end
