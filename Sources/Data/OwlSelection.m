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

#import "OwlSelection.h"
#import "OwlDataSource.h"
#import "OwlDataDevice.h"
#import "OwlFeatures.h"


@implementation OwlSelection

- (id) init {
    _dataDevices = [NSMutableArray new];
    return self;
}

- (void) dealloc {
    [_dataDevices release];
    [_dataSource removeHolder: self];
    [_dataSource release];
    [super dealloc];
}

+ (OwlSelection *) clipboard {
    static OwlSelection *clipboard;
    if (clipboard == nil) {
        clipboard = [[OwlSelection alloc] init];
    }
    return clipboard;
}

#ifdef OWL_PLATFORM_GNUSTEP
+ (OwlSelection *) primary {
    static OwlSelection *primary;
    if (primary == nil) {
        primary = [[OwlSelection alloc] init];
    }
    return primary;
}
#endif

// Get the current data source.
- (OwlDataSource *) dataSource {
    return _dataSource;
}

- (void) setDataSource: (OwlDataSource *) source {
    if (source == _dataSource) {
        return;
    }

    // Clean up the old data source.
    [_dataSource sendCancelled];
    [_dataSource removeHolder: self];
    [_dataSource release];

    // Set up the new one.
    _dataSource = [source retain];
    [_dataSource addHolder: self];

    // Broadcast it to the data devices that we have a new data source.
    for (NSValue *value in _dataDevices) {
        OwlDataDevice *dataDevice = [value nonretainedObjectValue];
        [dataDevice selectionChanged: self];
    }
}

- (void) addDataDevice: (OwlDataDevice *) dataDevice {
    NSValue *value = [NSValue valueWithNonretainedObject: dataDevice];
    [_dataDevices addObject: value];
}

- (void) removeDataDevice: (OwlDataDevice *) dataDevice {
    NSValue *value = [NSValue valueWithNonretainedObject: dataDevice];
    [_dataDevices removeObject: value];
}

- (void) releaseDataSource: (OwlDataSource *) source {
    if (_dataSource == source) {
       [_dataSource release];
       _dataSource = nil;
    }
}

@end
