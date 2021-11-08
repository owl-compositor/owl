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
#import "OwlWindow.h"

@interface OwlWindowWrapper : NSObject {
    NSString *_title;
    OwlWindow *_window;
    NSView *_view;
    NSSize _size;
    id<NSWindowDelegate> _windowDelegate;
}

- (OwlWindow *) window;

- (void) map;
- (void) unmap;
- (void) close;

- (void) minimize;
- (void) maximize;
- (void) unmaximize;

- (void) setContentSize: (NSSize) size;
- (void) setTitle: (NSString *) title;
- (void) setView: (NSView *) view;
- (void) setWindowDelegate: (id<NSWindowDelegate>) delegate;


@end
