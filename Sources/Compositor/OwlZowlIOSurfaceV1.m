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

#import "OwlZowlIOSurfaceV1.h"
#import "owl-iosurface-unstable-v1.h"
#import "owl-iosurface-unstable-v1-mig.h"
#import "OwlMIG.h"
#import "OwlIOSurfaceBuffer.h"

@implementation OwlZowlIOSurfaceV1

static NSMutableArray *instances;

+ (void) initialize {
    if (instances == nil) {
        instances = [[NSMutableArray alloc] init];
    }
}

static void iosurface_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static void iosurface_destroy(struct wl_resource *resource) {
    OwlZowlIOSurfaceV1 *self = wl_resource_get_user_data(resource);
    [self release];
}

static void iosurface_create_buffer_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t id
) {
    OwlZowlIOSurfaceV1 *self = wl_resource_get_user_data(resource);
    struct wl_resource *buffer_resource = wl_resource_create(
        client,
        &wl_buffer_interface,
        1,
        id
    );
    [[[OwlIOSurfaceBuffer alloc] initWithResource: buffer_resource
                                      surfacePort: self->_surfacePort] release];
}

static const struct zowl_iosurface_v1_interface iosurface_impl = {
    .create_buffer = iosurface_create_buffer_handler,
    .destroy = iosurface_destroy_handler
};

- (id) initWithResource: (struct wl_resource *) resource {
    [instances addObject: self];
    _resource = resource;
    wl_resource_set_implementation(
        resource,
        &iosurface_impl,
        [self retain],
        iosurface_destroy
    );

    // Create the receiver port and serve owl_iosurface_v1 on it.
    mach_port_allocate(
        mach_task_self(),
        MACH_PORT_RIGHT_RECEIVE,
        &_receiverPort
    );
    [OwlMIG serveOnPort: _receiverPort
          usingCallback: owl_iosurface_v1_server
                maxSize: 100];

    return self;
}

- (void) dealloc {
    mach_port_deallocate(mach_task_self(), _receiverPort);
    if (MACH_PORT_VALID (_surfacePort)) {
        mach_port_deallocate(mach_task_self(), _surfacePort);
    }
    [instances removeObject: self];
    [super dealloc];
}

- (mach_port_t) receiverPort {
    return _receiverPort;
}

+ (OwlZowlIOSurfaceV1 *) surfaceByReceiverPort: (mach_port_t) port {
    for (OwlZowlIOSurfaceV1 *surface in instances) {
        if (surface->_receiverPort == port) {
            return surface;
        }
    }
    return nil;
}

kern_return_t owl_iosurface_v1_server_set_surface_port(
    mach_port_t receiver_port,
    mach_port_t iosurface_port
) {
    OwlZowlIOSurfaceV1 *surface = [OwlZowlIOSurfaceV1 surfaceByReceiverPort: receiver_port];
    if (surface == nil) {
        NSLog(@"Failed to find the surface the receiver port belongs to");
        return KERN_INVALID_ARGUMENT;
    }
    surface->_surfacePort = iosurface_port;
    return KERN_SUCCESS;
}

@end

#endif /* OWL_PLATFORM_APPLE */
