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

#import "OwlXdgToplevel.h"
#import "OwlSurface.h"
#import "OwlXdgSurface.h"
#import "OwlServer.h"
#import "OwlKeyboard.h"
#import "OwlWlDataDevice.h"
#import "xdg-shell.h"
#import <wayland-server.h>


@implementation OwlXdgToplevel

static void xdg_toplevel_destroy(struct wl_resource *resource) {
    OwlXdgToplevel *self = wl_resource_get_user_data(resource);
    [self->_window close];
    [self release];
}

static void xdg_toplevel_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static void xdg_toplevel_set_parent_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    struct wl_resource *parent_resource
) {
    // TODO
}

static void xdg_toplevel_set_title_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    const char *raw_title
) {
    OwlXdgToplevel *self = wl_resource_get_user_data(resource);
    [self->_window setTitle: [NSString stringWithUTF8String: raw_title]];
}

static void xdg_toplevel_set_app_id_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    const char *raw_app_id
) {
    // Do nothing.
}

static void xdg_toplevel_move_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    struct wl_resource *seat_resource,
    uint32_t serial
) {
    OwlXdgToplevel *self = wl_resource_get_user_data(resource);
    [[self->_window window] runInteractiveMove];
}

static void xdg_toplevel_set_max_size_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    int32_t width,
    int32_t height
) {
    // TODO
}

static void xdg_toplevel_set_min_size_handler(
    struct wl_client *client,
    struct wl_resource *resource,
    int32_t width,
    int32_t height
) {
    // TODO
}

static void xdg_toplevel_set_minimized_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    OwlXdgToplevel *self = wl_resource_get_user_data(resource);
    [self->_window minimize];
}

static void xdg_toplevel_set_maximized_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    OwlXdgToplevel *self = wl_resource_get_user_data(resource);
    [self->_window maximize];
}

static void xdg_toplevel_unset_maximized_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    OwlXdgToplevel *self = wl_resource_get_user_data(resource);
    [self->_window unmaximize];
}

static const struct xdg_toplevel_interface xdg_toplevel_impl = {
    .destroy = xdg_toplevel_destroy_handler,
    .set_parent = xdg_toplevel_set_parent_handler,
    .set_title = xdg_toplevel_set_title_handler,
    .set_app_id = xdg_toplevel_set_app_id_handler,
    .move = xdg_toplevel_move_handler,
    .set_max_size = xdg_toplevel_set_max_size_handler,
    .set_min_size = xdg_toplevel_set_min_size_handler,
    .set_minimized = xdg_toplevel_set_minimized_handler,
    .set_maximized = xdg_toplevel_set_maximized_handler,
    .unset_maximized = xdg_toplevel_unset_maximized_handler
    // TODO
};

- (id) initWithResource: (struct wl_resource *) resource
                surface: (OwlSurface *) surface
             xdgSurface: (OwlXdgSurface *) xdgSurface
{
    _resource = resource;
    _surface = [surface retain];
    _xdgSurface = xdgSurface;

    [surface setRole: self];
    _window = [OwlWindowWrapper new];
    [_window setView: surface];
    [_window setWindowDelegate: self];

    wl_resource_set_implementation(
        resource,
        &xdg_toplevel_impl,
        [self retain],
        xdg_toplevel_destroy
    );

    return self;
}

- (void) dealloc {
    [_surface release];
    [_window release];
    [super dealloc];
}

- (struct wl_array) makeStates {
    struct wl_array states;
    wl_array_init(&states);

#define append(condition, value)                    \
    if (condition) {                                \
        void *ptr = wl_array_add(                   \
            &states,                                \
            sizeof(enum xdg_toplevel_state)         \
        );                                          \
        *(enum xdg_toplevel_state *) ptr = (value); \
    } else

    append(_activated, XDG_TOPLEVEL_STATE_ACTIVATED);
    append(_fullscreen, XDG_TOPLEVEL_STATE_FULLSCREEN);
    append(_resizing, XDG_TOPLEVEL_STATE_RESIZING);
    append(_maximized, XDG_TOPLEVEL_STATE_MAXIMIZED);

#undef append

    return states;
}

- (void) sendConfigureWithSize: (NSSize) size {
    struct wl_array states = [self makeStates];
    xdg_toplevel_send_configure(
        _resource,
        size.width,
        size.height,
        &states
    );
    [_xdgSurface sendConfigure];
    wl_array_release(&states);
    _configured = YES;
    [[OwlServer sharedServer] flushClientsLater];
}

- (OwlKeyboard *) keyboard {
    struct wl_client *client = wl_resource_get_client(_resource);
    return [OwlKeyboard keyboardForClient: client];
}

- (OwlWlDataDevice *) dataDevice {
    struct wl_client *client = wl_resource_get_client(_resource);
    return [OwlWlDataDevice dataDeviceForClient: client];
}

- (uint32_t) serial {
    struct wl_client *client = wl_resource_get_client(_resource);
    struct wl_display *display = wl_client_get_display(client);
    return wl_display_next_serial(display);
}

- (void) map {
    [self update];
    [_window map];
}

- (void) unmap {
    if (!_configured) {
        [self sendConfigureWithSize: NSZeroSize];
        return;
    }
    [_window unmap];
}

- (void) update {
    [_window setContentSize: [_surface bounds].size];
}

- (void) windowDidResize: (NSNotification *) notification {
    NSWindow *w = [notification object];
    _maximized = NO; // [w isZoomed];
    NSRect frame = [w frame];
    NSSize s = [w contentRectForFrameRect: frame].size;
    s = [_xdgSurface geometrySizeForBufferSize: s];
    [self sendConfigureWithSize: s];
}

- (BOOL) windowShouldClose: (NSWindow *) w {
    xdg_toplevel_send_close(_resource);
    [[OwlServer sharedServer] flushClientsLater];
    return NO;
}

- (void) windowWillClose: (NSNotification *) notification {
    // Unsubscribe so we don't get didResignMain.
    [_window setWindowDelegate: nil];
}

- (void) windowDidBecomeMain: (NSNotification *) notification {
    _activated = YES;
    [self sendConfigureWithSize: NSZeroSize];
}

- (void) windowDidResignMain: (NSNotification *) notification {
    _activated = NO;
    [self sendConfigureWithSize: NSZeroSize];
}

- (void) windowDidBecomeKey: (NSNotification *) notification {
    [[self keyboard] sendEnterSurface: _surface];
    [[self dataDevice] focused];
    [[OwlServer sharedServer] flushClientsLater];
}

- (void) windowDidResignKey: (NSNotification *) notification {
    [[self keyboard] sendLeaveSurface: _surface];
    [[self dataDevice] unfocused];
    [[OwlServer sharedServer] flushClientsLater];
}

@end
