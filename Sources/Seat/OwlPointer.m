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

#import "OwlPointer.h"
#import <wayland-server.h>
#import "OwlServer.h"
#import "OwlSurface.h"


@implementation OwlPointer

static NSMutableArray *pointers;

+ (void) initialize {
    if (pointers == nil) {
        pointers = [[NSMutableArray alloc] initWithCapacity: 1];
    }
}

+ (OwlPointer *) pointerForClient: (struct wl_client *) client {
    for (OwlPointer *pointer in pointers) {
        struct wl_resource *resource = pointer->_resource;
        if (client == wl_resource_get_client(resource)) {
            return pointer;
        }
    }
    return nil;
}

static void pointer_set_cursor(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t serial,
    struct wl_resource *surface_resource,
    int32_t hotspot_x,
    int32_t hotspot_y
) {
    // TODO
}

static const struct wl_pointer_interface pointer_impl = {
    .set_cursor = pointer_set_cursor
};

static void pointer_destroy(struct wl_resource *resource) {
    OwlPointer *self = wl_resource_get_user_data(resource);
    [pointers removeObjectIdenticalTo: self];
    [self release];
}

- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;
    [pointers addObject: self];
    wl_resource_set_implementation(
        resource,
        &pointer_impl,
        [self retain],
        pointer_destroy
    );
    return self;
}

- (struct wl_resource *) resource {
    return _resource;
}

- (void) sendEnterSurface: (OwlSurface *) surface atPoint: (NSPoint) point {
    wl_pointer_send_enter(
        _resource,
        [[OwlServer sharedServer] nextSerial],
        [surface resource],
        wl_fixed_from_double(point.x),
        wl_fixed_from_double(point.y)
    );
}

- (void) sendMotionAtPoint: (NSPoint) point {
    wl_pointer_send_motion(
        _resource,
        [OwlServer timestamp],
        wl_fixed_from_double(point.x),
        wl_fixed_from_double(point.y)
    );
}

- (void) sendLeaveSurface: (OwlSurface *) surface {
    wl_pointer_send_leave(
        _resource,
        [[OwlServer sharedServer] nextSerial],
        [surface resource]
    );
}

- (void) sendScrollByX: (CGFloat) deltaX byY: (CGFloat) deltaY {
    uint32_t timestamp = [OwlServer timestamp];

    if (deltaX != 0.0) {
        wl_pointer_send_axis(
            _resource,
            timestamp,
            WL_POINTER_AXIS_HORIZONTAL_SCROLL,
            wl_fixed_from_double(deltaX)
        );
    }

    if (deltaY != 0.0) {
        wl_pointer_send_axis(
            _resource,
            timestamp,
            WL_POINTER_AXIS_VERTICAL_SCROLL,
            wl_fixed_from_double(-deltaY)
        );
    }
}

- (void) sendButton: (uint32_t) button isPressed: (BOOL) isPressed {
    enum wl_pointer_button_state state = isPressed
        ? WL_POINTER_BUTTON_STATE_PRESSED
        : WL_POINTER_BUTTON_STATE_RELEASED;

    wl_pointer_send_button(
        _resource,
        [[OwlServer sharedServer] nextSerial],
        [OwlServer timestamp],
        button,
        state
    );
}

@end
