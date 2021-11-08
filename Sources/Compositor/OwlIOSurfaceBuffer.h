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

#import "OwlBuffer.h"
#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>


@interface OwlIOSurfaceBuffer : OwlBuffer {
    IOSurfaceRef _surface;
    GLuint _tex;
}

- (id) initWithResource: (struct wl_resource *) resource
            surfacePort: (mach_port_t) surfacePort;

@end

#endif /* OWL_PLATFORM_APPLE */
