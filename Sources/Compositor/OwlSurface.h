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
#import <wayland-server.h>

@class OwlBuffer;
@class OwlSurfaceState;

@protocol OwlSurfaceRole

- (void) map;
- (void) unmap;
- (void) update;

@end

@interface OwlSurface : NSView {
    struct wl_resource *_resource;
    NSOpenGLContext *_openGLContext;

    // Mouse tracking rectangle.
    NSTrackingRectTag _trackingRectTag;
    // Sadly, we cannot trust Cocoa to always deliver us
    // -mouseEntered: before -mouseMoved:, so keep our
    // own track of whether we think the mouse is inside.
    BOOL _mouseIsInside;

    // Callbacks to be sent when we draw a frame.
    // These are first collected as a part of a pending
    // state, and added to this array on a commit. Once
    // added, the callbacks stay in this array no matter
    // further state changes and commits, only to be sent
    // out during the next -drawRect: call.
    NSMutableArray *_callbacks;

    // The current state of this surface. This includes
    // things such as the attached buffer and an array
    // of damaged rects (compared to the previous frame).
    OwlSurfaceState *_currentState;
    // As the surface state in Wayland is double-buffered,
    // we store the pending state separately while it is
    // being built. This will become the new current state
    // on the next commit.
    OwlSurfaceState *_pendingState;
    id<OwlSurfaceRole> _role;
}

- (id) initWithResource: (struct wl_resource *) resource;

- (struct wl_resource *) resource;

- (id<OwlSurfaceRole>) role;
- (void) setRole: (id<OwlSurfaceRole>) newRole;

- (void) setPendingGeometry: (NSRect) geometry;

- (NSSize) geometrySizeAdjustements;

@end
