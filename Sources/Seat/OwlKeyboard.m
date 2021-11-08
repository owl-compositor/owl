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

#import "OwlKeyboard.h"
#import <xkbcommon/xkbcommon.h>
#import <fcntl.h>
#import <unistd.h>
#import "OwlServer.h"
#import "OwlSurface.h"
#import "OwlFeatures.h"

#ifdef OWL_PLATFORM_APPLE
    #import <Carbon/Carbon.h>
#endif


@implementation OwlKeyboard

static NSMutableArray *keyboards;

+ (void) initialize {
    if (keyboards == nil) {
        keyboards = [[NSMutableArray alloc] initWithCapacity: 1];
    }
}

+ (OwlKeyboard *) keyboardForClient: (struct wl_client *) client {
    for (OwlKeyboard *keyboard in keyboards) {
        struct wl_resource *resource = keyboard->_resource;
        if (client == wl_resource_get_client(resource)) {
            return keyboard;
        }
    }
    return nil;
}

static void keyboard_destroy(struct wl_resource *resource) {
    OwlKeyboard *self = wl_resource_get_user_data(resource);
    [keyboards removeObjectIdenticalTo: self];
    [self release];
}

static void keyboard_release_handler(
    struct wl_client *client,
    struct wl_resource *resource
) {
    wl_resource_destroy(resource);
}

static const struct wl_keyboard_interface keyboard_impl = {
    .release = keyboard_release_handler
};

- (void) sendKeymap {
    NSString *path = [[NSBundle mainBundle] pathForResource: @"keymap"
                                                     ofType: @"xkb"];
    int fd = open([path fileSystemRepresentation], O_RDONLY);
    uint32_t len = lseek(fd, 0, SEEK_END);
    lseek(fd, 0, SEEK_SET);
    wl_keyboard_send_keymap(
        _resource,
        WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1,
        fd,
        len
    );
    close(fd);
}

- (id) initWithResource: (struct wl_resource *) resource {
    _resource = resource;
    [keyboards addObject: self];

    wl_resource_set_implementation(
        resource,
        &keyboard_impl,
        [self retain],
        keyboard_destroy
    );

    [self sendKeymap];

    return self;
}

- (struct wl_resource *) resource {
    return _resource;
}

#ifdef OWL_PLATFORM_APPLE
static const struct {
    unsigned short cocoaKeyCode;
    uint32_t xkbKeyCode;
} keymap[] = {
    {kVK_Escape, 1},

    {kVK_ANSI_1, 2},
    {kVK_ANSI_2, 3},
    {kVK_ANSI_3, 4},
    {kVK_ANSI_4, 5},
    {kVK_ANSI_5, 6},
    {kVK_ANSI_6, 7},
    {kVK_ANSI_7, 8},
    {kVK_ANSI_8, 9},
    {kVK_ANSI_9, 10},
    {kVK_ANSI_0, 11},

    {kVK_ANSI_Minus, 12},
    {kVK_ANSI_Equal, 13},
    {kVK_Delete, 14}, // backspace
    {kVK_Tab, 15},

    {kVK_ANSI_Q, 16},
    {kVK_ANSI_W, 17},
    {kVK_ANSI_E, 18},
    {kVK_ANSI_R, 19},
    {kVK_ANSI_T, 20},
    {kVK_ANSI_Y, 21},
    {kVK_ANSI_U, 22},
    {kVK_ANSI_I, 23},
    {kVK_ANSI_O, 24},
    {kVK_ANSI_P, 25},

    {kVK_ANSI_LeftBracket, 26},
    {kVK_ANSI_RightBracket, 27},
    {kVK_Return, 28}, // enter

    {kVK_ANSI_A, 30},
    {kVK_ANSI_S, 31},
    {kVK_ANSI_D, 32},
    {kVK_ANSI_F, 33},
    {kVK_ANSI_G, 34},
    {kVK_ANSI_H, 35},
    {kVK_ANSI_J, 36},
    {kVK_ANSI_K, 37},
    {kVK_ANSI_L, 38},

    {kVK_ANSI_Semicolon, 39},
    {kVK_ANSI_Quote, 40},
    {kVK_ANSI_Grave, 41},
    {kVK_ANSI_Backslash, 43},

    {kVK_ANSI_Z, 44},
    {kVK_ANSI_X, 45},
    {kVK_ANSI_C, 46},
    {kVK_ANSI_V, 47},
    {kVK_ANSI_B, 48},
    {kVK_ANSI_N, 49},
    {kVK_ANSI_M, 50},

    {kVK_ANSI_Comma, 51},
    {kVK_ANSI_Period, 52},
    {kVK_ANSI_Slash, 53},
    {kVK_Space, 57},

    {kVK_F1, 59},
    {kVK_F2, 60},
    {kVK_F3, 61},
    {kVK_F4, 62},
    {kVK_F5, 63},
    {kVK_F6, 64},
    {kVK_F7, 65},
    {kVK_F8, 66},
    {kVK_F9, 67},
    {kVK_F10, 68},

    {kVK_F11, 87},
    {kVK_F12, 88},

    {kVK_Home, 102},
    {kVK_UpArrow, 103},
    {kVK_PageUp, 104},
    {kVK_LeftArrow, 105},
    {kVK_RightArrow, 106},
    {kVK_End, 107},
    {kVK_DownArrow, 108},
    {kVK_PageDown, 109},
    {kVK_ForwardDelete, 111}
};

