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

#import "OwlBuffer.h"
#import "OwlShmBuffer.h"


@implementation OwlBuffer

static NSMutableArray *buffers;

+ (void) initialize {
    if (buffers == nil) {
        buffers = [NSMutableArray new];
    }
}

static void buffer_destroy(struct wl_resource *resource) {
    OwlBuffer *self = wl_resource_get_user_data(resource);
    [self release];
}

static void buffer_destroy_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static const struct wl_buffer_interface buffer_impl = {
    .destroy = buffer_destroy_handler
};

- (id) initWithExternallyImplementedResource: (struct wl_resource *) resource {
    _resource = resource;
    [buffers addObject: self];
    return self;
}

- (id) initWithResource: (struct wl_resource *) resource {
    self = [self initWithExternallyImplementedResource: resource];
    wl_resource_set_implementation(
        resource,
        &buffer_impl,
        [self retain],
        buffer_destroy
    );
    return self;
}

- (void) dealloc {
    [buffers removeObject: self];
    [super dealloc];
}

+ (OwlBuffer *) bufferForResource: (struct wl_resource *) resource {
    if (resource == NULL) {
        return nil;
    }
    // All buffer factories register their resources with us immediately on creation,
    // except wl_shm, which is implemented outside of Owl (in wayland-server).
    for (OwlBuffer *buffer in buffers) {
        if (buffer->_resource == resource) {
            return buffer;
        }
    }
    return [[[OwlShmBuffer alloc] initWithResource: resource] autorelease];
}

- (void) invalidate {
    // Do nothing, subclasses may override this to recompute their data.
}

- (NSSize) size {
    // Subclasses need to override this.
    return NSZeroSize;
}

- (BOOL) needsGLForRendering {
    // Subclasses may override this if they need OpenGL.
    return NO;
}

- (void) drawInRect: (NSRect) rect {
    // Do nothing, subclasses override this.
}

- (void) sendRelease {
    wl_buffer_send_release(_resource);
}

- (void) notifyDetached {
    // This method is invoked when the buffer is detached from a surface,
    // The base implementation does nothing, subclasses may want to override
    // it and call [self sendRelease] if they don't already call that at a
    // different time.
}

@end
