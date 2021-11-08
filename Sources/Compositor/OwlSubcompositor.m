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

#import "OwlSubcompositor.h"
#import "OwlSurface.h"
#import "OwlSubsurface.h"


@implementation OwlSubcompositor

static void subcompositor_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static void subcompositor_destroy(struct wl_resource *resource) {
    OwlSubcompositor *self = wl_resource_get_user_data(resource);
    [self release];
}

static void subcompositor_get_subsurface_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t id,
    struct wl_resource *surface_resource,
    struct wl_resource *parent_resource
) {
    struct wl_resource *subsurface_resource = wl_resource_create(
        client,
        &wl_subsurface_interface,
        1,
        id
    );
    OwlSurface *surface = wl_resource_get_user_data(surface_resource);
    OwlSurface *parent = wl_resource_get_user_data(parent_resource);

#if 0
    // FIXME: This line doesn't compile anymore on Hurd for some reason, WTF?
    if ([surface role] != nil) {
        const char *role = [[[surface role] description] UTF8String];
        wl_resource_post_error(
            resource,
            WL_SUBCOMPOSITOR_ERROR_BAD_SURFACE,
            "Surface already has another role: %s",
            role
        );
        return;
    }
#endif
    [[[OwlSubsurface alloc] initWithResource: subsurface_resource
                                     surface: surface
                                      parent: parent] release];
}

static const struct wl_subcompositor_interface subcompositor_impl = {
    .destroy = subcompositor_destroy_handler,
    .get_subsurface = subcompositor_get_subsurface_handler
};

- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;
    wl_resource_set_implementation(
        resource,
        &subcompositor_impl,
        [self retain],
        subcompositor_destroy
    );
    return self;
}

static void subcompositor_bind(
    struct wl_client *client,
    void *data,
    uint32_t version,
    uint32_t id
) {
    struct wl_resource *resource = wl_resource_create(
        client,
        &wl_subcompositor_interface,
        version,
        id
    );
    [[[OwlSubcompositor alloc] initWithResource: resource] release];
}

+ (void) addGlobalToDisplay: (struct wl_display *) display {
    wl_global_create(
        display,
        &wl_subcompositor_interface,
        1,
        NULL,
        subcompositor_bind
    );
}

@end
