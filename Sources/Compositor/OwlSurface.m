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

#import "OwlSurface.h"
#import "OwlCallback.h"
#import "OwlPointer.h"
#import "OwlKeyboard.h"
#import "OwlServer.h"
#import "OwlBuffer.h"
#import "OwlSurfaceState.h"
#import <wayland-server.h>
#import <Cocoa/Cocoa.h>


@implementation OwlSurface

- (struct wl_resource *) resource {
    return _resource;
}

static void surface_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static void surface_destroy(struct wl_resource *resource) {
    OwlSurface *self = wl_resource_get_user_data(resource);
    [self removeFromSuperview];
    [self release];
}

- (void) attachBuffer: (OwlBuffer *) buffer {
    [_pendingState setBuffer: buffer];
    [buffer invalidate];
}

static void surface_attach_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    struct wl_resource *buffer_resource,
    int32_t x,
    int32_t y
) {
    OwlSurface *self = wl_resource_get_user_data(resource);
    OwlBuffer *buffer = [OwlBuffer bufferForResource: buffer_resource];
    [self attachBuffer: buffer];
}

static void surface_damage_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height
) {
    OwlSurface *self = wl_resource_get_user_data(resource);
    NSRect rect = NSMakeRect(x, y, width, height);
    [self->_pendingState addDamage: rect];
}

- (void) setPendingGeometry: (NSRect) geometry {
    [_pendingState setGeometry: geometry];
}

- (NSSize) geometrySizeAdjustements {
    NSSize currentSize = [_currentState geometry].size;
    if (currentSize.width == 0) {
        return NSZeroSize;
    }

    NSSize res;

    res.width = [self frame].size.width - currentSize.width;
    res.height = [self frame].size.height - currentSize.height;

    return res;
}

- (void) setUpGL {
    NSOpenGLPixelFormatAttribute attrs[] = { 0 };
    NSOpenGLPixelFormat *format = [NSOpenGLPixelFormat alloc];
    format = [format initWithAttributes: attrs];
    _openGLContext = [[NSOpenGLContext alloc] initWithFormat: format
                                                shareContext: nil];
    [format release];
}

- (void) tearDownGL {
    [_openGLContext clearDrawable];
    [_openGLContext release];
    _openGLContext = nil;
    [NSOpenGLContext clearCurrentContext];
}

- (void) updateTrackingRect {
    if (_trackingRectTag != 0) {
        [self removeTrackingRect: _trackingRectTag];
    }
    _trackingRectTag = [self addTrackingRect: [self bounds]
                                       owner: self
                                    userData: NULL
                                assumeInside: NO];
}

- (void) commit {
    OwlBuffer *oldBuffer = [_currentState buffer];
    OwlBuffer *newBuffer = [_pendingState buffer];
    BOOL oldBufferNeedsGL = [oldBuffer needsGLForRendering];
    BOOL newBufferNeedsGL = [newBuffer needsGLForRendering];

    // We're going to "map" the surface if it wasn't
    // mapped previously and the new buffer is not nil.
    BOOL map = oldBuffer == nil && newBuffer != nil;
    // Conversely, we're going to unmap it if the new
    // buffer is actually nil. We're going to call
    // [role unmap] even if wasn't mapped; the roles
    // are expected to deal with it by e.g. sending
    // some sort of a configure event.
    BOOL unmap = newBuffer == nil;

    BOOL setUpGL = !oldBufferNeedsGL && newBufferNeedsGL;
    BOOL tearDownGL = oldBufferNeedsGL && !newBufferNeedsGL;
    BOOL damageAll = oldBufferNeedsGL != newBufferNeedsGL;

    if (setUpGL) {
        [self setUpGL];
    }

    if (oldBuffer != newBuffer) {
        [oldBuffer notifyDetached];
    }

    // Actually set the pending state as our new state.
    [_currentState release];
    _currentState = _pendingState;
    _pendingState = [OwlSurfaceState alloc];
    _pendingState = [_pendingState initWithPreviousState: _currentState];

    [_callbacks addObjectsFromArray: [_currentState callbacks]];

    if (tearDownGL) {
        [self tearDownGL];
    }

    if (unmap) {
        [_role unmap];
        // Nothing further to do, as we have no buffer.
        return;
    }

    if (!NSEqualSizes([self frame].size, [newBuffer size])) {
        [self setFrameSize: [newBuffer size]];
        [self updateTrackingRect];
    }

    if (map) {
        [_role map];
    } else {
        [_role update];
    }

    // Now, tell Cocoa to redraw this view.
    if (damageAll) {
        [self setNeedsDisplay: YES];
    } else {
        for (NSValue *value in [_currentState damage]) {
            NSRect rect = [value rectValue];
            rect.origin.y = [newBuffer size].height - rect.size.height - rect.origin.y;
            [self setNeedsDisplayInRect: rect];
        }
    }
}

