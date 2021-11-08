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

#import "OwlPasteboardDataSource.h"
#import "OwlPasteboardType.h"
#import <Cocoa/Cocoa.h>


@implementation OwlPasteboardDataSource

- (id) initWithPasteboard: (NSPasteboard *) pboard {
    self = [super initWithResource: NULL];
    _pasteboard = [pboard retain];

    // Make a copy of the types array first.
    // Otherwise we run into a crash on GNUstep
    // while trying to use NSFastEnumeration
    // with distributed objects.
    NSArray *types = [NSArray arrayWithArray: [pboard types]];
    for (NSString *uti in types) {
        OwlPasteboardType *type = [[OwlPasteboardType alloc] initWithUTI: uti];
        NSString *mimeType = [type mimeType];
        if (mimeType != nil) {
            [_mimeTypes addObject: mimeType];
        }
        [type release];
    }

    return self;
}

- (void) dealloc {
    [_pasteboard release];
    [super dealloc];
}

- (void) sendContentOfMimeType: (NSString *) mimeType
                  toFileHandle: (NSFileHandle *) fileHandle
{
    OwlPasteboardType *type = [[OwlPasteboardType alloc] initWithMimeType: mimeType];
    NSData *data;
    NSString *uti = [type UTI];
    if ([type isText]) {
        NSString *s = [_pasteboard stringForType: uti];
        data = [s dataUsingEncoding: NSUTF8StringEncoding];
    } else {
        data = [_pasteboard dataForType: uti];
    }
    [type release];
    [fileHandle writeData: data];
}

- (void) sendCancelled {
    // Do nothing.
}

@end
