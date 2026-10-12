#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

// Forward declaration for SpringBoard private classes
@interface FBProcess : NSObject
@property (nonatomic, retain) NSString *bundleIdentifier;
- (void)setState:(NSInteger)state;
@end

// ==========================================
// Group 1: SpringBoard Anti-Suspension
// ==========================================
%group SpringBoardHooks

%hook FBProcess
- (void)setState:(NSInteger)state {
    // Prevent Telegram from being suspended or terminated by the system
    if ([self.bundleIdentifier isEqualToString:@"ph.telegra"] && state >= 4) {
        return; 
    }
    %orig;
}
%end

%end // End SpringBoardHooks

// ==========================================
// Group 2: Telegram App Background Extension
// ==========================================
%group TelegramHooks

@interface UIApplication (TelegramBGDownloader)
- (void)extendBackgroundTask:(UIApplication *)application;
- (void)startSilentAudio;
@end

%hook UIApplication

- (void)applicationDidEnterBackground:(UIApplication *)application {
    %orig;
    [self extendBackgroundTask:application];
    [self startSilentAudio];
}

%new
- (void)extendBackgroundTask:(UIApplication *)application {
    __block UIBackgroundTaskIdentifier bgTask = UIBackgroundTaskInvalid;
    bgTask = [application beginBackgroundTaskWithName:@"TelegramBGDownloader_KeepAlive" expirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        [self extendBackgroundTask:application];
    }];
}

%new
- (void)startSilentAudio {
    // Create a silent audio session and player to keep the app alive
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    [audioSession setActive:YES error:nil];

    // Minimal silent WAV file header (44 bytes)
    NSData *silentAudioData = [NSData dataWithBytes:"\x52\x49\x46\x46\x24\x08\x00\x00\x57\x41\x56\x45\x66\x6d\x74\x20\x10\x00\x00\x00\x01\x00\x01\x00\x44\xac\x00\x00\x88\x58\x01\x00\x02\x00\x10\x00\x64\x61\x74\x61\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00" length:44];
    
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithData:silentAudioData error:nil];
    audioPlayer.numberOfLoops = -1; // Loop forever
    [audioPlayer play];
    
    // Retain the audio player using associated object to prevent deallocation
    objc_setAssociatedObject(self, "TelegramBGDownloaderAudioPlayer", audioPlayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end

%end // End TelegramHooks

// ==========================================
// Constructor: Conditional Initialization
// ==========================================
%ctor {
    NSBundle *currentBundle = [NSBundle mainBundle];
    NSString *bundleID = [currentBundle bundleIdentifier];
    
    if ([bundleID isEqualToString:@"ph.telegra"]) {
        %init(TelegramHooks);
    } else if ([bundleID isEqualToString:@"com.apple.springboard"]) {
        %init(SpringBoardHooks);
    }
}
