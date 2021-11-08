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

#import "OwlZwlrDataControlOfferV1.h"
#import "wlr-data-control-unstable-v1.h"
#import <wayland-server.h>


@implementation OwlZwlrDataControlOfferV1

static void data_control_offer_destroy(struct wl_resource *resource) {
    OwlZwlrDataControlOfferV1 *self = wl_resource_get_user_data(resource);
    [self release];
}

static void data_control_offer_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static void data_control_offer_receive_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    const char *mime_type,
    int fd
) {
    OwlZwlrDataControlOfferV1 *self = wl_resource_get_user_data(resource);
    [self receiveContentOfMimeType: mime_type intoFileDescriptor: fd];
}

static const struct zwlr_data_control_offer_v1_interface data_control_offer_impl = {
    .destroy = data_control_offer_destroy_handler,
    .receive = data_control_offer_receive_handler
};

- (id) initWithResource: (struct wl_resource *) resource
             dataSource: (OwlDataSource *) source
{
    self = [super initWithResource: resource dataSource: source];
    wl_resource_set_implementation(
        resource,
        &data_control_offer_impl,
        [self retain],
        data_control_offer_destroy
    );
    return self;
}

- (void) addMimeType: (NSString *) mimeType {
    zwlr_data_control_offer_v1_send_offer(_resource, [mimeType UTF8String]);
}

@end
