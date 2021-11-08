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

#import "OwlPasteboardDataDevice.h"
#import "OwlPasteboardDataOffer.h"
#import "OwlPasteboardDataSource.h"
#import "OwlServer.h"
#import "OwlSelection.h"


@implementation OwlPasteboardDataDevice

// Publish a fresh data source representing our pasteboard
// as the selection content.
- (void) publishDataSource {
    OwlPasteboardDataSource *dataSource = [OwlPasteboardDataSource alloc];
    dataSource = [dataSource initWithPasteboard: _pasteboard];

    [_selection setDataSource: dataSource];
    [dataSource release];
    [[OwlServer sharedServer] flushClientsLater];
}

// FIXME: This is only called by our own offers when they get cancelled,
// which means we miss refreshes when we don't own the pasteboard.
- (void) pasteboardRefreshed {
    if (_ignoreRefreshes) {
        return;
    }
    // We have to do this asynchronously, otherwise NSPasteboard gets confused over
    // accessing pasteboard contents from the pasteboardChangedOwner handler, and
    // sends the same notification again and again, recursively.
    // The order argument below represents which order these delayed selectors should
    // be executed in; lower values go first. We do not care, so pass some large number.
    NSArray *modes = [NSArray arrayWithObject: NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] performSelector: @selector(publishDataSource)
                                         target: self
                                       argument: nil
                                          order: 1000
                                          modes: modes];
}

- (id) initWithPasteboard: (NSPasteboard *) pboard
                selection: (OwlSelection *) selection
{
    self = [super initWithResource: NULL];
    _pasteboard = [pboard retain];
    _selection = [selection retain];
    [selection addDataDevice: self];
    // On startup, initialize selection with pasteboard contents.
    // We assume no clients have connected yet.
    [self pasteboardRefreshed];
    return self;
}

- (void) dealloc {
    [_pasteboard release];
    [_selection removeDataDevice: self];
    [_selection release];
    [_currentOffer release];
    [super dealloc];
}

- (NSPasteboard *) pasteboard {
    return _pasteboard;
}

// Selection has changed; proxy the new contents to the pasteboard.
- (void) selectionChanged: (OwlSelection *) selection {
    OwlDataSource *dataSource = [selection dataSource];
    [_currentOffer release];
    _currentOffer = nil;

    if (dataSource == nil) {
        [_pasteboard clearContents];
        return;
    }

    // Don't proxy pasteboard contents back to the pasteboard.
    if ([dataSource isKindOfClass: [OwlPasteboardDataSource class]]) {
        return;
    }

    _ignoreRefreshes = YES;
    _currentOffer = [OwlPasteboardDataOffer alloc];
    _currentOffer = [_currentOffer initWithDataDevice: self
                                           dataSource: dataSource];
    _ignoreRefreshes = NO;
}

@end
