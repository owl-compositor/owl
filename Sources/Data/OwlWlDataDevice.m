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

#import "OwlWlDataDevice.h"
#import <wayland-server.h>
#import "OwlWlDataSource.h"
#import "OwlWlDataOffer.h"
#import "OwlSelection.h"


@implementation OwlWlDataDevice

static NSMutableArray *dataDevices;

+ (void) initialize {
    if (dataDevices == nil) {
        dataDevices = [[NSMutableArray alloc] initWithCapacity: 1];
    }
}

+ (OwlWlDataDevice *) dataDeviceForClient: (struct wl_client *) client {
    for (OwlWlDataDevice *dataDevice in dataDevices) {
        struct wl_resource *resource = dataDevice->_resource;
        if (client == wl_resource_get_client(resource)) {
            return dataDevice;
        }
    }
    return nil;
}

static void data_device_destroy(struct wl_resource *resource) {
    OwlWlDataDevice *self = wl_resource_get_user_data(resource);
    [dataDevices removeObjectIdenticalTo: self];
    [self release];
}

static void data_device_set_selection_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    struct wl_resource *source_resource,
    uint32_t serial
) {
    // TODO: Check the serial corresponds to an event of the focused surface
    // and the event is not it gaining focus.
    OwlWlDataDevice *self = wl_resource_get_user_data(resource);
    OwlWlDataSource *dataSource = nil;
    if (source_resource != NULL) {
        dataSource = wl_resource_get_user_data(source_resource);
    }
    [[OwlSelection clipboard] setDataSource: dataSource];
}

static void data_device_release_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static const struct wl_data_device_interface data_device_impl = {
    .set_selection = data_device_set_selection_handler,
    .release = data_device_release_handler
};

- (id) initWithResource: (struct wl_resource *) resource {
    self = [super initWithResource: resource];
    wl_resource_set_implementation(
        resource,
        &data_device_impl,
        [self retain],
        data_device_destroy
    );
    [dataDevices addObject: self];
    [[OwlSelection clipboard] addDataDevice: self];
    // FIXME: Call [self focused] here if we already have focus.
    [self selectionChanged: [OwlSelection clipboard]];
    return self;
}

- (void) dealloc {
    [[OwlSelection clipboard] removeDataDevice: self];
    [super dealloc];
}

- (void) sendSelection {
    _selectionHasChangedSinceLastFocused = NO;
    OwlDataSource *dataSource = [[OwlSelection clipboard] dataSource];

    if (dataSource == nil) {
        wl_data_device_send_selection(_resource, NULL);
        return;
    }

    struct wl_resource *offer_resource = wl_resource_create(
         wl_resource_get_client(_resource),
         &wl_data_offer_interface,
         2,
         0
    );
    wl_data_device_send_data_offer(_resource, offer_resource);
    // Creating an OwlDataOffer sends out the MIME types automatically.
    OwlWlDataOffer *offer =
        [[OwlWlDataOffer alloc] initWithResource: offer_resource
                                      dataSource: dataSource];
    wl_data_device_send_selection(_resource, offer_resource);
    [offer release];
}

- (void) selectionChanged: (OwlSelection *) selection {
    if (_focusCount > 0) {
        [self sendSelection];
    } else {
        _selectionHasChangedSinceLastFocused = YES;
    }
}

- (void) focused {
    _focusCount++;
    if (_focusCount == 1 && _selectionHasChangedSinceLastFocused) {
        [self sendSelection];
    }
}

- (void) unfocused {
    _focusCount--;
}

@end