static void surface_commit_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    OwlSurface *self = wl_resource_get_user_data(resource);
    [self commit];
}

- (void) drawRect: (NSRect) dirtyRect {
    // Ensure the GL context is set up correctly.
    // This has no effect if we're not using GL.
    [_openGLContext setView: self];
    [_openGLContext makeCurrentContext];

    [[_currentState buffer] drawInRect: [self bounds]];

    // We have painted; so send out all callbacks.
    uint32_t timestamp = [OwlServer timestamp];
    for (OwlCallback *callback in _callbacks) {
        [callback sendDoneWithData: timestamp];
    }
    [_callbacks removeAllObjects];

    [[self window] invalidateShadow];

    [[OwlServer sharedServer] flushClientsLater];
}

static void surface_set_opaque_region_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    struct wl_resource *region_resource
) {
    // TODO
}

static void surface_set_input_region_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    struct wl_resource *region_resource
) {
    // TODO
}

static void surface_set_buffer_scale_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    int32_t scale
) {
    // TODO
}

static void surface_set_buffer_transform_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    /* enum wl_output_transform */ int32_t transform
) {
    // TODO
}

static void surface_frame_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    uint32_t id
) {
    OwlSurface *self = wl_resource_get_user_data(resource);
    struct wl_resource *callback_resource = wl_resource_create(
        client,
        &wl_callback_interface,
        1,
        id
    );
    OwlCallback *callback = [[OwlCallback alloc] initWithResource: callback_resource];
    [self->_pendingState addCallback: callback];
    [callback release];
}

static const struct wl_surface_interface surface_interface = {
    .destroy = surface_destroy_handler,
    .attach = surface_attach_handler,
    .damage = surface_damage_handler,
    .commit = surface_commit_handler,
    .frame = surface_frame_handler,
    .set_opaque_region = surface_set_opaque_region_handler,
    .set_input_region = surface_set_input_region_handler,
    .set_buffer_scale = surface_set_buffer_scale_handler,
    .set_buffer_transform = surface_set_buffer_transform_handler
    // TODO
};

- (id) initWithResource: (struct wl_resource *) resource {
    self = [super initWithFrame: NSZeroRect];
    _resource = resource;
    wl_resource_set_implementation(
        resource,
        &surface_interface,
        [self retain],
        surface_destroy
    );
    _callbacks = [NSMutableArray new];
    _currentState = [OwlSurfaceState new];
    _pendingState = [OwlSurfaceState new];
    return self;
}

- (void) dealloc {
    [self tearDownGL];
    [_callbacks release];
    [_currentState release];
    [_pendingState release];
    [super dealloc];
}

- (id<OwlSurfaceRole>) role {
    return _role;
}

- (void) setRole: (id<OwlSurfaceRole>) newRole {
    _role = newRole;
}

- (OwlPointer *) pointer {
    struct wl_client *client = wl_resource_get_client(_resource);
    return [OwlPointer pointerForClient: client];
}

- (OwlKeyboard *) keyboard {
    struct wl_client *client = wl_resource_get_client(_resource);
    return [OwlKeyboard keyboardForClient: client];
}

- (NSPoint) pointOfEvent: (NSEvent *) event {
    NSPoint point = [event locationInWindow];
    point = [self convertPoint: point fromView: nil];
    point.y = [self bounds].size.height - point.y;
    return point;
}

