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

#import "OwlPasteboardDataOffer.h"
#import "OwlDataOffer.h"
#import "OwlPasteboardDataDevice.h"
#import "OwlPasteboardType.h"
#import "OwlServer.h"
#import "OwlDataDevice.h"
#import "OwlSelection.h"
#import <wayland-server.h>


@implementation OwlPasteboardDataOffer

- (id) initWithDataDevice: (OwlPasteboardDataDevice *) device
               dataSource: (OwlDataSource *) dataSource
{
    _types = [NSMutableArray new];
    _dataDevice = [device retain];
    // The parent constructor fills in types.
    [super initWithResource: NULL dataSource: dataSource];
    [[device pasteboard] declareTypes: _types owner: self];
    return self;
}

- (void) dealloc {
    [_types release];
    [_dataDevice release];
    [super dealloc];
}

- (void) addMimeType: (NSString *) mimeType {
    OwlPasteboardType *type = [[OwlPasteboardType alloc] initWithMimeType: mimeType];
    [_types addObject: [type UTI]];
    [type release];
}

- (void) pasteboard: (NSPasteboard *) pasteboard
 provideDataForType: (NSString *) uti
{
    OwlPasteboardType *type = [[[OwlPasteboardType alloc] initWithUTI: uti] autorelease];
    NSString *mimeType = [type mimeType];
    if (mimeType == nil) {
        // We can't meaningfully convert this UTI to a MIME type.
        // Refuse to provide the data, and hope for the better.
        return;
    }

    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *writingHandle = [pipe fileHandleForWriting];
    [_dataSource sendContentOfMimeType: mimeType
                          toFileHandle: writingHandle];
    [writingHandle closeFile];
    [[OwlServer sharedServer] flushClients];

    // Sigh, it seems there's no other way but to do this synchronously.
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    if ([type isText]) {
        NSString *s = [[NSString alloc] initWithData: data
                                            encoding: NSUTF8StringEncoding];
        [pasteboard setString: s forType: uti];
        [s release];
    } else {
        [pasteboard setData: data forType: uti];
    }
}

- (void) pasteboardChangedOwner: (NSPasteboard *) pasteboard {
    [_dataDevice pasteboardRefreshed];
}

@end
