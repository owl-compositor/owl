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

#import "OwlZxdgShellV6.h"
#import "OwlSurface.h"
#import "OwlZxdgSurfaceV6.h"
#import "xdg-shell-unstable-v6.h"
#import <wayland-server.h>

@implementation OwlZxdgShellV6

static void xdg_shell_v6_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static void xdg_shell_v6_destroy(
    struct wl_resource *resource
) {
    OwlZxdgShellV6 *self = wl_resource_get_user_data(resource);
    [self release];
}

static void xdg_shell_v6_get_xdg_surface(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t id,
    struct wl_resource *surface_resource
) {
    struct wl_resource *xdg_surface_resource = wl_resource_create(
        client,
        &zxdg_surface_v6_interface,
        1,
        id
    );

    OwlSurface *surface = wl_resource_get_user_data(surface_resource);
    [[[OwlZxdgSurfaceV6 alloc] initWithResource: xdg_surface_resource
                                        surface: surface] release];
}

static const struct zxdg_shell_v6_interface xdg_shell_v6_impl = {
    .destroy = xdg_shell_v6_destroy_handler,
    .get_xdg_surface = xdg_shell_v6_get_xdg_surface
    // TODO
};


- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;
    wl_resource_set_implementation(
        resource,
        &xdg_shell_v6_impl,
        [self retain],
        NULL
    );
    return self;
}

static void xdg_shell_v6_bind(
    struct wl_client *client,
    void *data,
    uint32_t version,
    uint32_t id
) {
    struct wl_resource *resource = wl_resource_create(
        client,
        &zxdg_shell_v6_interface,
        version,
        id
    );
    [[[OwlZxdgShellV6 alloc] initWithResource: resource] release];
    // TODO: destroy?
}

+ (void) addGlobalToDisplay: (struct wl_display *) display {
    wl_global_create(
        display,
        &zxdg_shell_v6_interface,
        1,
        NULL,
        xdg_shell_v6_bind
    );
}

@end
