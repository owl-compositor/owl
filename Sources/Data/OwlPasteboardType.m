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

#import "OwlPasteboardType.h"
#import "OwlFeatures.h"


@implementation OwlPasteboardType

static NSArray *extraTextTypes;

+ (void) initialize {
    if (extraTextTypes == nil) {
        extraTextTypes = [[NSArray alloc] initWithObjects:
            @"TEXT",
            @"STRING",
            @"UTF8_STRING",
            nil
        ];
    }
}

- (id) initWithMimeType: (NSString *) type {
    _mimeType = [type retain];
    return self;
}

- (id) initWithUTI: (NSString *) UTI {
    _uti = [UTI retain];
    return self;
}

- (void) dealloc {
    [_mimeType release];
    [_uti release];
    [super dealloc];
}

- (NSString *) mimeType {
    if (_mimeType == nil) {
        if ([_uti isEqual: NSStringPboardType]) {
            _mimeType = [@"text/plain" retain];
        } else if ([_uti isEqual: @"public.utf8-plain-text"]) {
            _mimeType = [@"text/plain;charset=utf-8" retain];
        } else {
#ifdef OWL_PLATFORM_APPLE
            _mimeType = (NSString *) UTTypeCopyPreferredTagWithClass(
                (CFStringRef) _uti,
                kUTTagClassMIMEType
            );
#else
            _mimeType = [_uti retain];
#endif
        }
    }

    return _mimeType;
}

- (NSString *) UTI {
    if (_uti == nil) {
        if (
            [_mimeType hasPrefix: @"text/plain"] ||
            [extraTextTypes containsObject: _mimeType]
        ) {
            _uti = [NSStringPboardType retain];
        } else {
#ifdef OWL_PLATFORM_APPLE
            _uti = (NSString *) UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassMIMEType,
                (CFStringRef) _mimeType,
                NULL
            );
#else
            _uti = [_mimeType retain];
#endif
        }
    }

    return _uti;
}

- (BOOL) isText {
    NSString *m = [self mimeType];
    return [m hasPrefix: @"text/"] || [extraTextTypes containsObject: m];
}

@end
