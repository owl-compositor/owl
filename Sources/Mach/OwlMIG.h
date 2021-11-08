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
#import <mach/mach.h>
#import <dispatch/dispatch.h>



// From source_private.h

typedef boolean_t (*dispatch_mig_callback_t)(
    mach_msg_header_t *message,
    mach_msg_header_t *reply
);

extern mach_msg_return_t dispatch_mig_server(
    dispatch_source_t source,
    size_t max_message_size,
    dispatch_mig_callback_t callback
);


@interface OwlMIG : NSObject

+ (void) serveOnPort: (mach_port_t) port
       usingCallback: (dispatch_mig_callback_t) callback
             maxSize: (size_t) maxSize;

@end
