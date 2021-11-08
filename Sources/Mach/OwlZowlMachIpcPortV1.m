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

#import "OwlZowlMachIpcPortV1.h"
#import <Cocoa/Cocoa.h>
#import <wayland-server.h>
#import "owl-mach-ipc-unstable-v1.h"
#import "owl-mach-ipc-unstable-v1-mig.h"


@implementation OwlZowlMachIpcPortV1

static NSMutableDictionary *secretToPort;

+ (void) initialize {
    if (secretToPort == nil) {
        secretToPort = [[NSMutableDictionary alloc] init];
    }
}

static void mach_ipc_port_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static const struct zowl_mach_ipc_port_v1_interface mach_ipc_port_impl = {
    .destroy = mach_ipc_port_destroy_handler
};

static void mach_ipc_port_destroy(struct wl_resource *resource) {
    OwlZowlMachIpcPortV1 *self = wl_resource_get_user_data(resource);
    [secretToPort removeObjectsForKeys: [secretToPort allKeysForObject: self]];
    [self release];
}

- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;
    wl_resource_set_implementation(
        resource,
        &mach_ipc_port_impl,
        [self retain],
        mach_ipc_port_destroy
    );

    // Cannot use NSUUID, as it's 10.8+.
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *secret = (NSString *) CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);

    zowl_mach_ipc_port_v1_send_secret(resource, [secret UTF8String]);
    [secretToPort setObject: self forKey: secret];
    [secret release];
    return self;
}

- (void) setPort: (mach_port_t) port {
    _port = port;
}

// FIXME: deallocate the port in dealloc?

kern_return_t owl_mach_ipc_v1_server_retrieve_port(
    mach_port_t server_port,
    secret_t raw_secret,
    mach_port_t *port
) {
    NSString *secret = [NSString stringWithUTF8String: raw_secret];
    OwlZowlMachIpcPortV1 *self = [secretToPort objectForKey: secret];
    if (self == nil) {
        return KERN_INVALID_ARGUMENT;
    }
    [secretToPort removeObjectForKey: secret];
    *port = self->_port;
    return KERN_SUCCESS;
}

@end
