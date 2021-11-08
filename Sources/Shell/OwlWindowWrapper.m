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

#import "OwlWindowWrapper.h"
#import "OwlWindow.h"
#import <Cocoa/Cocoa.h>

@implementation OwlWindowWrapper

- (void) dealloc {
    [_window release];
    [_title release];
    [_view release];
    [_windowDelegate release];
    [super dealloc];
}

- (void) createWindow {
    _window = [[OwlWindow alloc] initWithSize: _size displaySSD: NO];

    if (_title != nil) {
        [_window setTitle: _title];
    }
    if (_view != nil) {
        [[_window contentView] addSubview: _view];
        [_window makeFirstResponder: _view];
    }
    [_window setDelegate: _windowDelegate];
}

- (void) map {
    if (_window == nil) {
        [self createWindow];
    }
    [_window makeKeyAndOrderFront: self];
}

- (void) unmap {
    [_window orderOut: self];
}

- (void) close {
    [_window close];
}

- (void) minimize {
    [_window miniaturize: self];
}

- (void) maximize {
    if (![_window isZoomed]) {
        [_window zoom: self];
    }
}

- (void) unmaximize {
    if ([_window isZoomed]) {
        [_window zoom: self];
    }
}

- (OwlWindow *) window {
    return _window;
}

- (void) setContentSize: (NSSize) size {
    _size = size;
    [_window setContentSize: _size];
}

- (void) setTitle: (NSString *) title {
    [title retain];
    [_title release];
    _title = title;
    [_window setTitle: title];
}

- (void) setView: (NSView *) view {
    [view retain];
    [_view removeFromSuperview];
    [_view release];
    _view = view;
    [[_window contentView] addSubview: view];
    [_window makeFirstResponder: view];
}

- (void) setWindowDelegate: (id<NSWindowDelegate>) delegate {
    [delegate retain];
    [_windowDelegate release];
    _windowDelegate = delegate;
    [_window setDelegate: delegate];
}

@end
