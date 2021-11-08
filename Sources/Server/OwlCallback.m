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

#import "OwlCallback.h"
#import <wayland-server.h>

@implementation OwlCallback

static void callback_destroy(struct wl_resource *resource) {
    OwlCallback *self = wl_resource_get_user_data(resource);
    [self release];
}

- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;
    wl_resource_set_implementation(
        resource,
        NULL,
        [self retain],
        callback_destroy
    );
    return self;
}

- (void) sendDoneWithData: (uint32_t) data {
    wl_callback_send_done(_resource, data);
    // Sending a callback also implicitly destroys it.
    wl_resource_destroy(_resource);
}

@end
