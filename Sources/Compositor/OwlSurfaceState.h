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

@class OwlBuffer;
@class OwlCallback;

@interface OwlSurfaceState : NSObject {
    OwlBuffer *_buffer;
    // TODO: dx, dy
    NSMutableArray *_callbacks;
    NSMutableArray *_damage;
    NSRect _geometry;
}

- (id) init;
- (id) initWithPreviousState: (OwlSurfaceState *) previousState;

- (OwlBuffer *) buffer;
- (void) setBuffer: (OwlBuffer *) buffer;

- (NSArray *) callbacks;
- (void) addCallback: (OwlCallback *) callback;

- (NSArray *) damage;
- (void) addDamage: (NSRect) damageRect;

- (NSRect) geometry;
- (void) setGeometry: (NSRect) geometry;

@end
