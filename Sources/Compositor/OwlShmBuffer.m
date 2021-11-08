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

#import "OwlShmBuffer.h"
#import "OwlFeatures.h"


@implementation OwlShmBuffer

#ifdef OWL_PLATFORM_APPLE

- (CGBitmapInfo) bitmapInfoForWlShmFormat: (enum wl_shm_format) shmFormat {
    switch (shmFormat) {
    case WL_SHM_FORMAT_XRGB8888:
        return kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little;
    case WL_SHM_FORMAT_ARGB8888:
        return kCGImageAlphaFirst | kCGBitmapByteOrder32Little;
    default:
        NSLog(@"Unknown shm format");
        return 0;
    }
}

static void dataReleaseCallback(void *info, const void *data, size_t size) {
    free((void *) data);
}

#endif /* OWL_PLATFORM_APPLE */

- (void) releaseImage {
#ifdef OWL_PLATFORM_APPLE
    if (_image != NULL) {
        CGImageRelease(_image);
        _image = NULL;
    }
#else
    [_rep release];
    _rep = nil;
#endif
}

- (void) invalidate {
    [self releaseImage];

    enum wl_shm_format format = wl_shm_buffer_get_format(_buffer);
    size_t width = wl_shm_buffer_get_width(_buffer);
    size_t height = wl_shm_buffer_get_height(_buffer);
    size_t stride = wl_shm_buffer_get_stride(_buffer);
    void *data = wl_shm_buffer_get_data(_buffer);
    size_t size = height * stride;

#ifdef OWL_PLATFORM_APPLE
    CGBitmapInfo bitmapInfo = [self bitmapInfoForWlShmFormat: format];

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    void *dataCopy = malloc(size);
    wl_shm_buffer_begin_access(_buffer);
    memcpy(dataCopy, data, size);
    wl_shm_buffer_end_access(_buffer);
    [self sendRelease];

    CGDataProviderRef provider = CGDataProviderCreateWithData(
        NULL,
        dataCopy,
        size,
        dataReleaseCallback
    );
    _image = CGImageCreate(
        width,
        height,
        8,  // bitsPerComponent
        32,  // bitsPerPixel
        stride,
        colorSpace,
        bitmapInfo,
        provider,
        NULL,  // decode
        YES,  // shouldInterpolate
        kCGRenderingIntentDefault
    );
    CGDataProviderRelease(provider);

    CGColorSpaceRelease(colorSpace);
#else /* OWL_PLATFORM_APPLE */
    BOOL hasAlpha = format == WL_SHM_FORMAT_ARGB8888;
    size_t samplesPerPixel = hasAlpha ? 4 : 3;
    size_t destStride = samplesPerPixel * width;

    _rep = [NSBitmapImageRep alloc];
    _rep = [_rep initWithBitmapDataPlanes: NULL
                               pixelsWide: width
                               pixelsHigh: height
                            bitsPerSample: 8
                          samplesPerPixel: samplesPerPixel
                                 hasAlpha: hasAlpha
                                 isPlanar: NO
                           colorSpaceName: NSCalibratedRGBColorSpace
                             bitmapFormat: 0
                              bytesPerRow: destStride
                             bitsPerPixel: 8 * samplesPerPixel];

    void *destData = [_rep bitmapData];
    wl_shm_buffer_begin_access(_buffer);

    struct bgra {
        unsigned char b, g, r, a;
    };
    struct rgba {
        unsigned char r, g, b, a;
    };

    for (size_t row = 0; row < height; row++) {
        for (size_t col = 0; col < width; col++) {
            struct bgra *source = data + row * stride + col * 4;
            struct rgba *dest = destData + row * destStride + col * samplesPerPixel;
            dest->r = source->r;
            dest->g = source->g;
            dest->b = source->b;
            if (hasAlpha) {
                dest->a = source->a;
            }
        }
    }

    wl_shm_buffer_end_access(_buffer);
    [self sendRelease];
#endif /* OWL_PLATFORM_APPLE */
}

- (id) initWithResource: (struct wl_resource *) resource {
    self = [super initWithExternallyImplementedResource: resource];

    _buffer = wl_shm_buffer_get(resource);
    if (_buffer == NULL) {
        [NSException raise: NSInternalInconsistencyException
                    format: @"wl_shm_buffer_get(wl_buffer@%u) == NULL",
                            wl_resource_get_id(resource)];
        return nil;
    }

    return self;
}

- (void) dealloc {
    [self releaseImage];
    [super dealloc];
}

- (NSSize) size {
    size_t width = wl_shm_buffer_get_width(_buffer);
    size_t height = wl_shm_buffer_get_height(_buffer);
    return NSMakeSize(width, height);
}

- (void) drawInRect: (NSRect) rect {
#ifdef OWL_PLATFORM_APPLE
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextDrawImage(context, rect, _image);
#else
    [_rep drawInRect: rect
            fromRect: rect
           operation: NSCompositeSourceOver
            fraction: 1.0
      respectFlipped: NO
               hints: nil];
#endif
}

@end
