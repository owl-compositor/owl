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

#import "OwlWindow.h"
#import <Cocoa/Cocoa.h>

@implementation OwlWindow

+ (NSUInteger) styleMaskWhenDisplayingSSD: (BOOL) displaySSD {
    if (!displaySSD) {
        return NSBorderlessWindowMask;
    }
    return NSTitledWindowMask | NSClosableWindowMask |
        NSMiniaturizableWindowMask | NSResizableWindowMask;
}

- (id) initWithSize: (NSSize) size displaySSD: (BOOL) displaySSD {
    NSRect contentRect;
    contentRect.origin = NSMakePoint(500, 500);
    contentRect.size = size;

    NSUInteger styleMask = [OwlWindow styleMaskWhenDisplayingSSD: displaySSD];
    self = [super initWithContentRect: contentRect
                            styleMask: styleMask
                              backing: NSBackingStoreBuffered
                                defer: NO];

    [self setOpaque: NO];
    [self setBackgroundColor: [NSColor clearColor]];
    [self setReleasedWhenClosed: NO];
    [self setAcceptsMouseMovedEvents: YES];

    // Does not automatically happen for borderless windows.
    [NSApp addWindowsItem: self title: @"Window" filename: NO];

    return self;
}

- (void) setTitle: (NSString *) newTitle {
    newTitle = [newTitle retain];
    [_title release];
    _title = newTitle;
    [super setTitle: newTitle];
    [NSApp changeWindowsItem: self title: newTitle filename: NO];
}

- (void) dealloc {
    [_title release];
    [super dealloc];
}

- (BOOL) displaySSD {
    return ([self styleMask] & NSTitledWindowMask) != 0;
}

- (void) setDisplaySSD: (BOOL) displaySSD {
    [self setStyleMask: [OwlWindow styleMaskWhenDisplayingSSD: displaySSD]];
    if (_title != nil) {
        [self setTitle: _title];
    }
}

- (IBAction) toggleDisplaySSD: (NSMenuItem *) sender {
    BOOL displaySSD = ![self displaySSD];
    [self setDisplaySSD: displaySSD];
    [sender setState: displaySSD];
}

- (BOOL) canBecomeKeyWindow {
    return YES;
}

- (BOOL) canBecomeMainWindow {
    return YES;
}

- (void) runInteractiveMove {
    NSPoint originalMouseLocation = [NSEvent mouseLocation];
    NSPoint originalOrigin = [self frame].origin;
    NSEventMask mask = NSLeftMouseUpMask | NSMouseMovedMask | NSLeftMouseDraggedMask;

    while (YES) {
        NSEvent *event = [NSApp nextEventMatchingMask: mask
                                            untilDate: [NSDate distantFuture]
                                               inMode: NSEventTrackingRunLoopMode
                                              dequeue: YES];

        if ([event type] == NSLeftMouseUp) {
            break;
        }

        NSPoint mouseLocation = [NSEvent mouseLocation];

        NSPoint origin = originalOrigin;
        origin.x += mouseLocation.x - originalMouseLocation.x;
        origin.y += mouseLocation.y - originalMouseLocation.y;
        [self setFrameOrigin: origin];
    }
}

@end
