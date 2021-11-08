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

#import "OwlDataSource.h"
#import <Cocoa/Cocoa.h>
#import <wayland-server.h>

// Data offers are sent to clients to represent a data source that they
// can request data from. There can be multiple data offers representing
// one data source (typically, one per data device).
//
// A data offer and the data source it represents need not use the same
// protocol: a client can ask to recevive data from a data offer using
// one protocol, and Owl will ask the backing client to send the data for
// the data source using another one.
@interface OwlDataOffer : NSObject <OwlDataSourceHolder> {
    struct wl_resource *_resource;
    OwlDataSource *_dataSource;
}

- (id) initWithResource: (struct wl_resource *) resource
             dataSource: (OwlDataSource *) dataSource;

- (struct wl_resource *) resource;

- (void) receiveContentOfMimeType: (const char *) mime_type
               intoFileDescriptor: (int) fd;

// Subclasses should override this.
- (void) addMimeType: (NSString *) mimeType;

@end
