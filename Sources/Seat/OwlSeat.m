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

#import "OwlSeat.h"
#import "OwlPointer.h"
#import "OwlKeyboard.h"
#import <wayland-server.h>

@implementation OwlSeat

static void seat_get_pointer(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t id
) {
    uint32_t version = wl_resource_get_version(resource);
    struct wl_resource *pointer_resource = wl_resource_create(
        client,
        &wl_pointer_interface,
        version,
        id
    );
    [[[OwlPointer alloc] initWithResource: pointer_resource] release];
}

static void seat_get_keyboard(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t id
) {
    uint32_t version = wl_resource_get_version(resource);
    struct wl_resource *keyboard_resource = wl_resource_create(
        client,
        &wl_keyboard_interface,
        version,
        id
    );
    [[[OwlKeyboard alloc] initWithResource: keyboard_resource] release];
}

static const struct wl_seat_interface seat_impl = {
    .get_pointer = seat_get_pointer,
    .get_keyboard = seat_get_keyboard
};

static void seat_destroy(struct wl_resource *resource) {
    OwlSeat *self = wl_resource_get_user_data(resource);
    [self release];
}

- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;

    wl_resource_set_implementation(
        resource,
        &seat_impl,
        [self retain],
        seat_destroy
    );

    wl_seat_send_capabilities(
        resource,
        WL_SEAT_CAPABILITY_POINTER | WL_SEAT_CAPABILITY_KEYBOARD
    );

    if (wl_resource_get_version(resource) >= 2) {
        wl_seat_send_name(resource, "seat0");
    }

    return self;
}

static void seat_bind(
    struct wl_client *client,
    void *data,
    uint32_t version,
    uint32_t id
) {
    struct wl_resource *resource = wl_resource_create(
        client,
        &wl_seat_interface,
        version,
        id
    );
    [[[OwlSeat alloc] initWithResource: resource] release];
}

+ (void) addGlobalToDisplay: (struct wl_display *) display {
    wl_global_create(display, &wl_seat_interface, 2, NULL, seat_bind);
}

@end
