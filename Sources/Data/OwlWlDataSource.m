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

#import "OwlWlDataSource.h"


@implementation OwlWlDataSource

static void data_source_destroy(struct wl_resource *resource) {
    OwlWlDataSource *self = wl_resource_get_user_data(resource);
    [self releaseFromHolders];
    [self release];
}

static void data_source_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static void data_source_offer_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    const char *mime_type
) {
    OwlWlDataSource *self = wl_resource_get_user_data(resource);
    [self->_mimeTypes addObject: [NSString stringWithUTF8String: mime_type]];
}

static const struct wl_data_source_interface data_source_impl = {
    .destroy = data_source_destroy_handler,
    .offer = data_source_offer_handler
};

- (id) initWithResource: (struct wl_resource *) resource {
    self = [super initWithResource: resource];
    wl_resource_set_implementation(
        resource,
        &data_source_impl,
        [self retain],
        data_source_destroy
    );
    return self;
}

- (void) sendContentOfMimeType: (NSString *) mimeType
                  toFileHandle: (NSFileHandle *) fileHandle
{
    wl_data_source_send_send(
        _resource,
        [mimeType UTF8String],
        [fileHandle fileDescriptor]
    );
}

- (void) sendCancelled {
    wl_data_source_send_cancelled(_resource);
}

@end
