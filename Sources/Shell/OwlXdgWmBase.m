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

#import "OwlXdgWmBase.h"
#import "OwlSurface.h"
#import "OwlXdgSurface.h"
#import "xdg-shell.h"
#import <wayland-server.h>

@implementation OwlXdgWmBase

static void xdg_wm_base_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static void xdg_wm_base_destroy(
    struct wl_resource *resource
) {
    OwlXdgWmBase *self = wl_resource_get_user_data(resource);
    [self release];
}

static void xdg_wm_base_get_xdg_surface(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t id,
    struct wl_resource *surface_resource
) {
    struct wl_resource *xdg_surface_resource = wl_resource_create(
        client,
        &xdg_surface_interface,
        1,
        id
    );

    OwlSurface *surface = wl_resource_get_user_data(surface_resource);
    [[[OwlXdgSurface alloc] initWithResource: xdg_surface_resource
                                     surface: surface] release];
}

static const struct xdg_wm_base_interface xdg_wm_base_impl = {
    .destroy = xdg_wm_base_destroy_handler,
    .get_xdg_surface = xdg_wm_base_get_xdg_surface
    // TODO
};

- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;
    wl_resource_set_implementation(
        resource,
        &xdg_wm_base_impl,
        [self retain],
        NULL
    );
    return self;
}

static void xdg_wm_base_bind(
    struct wl_client *client,
    void *data,
    uint32_t version,
    uint32_t id
) {
    struct wl_resource *resource = wl_resource_create(
        client,
        &xdg_wm_base_interface,
        version,
        id
    );
    [[[OwlXdgWmBase alloc] initWithResource: resource] release];
}

+ (void) addGlobalToDisplay: (struct wl_display *) display {
    wl_global_create(
        display,
        &xdg_wm_base_interface,
        1,
        NULL,
        xdg_wm_base_bind
    );
}

@end
