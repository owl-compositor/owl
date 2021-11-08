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

#import "OwlFeatures.h"
#ifdef OWL_PLATFORM_APPLE

#import "OwlIOSurfaceBuffer.h"
#import <OpenGL/gl.h>
#import <OpenGL/CGLIOSurface.h>


@implementation OwlIOSurfaceBuffer

- (id) initWithResource: (struct wl_resource *) resource
            surfacePort: (mach_port_t) surfacePort
{
    self = [super initWithResource: resource];
    _surface = IOSurfaceLookupFromMachPort(surfacePort);
    return self;
}

- (void) dealloc {
    IOSurfaceDecrementUseCount(_surface);
    [super dealloc];
}

- (void) invalidate {
    // ???
}

- (NSSize) size {
    size_t width = IOSurfaceGetWidth(_surface);
    size_t height = IOSurfaceGetHeight(_surface);
    return NSMakeSize(width, height);
}

- (BOOL) needsGLForRendering {
    return YES;
}

- (void) setupTextureWithCGLContext: (CGLContextObj) context {
    glGenTextures(1, &_tex);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _tex);

    size_t width = IOSurfaceGetWidth(_surface);
    size_t height = IOSurfaceGetHeight(_surface);

    CGLTexImageIOSurface2D(
        context,
        GL_TEXTURE_RECTANGLE_ARB,  // target
        GL_RGBA,  // internal_format
        width,
        height,
        GL_BGRA,  // format
        GL_UNSIGNED_INT_8_8_8_8_REV,  // type
        _surface,
        0  // plane
    );

    glTexParameteri(
        GL_TEXTURE_RECTANGLE_ARB,
        GL_TEXTURE_MIN_FILTER,
        GL_LINEAR
    );
    glTexParameteri(
        GL_TEXTURE_RECTANGLE_ARB,
        GL_TEXTURE_MAG_FILTER,
        GL_LINEAR
    );
    glTexParameteri(
        GL_TEXTURE_RECTANGLE_ARB,
        GL_TEXTURE_WRAP_S,
        GL_CLAMP_TO_EDGE
    );
    glTexParameteri(
        GL_TEXTURE_RECTANGLE_ARB,
        GL_TEXTURE_WRAP_T,
        GL_CLAMP_TO_EDGE
    );
}

- (void) drawInRect: (NSRect) rect {
    glViewport(0, 0, rect.size.width, rect.size.height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, rect.size.width, 0, rect.size.height, -1, 1);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    struct {
        GLfloat x, y;
    } coord[4] = {
        {0, 0},
        {rect.size.width, 0},
        {0, rect.size.height},
        {rect.size.width, rect.size.height}
    };

    glEnable(GL_TEXTURE_RECTANGLE_ARB);

    NSOpenGLContext *currentContext = [NSOpenGLContext currentContext];
    [self setupTextureWithCGLContext: [currentContext CGLContextObj]];

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    glPushMatrix();
    glTexCoordPointer(2, GL_FLOAT, 0, coord);
    glVertexPointer(2, GL_FLOAT, 0, coord);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glPopMatrix();

    glFlush();
}

- (void) notifyDetached {
    [self sendRelease];
}

@end

#endif /* OWL_PLATFORM_APPLE */
