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


@implementation OwlDataSource

- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;
    _mimeTypes = [NSMutableArray new];
    _holders = [NSMutableArray new];
    return self;
}

- (void) dealloc {
    [_mimeTypes release];
    [_holders release];
    [super dealloc];
}

- (NSArray *) mimeTypes {
    return _mimeTypes;
}

- (void) addHolder: (id<OwlDataSourceHolder>) holder {
    NSValue *value = [NSValue valueWithNonretainedObject: holder];
    [_holders addObject: value];
}

- (void) removeHolder: (id<OwlDataSourceHolder>) holder {
    NSValue *value = [NSValue valueWithNonretainedObject: holder];
    [_holders removeObject: value];
}

// Ask all holders to release their references to this data source.
- (void) releaseFromHolders {
    for (NSValue *value in _holders) {
        id<OwlDataSourceHolder> holder = [value nonretainedObjectValue];
        [holder releaseDataSource: self];
    }
    [_holders removeAllObjects];
}

@end
