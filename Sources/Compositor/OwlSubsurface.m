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

#import "OwlSubsurface.h"
#import "OwlSurface.h"
#import "OwlServer.h"
#import <wayland-server.h>

@implementation OwlSubsurface

static void subsurface_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static void subsurface_destroy(struct wl_resource *resource) {
    OwlSubsurface *self = wl_resource_get_user_data(resource);
    [self unmap];
    [self->_surface setRole: nil];
    [self release];
}

static void subsurface_set_position_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    int32_t x,
    int32_t y
) {
    OwlSubsurface *self = wl_resource_get_user_data(resource);
    self->_position = NSMakePoint(x, y);
}

static void subsurface_place_above_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    struct wl_resource *sibling_resource
) {
    OwlSubsurface *self = wl_resource_get_user_data(resource);
    // TODO
}

static void subsurface_place_below_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    struct wl_resource *sibling_resource
) {
    OwlSubsurface *self = wl_resource_get_user_data(resource);
    // TODO
}

static void subsurface_set_sync_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    OwlSubsurface *self = wl_resource_get_user_data(resource);
    // TODO
}

static void subsurface_set_desync_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    OwlSubsurface *self = wl_resource_get_user_data(resource);
    // TODO
}

static const struct wl_subsurface_interface subsurface_impl = {
    .destroy = subsurface_destroy_handler,
    .set_position = subsurface_set_position_handler,
    .place_above = subsurface_place_above_handler,
    .place_below = subsurface_place_below_handler,
    .set_sync = subsurface_set_sync_handler,
    .set_desync = subsurface_set_desync_handler
};

- (id) initWithResource: (struct wl_resource *) resource
                surface: (OwlSurface *) surface
                 parent: (OwlSurface *) parent
{
    _resource = resource;
    _surface = [surface retain];
    _parent = [parent retain];
    [surface setRole: self];

    wl_resource_set_implementation(
        resource,
        &subsurface_impl,
        [self retain],
        subsurface_destroy
    );

    return self;
}

- (void) dealloc {
    [self unmap];
    [_surface release];
    [_parent release];
    [super dealloc];
}

// FIXME: These are supposed to be applied on parent's next commit.
- (void) map {
    [_parent addSubview: _surface];
    [self update];
}

- (void) unmap {
    [_surface removeFromSuperview];
}

- (void) update {
    NSPoint origin;
    origin.x = _position.x;
    origin.y = [_parent frame].size.height - [_surface frame].size.height - _position.y;
    [_surface setFrameOrigin: origin];
}

@end
