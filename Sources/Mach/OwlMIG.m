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

#import "OwlMIG.h"


@implementation OwlMIG

+ (void) serveOnPort: (mach_port_t) port
       usingCallback: (dispatch_mig_callback_t)
    callback maxSize: (size_t) maxSize
{
    dispatch_source_t source = dispatch_source_create(
        DISPATCH_SOURCE_TYPE_MACH_RECV,
        port,
        0,
        dispatch_get_main_queue()
    );

    dispatch_source_set_event_handler(source, ^{
        dispatch_mig_server(source, maxSize, callback);
    });
    dispatch_resume(source);
}

@end
