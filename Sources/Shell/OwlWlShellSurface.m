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

#import "OwlWlShellSurface.h"
#import "OwlSurface.h"
#import "OwlWindowWrapper.h"
#import <wayland-server.h>

@implementation OwlWlShellSurface

static void shell_surface_destroy(struct wl_resource *resource) {
    OwlWlShellSurface *self = wl_resource_get_user_data(resource);
    [self->_window close];
    [self release];
}

static void shell_surface_move_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    struct wl_resource *seat_resource,
    uint32_t serial
) {
    OwlWlShellSurface *self = wl_resource_get_user_data(resource);
    [[self->_window window] runInteractiveMove];
}

static void shell_surface_set_toplevel_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    OwlWlShellSurface *self = wl_resource_get_user_data(resource);
    self->_mode = OWL_WL_SHELL_SURFACE_MODE_TOPLEVEL;
}

static void shell_surface_set_title_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    const char *raw_title
) {
    OwlWlShellSurface *self = wl_resource_get_user_data(resource);
    [self->_window setTitle: [NSString stringWithUTF8String: raw_title]];
}

static const struct wl_shell_surface_interface shell_surface_interface = {
    .set_toplevel = shell_surface_set_toplevel_handler,
    .set_title = shell_surface_set_title_handler
    // TODO
};

- (id) initWithResource: (struct wl_resource *) resource
                surface: (OwlSurface *) surface
{
    _resource = resource;
    _surface = [surface retain];

    [surface setRole: self];
    _window = [OwlWindowWrapper new];
    [_window setView: surface];

    wl_resource_set_implementation(
        resource,
        &shell_surface_interface,
        [self retain],
        shell_surface_destroy
    );
    return self;
}

- (void) dealloc {
    [_surface release];
    [_window release];
    [super dealloc];
}

- (void) map {
    [self update];
    [_window map];
}

- (void) unmap {
    [_window unmap];
}

- (void) update {
    [_window setContentSize: [_surface bounds].size];
}

@end
