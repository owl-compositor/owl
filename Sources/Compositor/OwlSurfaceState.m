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

#import "OwlSurfaceState.h"
#import "OwlBuffer.h"


@implementation OwlSurfaceState

- (id) init {
    _callbacks = [NSMutableArray new];
    _damage = [NSMutableArray new];
    return self;
}

// Make a new state to succeed the given previous state.
//
// This copies over parts of the previous state that should
// be copied over, namely the attached buffer and geometry,
// and initializes other state to empty values.
- (id) initWithPreviousState: (OwlSurfaceState *) previousState {
    self = [self init];
    _buffer = [previousState->_buffer retain];
    _geometry = previousState->_geometry;
    return self;
}

- (void) dealloc {
    [_buffer release];
    [_callbacks release];
    [_damage release];
    [super dealloc];
}

- (OwlBuffer *) buffer {
    return _buffer;
}

- (void) setBuffer: (OwlBuffer *) buffer {
    [buffer retain];
    [_buffer release];
    _buffer = buffer;
}

- (NSArray *) callbacks {
    return _callbacks;
}

- (void) addCallback: (OwlCallback *) callback {
    [_callbacks addObject: callback];
}

- (NSArray *) damage {
    return _damage;
}

- (void) addDamage: (NSRect) damageRect {
    NSValue *value = [NSValue valueWithRect: damageRect];
    [_damage addObject: value];
}

- (NSRect) geometry {
    return _geometry;
}

- (void) setGeometry: (NSRect) geometry {
    _geometry = geometry;
}

@end