- (uint32_t) xkbKeyCodeForCocoaKeyCode: (unsigned short) cocoaKeyCode {
    size_t keymap_size = sizeof(keymap) / sizeof(*keymap);
    for (size_t i = 0; i < keymap_size; i++) {
        if (keymap[i].cocoaKeyCode == cocoaKeyCode) {
            return keymap[i].xkbKeyCode;
        }
    }
    return 0;
}

#else /* OWL_PLATFORM_APPLE */

- (uint32_t) xkbKeyCodeForCocoaKeyCode: (unsigned short) keyCode {
    static const struct {
        unsigned short from, to;
        uint32_t base;
    } translations[] = {
        {10, 22, 2},
        {24, 35, 16},
        {38, 48, 30},
        {52, 61, 44},
        {65, 65, 57},
        {36, 36, 28}
    };
    size_t translations_size = sizeof(translations) / sizeof(translations[0]);

    for (size_t i = 0; i < translations_size; i++) {
        if (keyCode >= translations[i].from && keyCode <= translations[i].to) {
            return keyCode - translations[i].from + translations[i].base;
        }
    }
    return keyCode;
}


#endif /* OWL_PLATFORM_APPLE */

- (void) sendKey: (unsigned short) keyCode isPressed: (BOOL) isPressed {
    enum wl_keyboard_key_state state = isPressed
        ? WL_KEYBOARD_KEY_STATE_PRESSED
        : WL_KEYBOARD_KEY_STATE_RELEASED;

    wl_keyboard_send_key(
        _resource,
        [[OwlServer sharedServer] nextSerial],
        [OwlServer timestamp],
        [self xkbKeyCodeForCocoaKeyCode: keyCode],
        state
    );
}

- (void) sendModifiers: (uint32_t) modifiers {
    uint32_t serial = [[OwlServer sharedServer] nextSerial];
    wl_keyboard_send_modifiers(_resource, serial, modifiers, 0, 0, 0);
}

- (void) sendEnterSurface: (OwlSurface *) surface {
    uint32_t serial = [[OwlServer sharedServer] nextSerial];
    struct wl_array keys;
    wl_array_init(&keys);
    wl_keyboard_send_enter(_resource, serial, [surface resource], &keys);
    wl_array_release(&keys);
}

- (void) sendLeaveSurface: (OwlSurface *) surface {
    uint32_t serial = [[OwlServer sharedServer] nextSerial];
    wl_keyboard_send_leave(_resource, serial, [surface resource]);
}

@end
