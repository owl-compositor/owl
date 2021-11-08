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
#import "OwlFeatures.h"
#import <Cocoa/Cocoa.h>

@class OwlDataDevice;

// A selection represents a "place" or a "slot" where data can be copied to
// and pasted from. One selection can only hold one data source at a time.
//
// There's a single global selection that represents the system clipboard.
// On GNUstep, there's additionally the primary selection.
@interface OwlSelection : NSObject <OwlDataSourceHolder> {
    OwlDataSource *_dataSource;
    NSMutableArray *_dataDevices;
}

+ (OwlSelection *) clipboard;
#ifdef OWL_PLATFORM_GNUSTEP
+ (OwlSelection *) primary;
#endif

// Get and set the contents of the selction, as a data source.
- (OwlDataSource *) dataSource;
- (void) setDataSource: (OwlDataSource *) dataSource;

// Subscribe and unsubscribe data devices.
// OwlSelection will call -selectionChanged: on the registered data devices.
- (void) addDataDevice: (OwlDataDevice *) dataDevice;
- (void) removeDataDevice: (OwlDataDevice *) dataDevice;

@end
