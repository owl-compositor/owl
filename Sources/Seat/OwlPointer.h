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

@class OwlSurface;

// These come from linux/event.h

#define BTN_LEFT   0x100
#define BTN_RIGHT  0x111
#define BTN_MIDDLE 0x112


@interface OwlPointer : NSObject {
    struct wl_resource *_resource;
}

- (id) initWithResource: (struct wl_resource *) resource;

+ (OwlPointer *) pointerForClient: (struct wl_client *) client;

- (void) sendEnterSurface: (OwlSurface *) surface atPoint: (NSPoint) point;
- (void) sendMotionAtPoint: (NSPoint) point;
- (void) sendLeaveSurface: (OwlSurface *) surface;
- (void) sendScrollByX: (CGFloat) deltaX byY: (CGFloat) deltaY;
- (void) sendButton: (uint32_t) button isPressed: (BOOL) isPressed;

@end
