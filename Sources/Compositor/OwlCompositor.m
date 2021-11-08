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

#import "OwlCompositor.h"
#import "OwlSurface.h"
#import "OwlRegion.h"
#import <Cocoa/Cocoa.h>

@implementation OwlCompositor

static void compositor_create_surface_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t id
) {
    uint32_t version = wl_resource_get_version(resource);
    struct wl_resource *surface_resource = wl_resource_create(
        client,
        &wl_surface_interface,
        version,
        id
    );
    [[[OwlSurface alloc] initWithResource: surface_resource] release];
}

static void compositor_create_region_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t id
) {
    uint32_t version = wl_resource_get_version(resource);
    struct wl_resource *region_resource = wl_resource_create(
        client,
        &wl_region_interface,
        version,
        id
    );
    [[[OwlRegion alloc] initWithResource: region_resource] release];
}

static const struct wl_compositor_interface compositor_interface = {
    .create_surface = compositor_create_surface_handler,
    .create_region = compositor_create_region_handler
};

static void compositor_destroy(struct wl_resource *resource) {
    OwlCompositor *self = wl_resource_get_user_data(resource);
    [self release];
}

- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;
    wl_resource_set_implementation(
        resource,
        &compositor_interface,
        [self retain],
        compositor_destroy
    );
    return self;
}

static void compositor_bind(
    struct wl_client *client,
    void *data,
    uint32_t version,
    uint32_t id
) {
    struct wl_resource *resource = wl_resource_create(
        client,
        &wl_compositor_interface,
        version,
        id
    );
    [[[OwlCompositor alloc] initWithResource: resource] release];
}

+ (void) addGlobalToDisplay: (struct wl_display *) display {
    wl_global_create(
        display,
        &wl_compositor_interface,
        4,
        NULL,
        compositor_bind
    );
}

@end
