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

#import "OwlWlDataDeviceManager.h"
#import "OwlWlDataSource.h"
#import "OwlWlDataDevice.h"


@implementation OwlWlDataDeviceManager

static void data_device_manager_destroy(struct wl_resource *resource) {
    OwlWlDataDeviceManager *self = wl_resource_get_user_data(resource);
    [self release];
}

static void data_device_manager_create_data_source_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t id
) {
    struct wl_resource *data_source_resource = wl_resource_create(
        client,
        &wl_data_source_interface,
        2,
        id
    );
    [[[OwlWlDataSource alloc] initWithResource: data_source_resource] release];
}

static void data_device_manager_get_data_device_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t id,
    struct wl_resource *seat_resource
) {
    struct wl_resource *data_device_resource = wl_resource_create(
        client,
        &wl_data_device_interface,
        2,
        id
    );
    [[[OwlWlDataDevice alloc] initWithResource: data_device_resource] release];
}

static const struct wl_data_device_manager_interface data_device_manager_impl = {
    .create_data_source = data_device_manager_create_data_source_handler,
    .get_data_device = data_device_manager_get_data_device_handler
};

- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;
    wl_resource_set_implementation(
        resource,
        &data_device_manager_impl,
        [self retain],
        data_device_manager_destroy
    );
    return self;
}

static void data_device_manager_bind(
    struct wl_client *client,
    void *data,
    uint32_t version,
    uint32_t id
) {
    struct wl_resource *resource = wl_resource_create(
        client,
        &wl_data_device_manager_interface,
        version,
        id
    );
    [[[OwlWlDataDeviceManager alloc] initWithResource: resource] release];
}

+ (void) addGlobalToDisplay: (struct wl_display *) display {
    wl_global_create(
        display,
        &wl_data_device_manager_interface,
        2,
        NULL,
        data_device_manager_bind
    );
}

@end
