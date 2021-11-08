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

#import "OwlFeatures.h"
#ifdef OWL_PLATFORM_APPLE

#import "OwlZowlIOSurfaceManagerV1.h"
#import "OwlZowlIOSurfaceV1.h"
#import <wayland-server.h>
#import "OwlGlobal.h"
#import "owl-iosurface-unstable-v1.h"
#import "OwlZowlMachIpcPortV1.h"


@implementation OwlZowlIOSurfaceManagerV1

static void iosurface_manager_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static void iosurface_manager_create_surface_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    struct wl_resource *port_resource,
    uint32_t id
) {
    struct wl_resource *iosurface_resource = wl_resource_create(
        client,
        &zowl_iosurface_v1_interface,
        1,
        id
    );
    OwlZowlIOSurfaceV1 *iosurface = [[OwlZowlIOSurfaceV1 alloc] initWithResource: iosurface_resource];
    OwlZowlMachIpcPortV1 *port = wl_resource_get_user_data(port_resource);
    [port setPort: [iosurface receiverPort]];
    [iosurface release];
}

static const struct zowl_iosurface_manager_v1_interface iosurface_manager_impl = {
    .create_surface = iosurface_manager_create_surface_handler,
    .destroy = iosurface_manager_destroy_handler
};

static void iosurface_manager_destroy(struct wl_resource *resource) {
    OwlZowlIOSurfaceManagerV1 *self = wl_resource_get_user_data(resource);
    [self release];
}

- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;
    wl_resource_set_implementation(
        resource,
        &iosurface_manager_impl,
        [self retain],
        iosurface_manager_destroy
    );
    return self;
}

static void iosurface_manager_bind(
    struct wl_client *client,
    void *data,
    uint32_t version,
    uint32_t id
) {
    struct wl_resource *resource = wl_resource_create(
        client,
        &zowl_iosurface_manager_v1_interface,
        version,
        id
    );
    [[[OwlZowlIOSurfaceManagerV1 alloc] initWithResource: resource] release];
}

+ (void) addGlobalToDisplay: (struct wl_display *) display {
    wl_global_create(
        display,
        &zowl_iosurface_manager_v1_interface,
        1,
        NULL,
        iosurface_manager_bind
    );
}

@end

#endif /* OWL_PLATFORM_APPLE */
