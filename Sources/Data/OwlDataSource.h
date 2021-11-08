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

#import <Cocoa/Cocoa.h>
#import <wayland-server.h>

@class OwlDataSource;

// Something that keeps a reference to a data source.
//
// A data source can conceptually die at any moment, but the object
// can only be deallocated once all the references to it are gone.
// To make this work, data sources notify the interested parties of their
// death, asking them to drop their reference. Once they all do, the data
// source gets deallocated.
//
// In addition to implementing -releaseDataSource:, data source holders
// should call -addHolder: and -removeHolder: as appropriate, to help the
// data source maintain an up-to-date list of its holders.
@protocol OwlDataSourceHolder
- (void) releaseDataSource: (OwlDataSource *) source;
@end


// A data source represents a lazily-received piece of data, perhaps
// available in several formats, such as plain and rich text.
//
// Typically, it's a client that actually has the data represented by a
// data source.
@interface OwlDataSource : NSObject {
    struct wl_resource *_resource;
    NSMutableArray *_mimeTypes;
    NSMutableArray *_holders;
}

- (id) initWithResource: (struct wl_resource *) resource;

- (NSArray *) mimeTypes;

// Data source holder management.
- (void) addHolder: (id<OwlDataSourceHolder>) holder;
- (void) removeHolder: (id<OwlDataSourceHolder>) holder;
- (void) releaseFromHolders;

// Subclasses should override these.
- (void) sendContentOfMimeType: (NSString *) mimeType
                  toFileHandle: (NSFileHandle *) fileHandle;
- (void) sendCancelled;

@end
