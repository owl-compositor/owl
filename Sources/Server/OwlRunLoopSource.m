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

#import "OwlRunLoopSource.h"
#import "OwlServer.h"
#import "OwlFeatures.h"
#import <Cocoa/Cocoa.h>

@implementation OwlRunLoopSource

#ifndef OWL_PLATFORM_GNUSTEP
static void socketCallback(
    CFSocketRef socket,
    CFSocketCallBackType type,
    CFDataRef address,
    const void *data,
    void *info
) {
    OwlRunLoopSource *self = info;
#else
- (void) receivedEvent: (void *) data
                  type: (RunLoopEventType) type
                 extra: (void *) extra
               forMode: (NSString *) mode
{
#endif

    @try {
        wl_event_loop_dispatch(self->_event_loop, 0);
    } @catch (NSException *ex) {
        NSLog(@"Internal error during wl_event_loop_dispatch(): %@", ex);
    }

    [[OwlServer sharedServer] flushClients];
}

- (id) initWithEventLoop: (struct wl_event_loop *) event_loop {
    _event_loop = event_loop;

#ifndef OWL_PLATFORM_GNUSTEP
    int fd = wl_event_loop_get_fd(_event_loop);

    CFSocketContext context = {
        .version = 0,
        .info = self,
        .retain = NULL,
        .release = NULL,
        .copyDescription = NULL
    };

    _socket = CFSocketCreateWithNative(
        NULL,
        fd,
        kCFSocketReadCallBack,
        socketCallback,
        &context
    );
    _source = CFSocketCreateRunLoopSource(NULL, _socket, 0);
#endif

    return self;
}

- (void) dealloc {
#ifndef OWL_PLATFORM_GNUSTEP
    CFRelease(_source);
    CFRelease(_socket);
#endif
    [super dealloc];
}

- (void) addToRunLoop {
#ifndef OWL_PLATFORM_GNUSTEP
    CFRunLoopAddSource(CFRunLoopGetCurrent(), _source, kCFRunLoopDefaultMode);
#else
    int fd = wl_event_loop_get_fd(_event_loop);

    [[NSRunLoop currentRunLoop] addEvent: (void *) fd
                                    type: ET_RDESC
                                 watcher: self
                                 forMode: NSDefaultRunLoopMode];
#endif
}

- (void) removeFromRunLoop {
#ifndef OWL_PLATFORM_GNUSTEP
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _source, kCFRunLoopDefaultMode);
#else
    int fd = wl_event_loop_get_fd(_event_loop);

    [[NSRunLoop currentRunLoop] removeEvent: (void *) fd
                                       type: ET_RDESC
                                    forMode: NSDefaultRunLoopMode
                                        all: YES];
#endif
}

@end
