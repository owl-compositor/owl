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

#import <Cocoa/Cocoa.h>
#import <wayland-server.h>
#import "OwlFeatures.h"

#ifdef OWL_PLATFORM_GNUSTEP
@interface OwlRunLoopSource : NSObject<RunLoopEvents> {
#else
@interface OwlRunLoopSource : NSObject {
#endif

    struct wl_event_loop *_event_loop;

#ifndef OWL_PLATFORM_GNUSTEP
    CFSocketRef _socket;
    CFRunLoopSourceRef _source;
#endif
}

- (id) initWithEventLoop: (struct wl_event_loop *) event_loop;

- (void) addToRunLoop;
- (void) removeFromRunLoop;

@end

