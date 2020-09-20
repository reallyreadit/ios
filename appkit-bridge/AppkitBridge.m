#import "AppkitBridge.h"

@import AppKit;

@implementation AppkitBridge

+ (void) removeFullSizeContentViewStyleMaskFromWindows
{
    NSArray *windows = NSApplication.sharedApplication.windows;
    
    for (NSWindow *window in windows) {
        window.styleMask &= ~NSWindowStyleMaskFullSizeContentView;
    }
}

@end
