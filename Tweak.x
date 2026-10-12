#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIApplication (TelegramBGDownloader)
- (void)extendBackgroundTask:(UIApplication *)application;
@end

%hook UIApplication

- (void)applicationDidEnterBackground:(UIApplication *)application {
    %orig;
    [self extendBackgroundTask:application];
}

%new
- (void)extendBackgroundTask:(UIApplication *)application {
    __block UIBackgroundTaskIdentifier bgTask = UIBackgroundTaskInvalid;
    bgTask = [application beginBackgroundTaskWithName:@"TelegramBGDownloader_KeepAlive" expirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
        // Restart the task recursively to keep the app alive in the background
        [self extendBackgroundTask:application];
    }];
}

%end

%ctor {
    %init;
}
