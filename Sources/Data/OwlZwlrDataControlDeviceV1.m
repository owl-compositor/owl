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

#import "OwlZwlrDataControlDeviceV1.h"
#import "wlr-data-control-unstable-v1.h"
#import "OwlZwlrDataControlSourceV1.h"
#import "OwlZwlrDataControlOfferV1.h"
#import "OwlSelection.h"
#import "OwlFeatures.h"
#import <wayland-server.h>


@implementation OwlZwlrDataControlDeviceV1

static void data_control_device_destroy(struct wl_resource *resource) {
    OwlZwlrDataControlDeviceV1 *self = wl_resource_get_user_data(resource);
    [self release];
}

static void data_control_device_set_selection_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    struct wl_resource *source_resource
) {
    OwlZwlrDataControlDeviceV1 *self = wl_resource_get_user_data(resource);
    OwlZwlrDataControlSourceV1 *dataSource = nil;
    if (source_resource != NULL) {
        dataSource = (OwlZwlrDataControlSourceV1 *) wl_resource_get_user_data(source_resource);
    }
    [[OwlSelection clipboard] setDataSource: dataSource];
}

#ifdef OWL_PLATFORM_GNUSTEP
static void data_control_device_set_primary_selection_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    struct wl_resource *source_resource
) {
    OwlZwlrDataControlDeviceV1 *self = wl_resource_get_user_data(resource);
    OwlZwlrDataControlSourceV1 *dataSource = nil;
    if (source_resource != NULL) {
        dataSource = (OwlZwlrDataControlSourceV1 *) wl_resource_get_user_data(source_resource);
    }
    [[OwlSelection primary] setDataSource: dataSource];
}
#endif

static void data_control_device_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static const struct zwlr_data_control_device_v1_interface data_control_device_impl = {
    .set_selection = data_control_device_set_selection_handler,
#ifdef OWL_PLATFORM_GNUSTEP
    .set_primary_selection = data_control_device_set_primary_selection_handler,
#endif
    .destroy = data_control_device_destroy_handler
};

- (id) initWithResource: (struct wl_resource *) resource {
    self = [super initWithResource: resource];
    wl_resource_set_implementation(
        resource,
        &data_control_device_impl,
        [self retain],
        data_control_device_destroy
    );

    [[OwlSelection clipboard] addDataDevice: self];
    [self selectionChanged: [OwlSelection clipboard]];
#ifdef OWL_PLATFORM_GNUSTEP
    [[OwlSelection primary] addDataDevice: self];
    [self selectionChanged: [OwlSelection primary]];
#endif

    return self;
}

- (void) dealloc {
    [[OwlSelection clipboard] removeDataDevice: self];
#ifdef OWL_PLATFORM_GNUSTEP
    [[OwlSelection primary] removeDataDevice: self];
#endif
    [super dealloc];
}

- (void) sendOffer: (OwlZwlrDataControlOfferV1 *) offer
      forSelection: (OwlSelection *) selection
{
    struct wl_resource *offer_resource = [offer resource];

    if (selection == [OwlSelection clipboard]) {
        zwlr_data_control_device_v1_send_selection(_resource, offer_resource);
#ifdef OWL_PLATFORM_GNUSTEP
    } else if (selection == [OwlSelection primary]) {
        if (wl_resource_get_version(_resource) >= 2) {
            zwlr_data_control_device_v1_send_primary_selection(
                _resource,
                offer_resource
            );
        }
#endif
    } else {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Unexpected selection: %@", selection];
    }
}

- (void) selectionChanged: (OwlSelection *) selection {
    OwlDataSource *dataSource = [selection dataSource];

    if (dataSource == nil) {
        [self sendOffer: nil forSelection: selection];
        return;
    }

    // Introduce a new offer to the client.
    struct wl_resource *offer_resource = wl_resource_create(
        wl_resource_get_client(_resource),
        &zwlr_data_control_offer_v1_interface,
        wl_resource_get_version(_resource),
        0
    );
    zwlr_data_control_device_v1_send_data_offer(_resource, offer_resource);
    // Creating an OwlDataOffer sends out the MIME types automatically.
    OwlZwlrDataControlOfferV1 *offer =
        [[OwlZwlrDataControlOfferV1 alloc] initWithResource: offer_resource
                                                 dataSource: dataSource];
    [self sendOffer: offer forSelection: selection];
    [offer release];
}

@end
