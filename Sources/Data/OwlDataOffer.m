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

#import "OwlDataOffer.h"
#import "OwlDataSource.h"
#import <wayland-server.h>


@implementation OwlDataOffer

- (id) initWithResource: (struct wl_resource *) resource
             dataSource: (OwlDataSource *) source
{
    _resource = resource;
    _dataSource = [source retain];
    [source addHolder: self];
    for (NSString *mimeType in [source mimeTypes]) {
        [self addMimeType: mimeType];
    }
    return self;
}

- (struct wl_resource *) resource {
    return _resource;
}

- (void) dealloc {
    [_dataSource removeHolder: self];
    [_dataSource release];
    [super dealloc];
}

- (void) receiveContentOfMimeType: (const char *) mime_type
               intoFileDescriptor: (int) fd
{
    NSFileHandle *fileHandle = [[NSFileHandle alloc] initWithFileDescriptor: fd];
    NSString *mimeType = [NSString stringWithUTF8String: mime_type];

    [_dataSource sendContentOfMimeType: mimeType toFileHandle: fileHandle];

    // Make sure not to delay closing the file.
    [fileHandle closeFile];
    [fileHandle release];
}

- (void) releaseDataSource: (OwlDataSource *) source {
    [_dataSource release];
    _dataSource = nil;
}

@end