- (void) mouseEntered: (NSEvent *) event {
    [[self window] setAcceptsMouseMovedEvents: YES];
    NSPoint point = [self pointOfEvent: event];
    if (!_mouseIsInside) {
        [[self pointer] sendEnterSurface: self atPoint: point];
        _mouseIsInside = YES;
    } else {
        // We believe the mouse to already be inside, and now
        // we get an enter event again. No need to send an enter
        // event to our client, but we do need to send the new
        // position, so fake a move event.
        [[self pointer] sendMotionAtPoint: point];
    }
    [[OwlServer sharedServer] flushClientsLater];
}

- (void) ensureMouseIsInside: (NSEvent *) event {
    if (!_mouseIsInside) {
        // We haven't been told the mouse is inside our view,
        // but apparently it is. Fake an enter event.
        [self mouseEntered: event];
    }
}

- (void) mouseMoved: (NSEvent *) event {
    NSPoint point = [self pointOfEvent: event];
    // See whether the mouse is really inside our view.
    // If it's outside our view, stop receiving mouse events.
    if (!NSPointInRect(point, [self bounds])) {
        [[self window] setAcceptsMouseMovedEvents: NO];
        return;
    }

    [self ensureMouseIsInside: event];
    [[self pointer] sendMotionAtPoint: point];
    [[OwlServer sharedServer] flushClientsLater];
}

- (void) mouseDragged: (NSEvent *) event {
    [self mouseMoved: event];
}

- (void) mouseExited: (NSEvent *) event {
    _mouseIsInside = NO;
    [[self window] setAcceptsMouseMovedEvents: NO];
    [[self pointer] sendLeaveSurface: self];
    [[OwlServer sharedServer] flushClientsLater];
}

- (void) mouseDown: (NSEvent *) event {
    [self ensureMouseIsInside: event];
    [[self pointer] sendButton: BTN_LEFT isPressed: YES];
    [[OwlServer sharedServer] flushClientsLater];
}

- (void) mouseUp: (NSEvent *) event {
    [self ensureMouseIsInside: event];
    [[self pointer] sendButton: BTN_LEFT isPressed: NO];
    [[OwlServer sharedServer] flushClientsLater];
}

- (void) rightMouseDown: (NSEvent *) event {
    [self ensureMouseIsInside: event];
    [[self pointer] sendButton: BTN_RIGHT isPressed: YES];
    [[OwlServer sharedServer] flushClientsLater];
}

- (void) rightMouseUp: (NSEvent *) event {
    [self ensureMouseIsInside: event];
    [[self pointer] sendButton: BTN_RIGHT isPressed: NO];
    [[OwlServer sharedServer] flushClientsLater];
}

- (void) rightMouseDragged: (NSEvent *) event {
    [self mouseMoved: event];
}

- (void) scrollWheel: (NSEvent *) event {
    [self ensureMouseIsInside: event];
    [[self pointer] sendScrollByX: [event deltaX] byY: [event deltaY]];
    [[OwlServer sharedServer] flushClientsLater];
}

- (BOOL) acceptsFirstResponder {
    return YES;
}

- (void) keyDown: (NSEvent *) event {
    [[self keyboard] sendKey: [event keyCode] isPressed: YES];
    [[OwlServer sharedServer] flushClientsLater];
}

- (void) keyUp: (NSEvent *) event {
    [[self keyboard] sendKey: [event keyCode] isPressed: NO];
    [[OwlServer sharedServer] flushClientsLater];
}

- (void) flagsChanged: (NSEvent *) event {
    NSUInteger flags = [event modifierFlags];
    BOOL shift = (flags & NSShiftKeyMask) ? YES : NO;
    BOOL ctrl = (flags & NSCommandKeyMask) ? YES : NO;
    BOOL alt = (flags & NSAlternateKeyMask) ? YES : NO;
    uint32_t mods = shift + ctrl * 4 + alt * 262152;
    [[self keyboard] sendModifiers: mods];
    [[OwlServer sharedServer] flushClientsLater];
}

@end
