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

#import "OwlWlDataOffer.h"


@implementation OwlWlDataOffer

static void data_offer_destroy(struct wl_resource *resource) {
    OwlWlDataOffer *self = wl_resource_get_user_data(resource);
    [self release];
}

static void data_offer_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static void data_offer_accept(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t serial,
    const char *mime_type
) {
    // TODO
}

static void data_offer_receive_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    const char *mime_type,
    int fd
) {
    OwlWlDataOffer *self = wl_resource_get_user_data(resource);
    [self receiveContentOfMimeType: mime_type intoFileDescriptor: fd];
}

static const struct wl_data_offer_interface data_offer_impl = {
    .destroy = data_offer_destroy_handler,
    .receive = data_offer_receive_handler
};

- (id) initWithResource: (struct wl_resource *) resource
             dataSource: (OwlDataSource *) source
{
    self = [super initWithResource: resource dataSource: source];
    wl_resource_set_implementation(
        resource,
        &data_offer_impl,
        [self retain],
        data_offer_destroy
    );
    return self;
}

- (void) addMimeType: (NSString *) mimeType {
    wl_data_offer_send_offer(_resource, [mimeType UTF8String]);
}

@end
