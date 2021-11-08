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

#import "OwlKnownClientsManager.h"


@implementation OwlKnownClientsManager

- (void) createMenuItemForIndex: (NSUInteger) index
                     clientPath: (NSString *) clientPath
{
    NSString *title = [clientPath lastPathComponent];
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: title
                                                  action: @selector(startClient:)
                                           keyEquivalent: @""];
    [item setTarget: self];
    [item setTag: index];
    [_clientsMenu addItem: item];
    [item release];
}

- (void) update {
    [_clients release];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *customClients = [defaults arrayForKey: @"CustomClients"];
    _clients = [[_defaultClients arrayByAddingObjectsFromArray: customClients] retain];

    [_clientsMenu removeAllItems];

    NSUInteger size = [_clients count];
    for (NSUInteger i = 0; i < size; i++) {
        NSString *clientPath = [_clients objectAtIndex: i];
        [self createMenuItemForIndex: i clientPath: clientPath];
    }
}

- (void) awakeFromNib {
    NSString *path = [[NSBundle mainBundle] resourcePath];
    _defaultClients = [[NSArray alloc] initWithObjects:
        [path stringByAppendingPathComponent: @"weston-terminal"],
        [path stringByAppendingPathComponent: @"weston-flower"],
        [path stringByAppendingPathComponent: @"weston-smoke"],
        nil
    ];

    [self update];
}

- (void) dealloc {
    [_clientsMenu removeAllItems];
    [_defaultClients release];
    [_clients release];
    [super dealloc];
}

- (IBAction) startClient: (id) sender {
    NSUInteger index = [sender tag];
    NSString *path = [_clients objectAtIndex: index];
    [NSTask launchedTaskWithLaunchPath: path arguments: [NSArray array]];
}

- (IBAction) configureClients: (id) sender {
}

@end
