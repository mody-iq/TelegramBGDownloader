#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Forward declaration for SpringBoard private classes
@interface FBProcess : NSObject
@property (nonatomic, retain) NSString *bundleIdentifier;
- (void)setState:(NSInteger)state;
@end

%hook FBProcess

- (void)setState:(NSInteger)state {
    // Prevent Telegram from being suspended or terminated by the system
    // States >= 4 typically represent Suspended or NotRunning states in iOS
    if ([self.bundleIdentifier isEqualToString:@"ph.telegra"] && state >= 4) {
        return; 
    }
    %orig;
}

%end

%ctor {
    %init;
}
