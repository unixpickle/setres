//
//  main.m
//  setres
//
//  Created by Alex Nichol on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

void listAllModes();
CFDictionaryRef CGDisplayModeGetDictionary(CGDisplayModeRef mode);
CGDisplayModeRef findDisplayMode(CGFloat width, CGFloat height, CGFloat scale, CGDirectDisplayID display);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc >= 2) {
            if (strcmp(argv[1], "--modes") == 0) {
                listAllModes();
                return 0;
            }
        }
        
        if (argc < 3) {
            fprintf(stderr, "usage: %s [--modes] <width> <height> [scale]\n", argv[0]);
            return 1;
        }
        
        CGFloat width = atof(argv[1]);
        CGFloat height = atof(argv[2]);
        CGFloat scale = 1;
        
        if (argc > 3) {
            scale = atof(argv[3]);
        }
                
        CGDirectDisplayID display = CGMainDisplayID();       
        CGDisplayModeRef mode = findDisplayMode(width, height, scale, display);
        if (!mode) {
            printf("error: no display mode was found...\n");
            return 1;
        }
        
        CGDisplayConfigRef config;
        if (CGBeginDisplayConfiguration(&config) == kCGErrorSuccess) {
            CGConfigureDisplayWithDisplayMode(config, display, mode, NULL);
            CGCompleteDisplayConfiguration(config, kCGConfigureForSession);
        }
        
        CGDisplayModeRelease(mode);
    }
    return 0;
}

void listAllModes() {
    CGDirectDisplayID display = CGMainDisplayID();
    CFArrayRef modes = CGDisplayCopyAllDisplayModes(display, NULL);
    for (int i = 0; i < CFArrayGetCount(modes); i++) {
        CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(modes, i);        
        CFDictionaryRef infoDict = CGDisplayModeGetDictionary(mode);
        CFNumberRef resolution = CFDictionaryGetValue(infoDict, CFSTR("kCGDisplayResolution"));
        float value;
        CFNumberGetValue(resolution, kCFNumberFloatType, &value);
        printf("mode: {resolution=%dx%d, scale = %.1f}\n", (int)CGDisplayModeGetWidth(mode),
               (int)CGDisplayModeGetHeight(mode), value);
    }
    CFRelease(modes);

}

CFDictionaryRef CGDisplayModeGetDictionary(CGDisplayModeRef mode) {
    CFDictionaryRef infoDict = ((CFDictionaryRef *)mode)[2]; // DIRTY, dirty, smelly, no good very bad hack
    return infoDict;
}

CGDisplayModeRef findDisplayMode(CGFloat width, CGFloat height, CGFloat scale, CGDirectDisplayID display) {
    CFArrayRef modes = CGDisplayCopyAllDisplayModes(display, NULL);
    for (int i = 0; i < CFArrayGetCount(modes); i++) {
        CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(modes, i);        
        if (CGDisplayModeGetWidth(mode) == width && CGDisplayModeGetHeight(mode) == height) {
            CFDictionaryRef infoDict = CGDisplayModeGetDictionary(mode);
            CFNumberRef resolution = CFDictionaryGetValue(infoDict, CFSTR("kCGDisplayResolution"));
            float value;
            CFNumberGetValue(resolution, kCFNumberFloatType, &value);
            if (value == scale) {
                CGDisplayModeRetain(mode);
                CFRelease(modes);
                return mode;
            }
        }
    }
    CFRelease(modes);
    return NULL;
}
