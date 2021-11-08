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

#import "OwlZowlMachIpcV1.h"
#import <Cocoa/Cocoa.h>
#import <wayland-server.h>
#import "owl-mach-ipc-unstable-v1.h"
#import "owl-mach-ipc-unstable-v1-mig.h"
#import <mach/mach.h>
#import <servers/bootstrap.h>
#import "OwlZowlMachIpcPortV1.h"
#import "OwlMIG.h"

@implementation OwlZowlMachIpcV1

static NSString *globalName;
static mach_port_t port;

+ (BOOL) bootstrapCheckInWithName: (NSString *) name {
    globalName = [name retain];
    const char *raw_name = [name UTF8String];
    kern_return_t kr = bootstrap_check_in(bootstrap_port, raw_name, &port);
    if (kr != KERN_SUCCESS) {
        NSLog(@"bootstrap_check_in(%@) = %x", name, kr);
        return NO;
    } else {
        NSLog(@"Checked in with the bootstrap server as %@", name);
    }

    [OwlMIG serveOnPort: port
          usingCallback: owl_mach_ipc_v1_server
                maxSize: 100];
    return YES;
}

static void mach_ipc_destroy(struct wl_resource *resource) {
    OwlZowlMachIpcV1 *self = wl_resource_get_user_data(resource);
    [self release];
}

static void mach_ipc_create_port_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t id
) {
    struct wl_resource *port_resource = wl_resource_create(
        client,
        &zowl_mach_ipc_port_v1_interface,
        1,
        id
    );
    [[[OwlZowlMachIpcPortV1 alloc] initWithResource: port_resource] release];
}

static void mach_ipc_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static const struct zowl_mach_ipc_v1_interface mach_ipc_impl = {
    .create_port = mach_ipc_create_port_handler,
    .destroy = mach_ipc_destroy_handler
};

- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;
    wl_resource_set_implementation(
        resource,
        &mach_ipc_impl,
        [self retain],
        mach_ipc_destroy
    );
    zowl_mach_ipc_v1_send_bootstrap_name(resource, [globalName UTF8String]);
    return self;
}

static void mach_ipc_bind(
    struct wl_client *client,
    void *data,
    uint32_t version,
    uint32_t id
) {
    struct wl_resource *resource = wl_resource_create(
        client,
        &zowl_mach_ipc_v1_interface,
        version,
        id
    );
    [[[OwlZowlMachIpcV1 alloc] initWithResource: resource] release];
}

+ (void) addGlobalToDisplay: (struct wl_display *) display {
    wl_global_create(
        display,
        &zowl_mach_ipc_v1_interface,
        1,
        NULL,
        mach_ipc_bind
    );
}

@end
