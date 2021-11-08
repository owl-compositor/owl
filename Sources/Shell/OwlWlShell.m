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

#import "OwlWlShell.h"
#import <wayland-server.h>
#import "OwlSurface.h"
#import "OwlWlShellSurface.h"

@implementation OwlWlShell

static void shell_get_shell_surface_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t id,
    struct wl_resource *surface_resource
) {
    struct wl_resource *shell_surface_resource = wl_resource_create(
        client,
        &wl_shell_surface_interface,
        1,
        id
    );

    OwlSurface *surface = wl_resource_get_user_data(surface_resource);
    [[[OwlWlShellSurface alloc] initWithResource: shell_surface_resource
                                         surface: surface] release];
}

static const struct wl_shell_interface shell_impl = {
    .get_shell_surface = shell_get_shell_surface_handler
};

static void wl_shell_destroy(struct wl_resource *resource) {
    OwlWlShell *self = wl_resource_get_user_data(resource);
    [self release];
}

- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;
    wl_resource_set_implementation(
        resource,
        &shell_impl,
        [self retain],
        wl_shell_destroy
    );
    return self;
}

static void shell_bind(
    struct wl_client *client,
    void *data,
    uint32_t version,
    uint32_t id
) {
    struct wl_resource *resource = wl_resource_create(
        client,
        &wl_shell_interface,
        version,
        id
    );
    [[[OwlWlShell alloc] initWithResource: resource] release];
}

+ (void) addGlobalToDisplay: (struct wl_display *) display {
    wl_global_create(display, &wl_shell_interface, 1, NULL, shell_bind);
}

@end
