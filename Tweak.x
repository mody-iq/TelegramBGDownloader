#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

%hook UIApplication

- (void)applicationDidEnterBackground:(UIApplication *)application {
    %orig;
    
    // Start a background task to prevent the app from suspending immediately
    // This gives Telegram extra time to finish active downloads
    __block UIBackgroundTaskIdentifier bgTask = UIBackgroundTaskInvalid;
    bgTask = [application beginBackgroundTaskWithName:@"TelegramBGDownloaderTask" expirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

%end

%ctor {
    %init;
}
