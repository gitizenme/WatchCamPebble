//
//  SnapWatchAppDelegate.m
//  SnapWatch
//
//  Created by Joe Chavez on 7/10/13.
//  Copyright (c) 2013 izen.me. All rights reserved.
//

#import "SnapWatchDebug.h"
#import "SnapWatchSettings.h"
#import "SnapWatchAppDelegate.h"
#import "SnapWatchViewController.h"


#define PUSH_MSG_ALERT 1
// {"badge":"1","alert":"Flash update..., read it?","sound":"default","messageId":"1"}

#define PUSH_MSG_WATCH_APP_UPDATED 2
// {"badge":"1","alert":"Version 1.1. available, install?","sound":"default","messageId":"2"}

#define PUSH_MSG_IOS_APP_UPDATE_COMING 3
// {"badge":"1","alert":"Version 1.1 in app review, learn more?","sound":"default","messageId":"3"}

#define PUSH_MSG_NEW_BLOG_POST 4
// {"badge":"1","alert":"New blog post, want to read it?","sound":"default","messageId":"4"}


@implementation SnapWatchAppDelegate

int messageId = 0;

- (void)handlePushNotification:(NSDictionary*)notification application:(UIApplication*)application remote:(bool)isRemote inactive:(bool)inactive
{
    DebugLog(@"BEGIN");
// {"badge":1, "sound":"default", "alert":"Testing", "messageId":1}
    
    
    //    application.applicationIconBadgeNumber -= 1;
    
    NSDictionary *aps = [notification valueForKey:@"aps"];
    NSString *message = [aps valueForKey:@"alert"];
    NSNumber *badge = [aps valueForKey:@"badge"];
//    NSString *sound = [aps valueForKey:@"sound"];
    NSNumber *messageIdValue = [notification valueForKey:@"messageId"];

    application.applicationIconBadgeNumber = [badge intValue]-1;
    

    messageId = 0;
    if(messageIdValue != nil) {
        messageId = messageIdValue.intValue;
    }

    NSString *title = @"Pebble Snap";
    NSString *cancelButtonTitle = @"Cancel";
    NSString *otherButtonTitles = @"Okay";
    
    
    
    
    switch (messageId) {
        case PUSH_MSG_ALERT:
            title = @"Alert!";
            otherButtonTitles = @"Read it";
            cancelButtonTitle = @"Close";
            break;
            
        case PUSH_MSG_WATCH_APP_UPDATED:
            title = @"Watch App Update Avilable";
            otherButtonTitles = @"Install";
            cancelButtonTitle = @"No";
            break;
            
        case PUSH_MSG_IOS_APP_UPDATE_COMING:
            title = @"iOS App Update Coming";
            otherButtonTitles = @"Yes";
            cancelButtonTitle = @"No";
            break;
            
        case PUSH_MSG_NEW_BLOG_POST:
            title = @"New Blog Post";
            otherButtonTitles = @"Read it";
            cancelButtonTitle = @"No";
            break;
            
        default:
            break;
    }

    if(messageId > 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles, nil];
        [alertView show];
    }

}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    DebugLog(@"BEGIN");
//    [Flurry logEvent:[NSString stringWithFormat:@"messageId for notification %d", buttonIndex]];

    if (buttonIndex == 1) // Yes, do the action corresponding to messageId
    {
        SnapWatchViewController* mainController = (SnapWatchViewController *)  self.window.rootViewController;
        NSURL *url = nil;
        switch (messageId) {
            case PUSH_MSG_ALERT:
                url = [NSURL URLWithString:@"http://izen.me/tag/pebble-snap-alerts/"];
                break;
                
            case PUSH_MSG_WATCH_APP_UPDATED:
                url = [NSURL URLWithString:@"http://izen.me/tag/watch-app-updates/"];
                [mainController processWatchAppInstall];
                break;
                
            case PUSH_MSG_IOS_APP_UPDATE_COMING:
                url = [NSURL URLWithString:@"http://izen.me/tag/pebble-snap-updates/"];
                break;
            
            case PUSH_MSG_NEW_BLOG_POST:
                url = [NSURL URLWithString:@"http://izen.me/tag/pebble-snap-blog-posts/"];
                break;
                
            default:
                break;
     
        }
        if(url != nil) {
            if (![[UIApplication sharedApplication] openURL:url])
                DebugLog(@"%@%@",@"Failed to open url:",[url description]);
        }

    }
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    DebugLog(@"BEGIN");
    
//    DebugLog(@"Loaded setting: %s, value: %@, default value: %s", SETTING_USERNAME, username, kbUsername);
//    DebugLog(@"Loaded setting: %s, value: %@, default value: %s", SETTING_USERID, userId, kbUserId);
//    DebugLog(@"Loaded setting: %s, value: %@, default value: %s", SETTING_SESSIONID, sessionId, kbSessionId);
//    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_FLASH_MODE, flashMode, kbFlashModeDefault);
//    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_SELF_TIMER_SECONDS, selfTimerSeconds, kbSelfTimerSecondsDefault);
//    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_ADD_LOCATION_TO_PHOTOS, addLocationDataToPhotos, kbAddLocationDataToPhotosKeyDefault);
//    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_FIRST_TIME_USE, firstTimeUse, kbFirstTimeUseDefault);
//    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_ALREADY_INSTALLED_WATCH_APP, alreadyInstallWatchApp, kbAlreadyInstallWatchApp);
//    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_REMIND_CONNECT_WATCH_APP, remindStartWatchApp, kbRemindStartWatchApp);
//    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_REMIND_START_WATCH_APP, askUserToConnectPebbleWatchApp, kbAskUserToConnectPebbleWatchApp);
//    DebugLog(@"LOADED setting: %s, value: %d, default value: %d", SETTING_KEEPSCREENON, keepScreenOn, kbKeepScreenOn);
    
    
    NSDictionary *appDefaults = @{
                                  @SETTING_USERNAME: @kbUsername,
                                   @SETTING_USERID: @kbUserId,
                                   @SETTING_SESSIONID: @kbSessionId,
                                   @SETTING_PWD: @kbPwd,
                                   @SETTING_FLASH_MODE: [NSNumber numberWithInt:kbFlashModeDefault],
                                   @SETTING_SELF_TIMER_SECONDS: [NSNumber numberWithInt:kbSelfTimerSecondsDefault],
                                   @SETTING_ADD_LOCATION_TO_PHOTOS: [NSNumber numberWithBool:kbAddLocationDataToPhotosKeyDefault],
                                   @SETTING_FIRST_TIME_USE: [NSNumber numberWithBool:kbFirstTimeUseDefault],
                                   @SETTING_ALREADY_INSTALLED_WATCH_APP: [NSNumber numberWithBool:kbAlreadyInstallWatchApp],
                                   @SETTING_REMIND_CONNECT_WATCH_APP: [NSNumber numberWithBool:kbAskUserToConnectPebbleWatchApp],
                                   @SETTING_REMIND_START_WATCH_APP: [NSNumber numberWithBool:kbRemindStartWatchApp],
                                   @SETTING_KEEPSCREENON: [NSNumber numberWithBool:kbKeepScreenOn],
                                   @SETTING_FOLLOWONTWITTER: [NSNumber numberWithBool:kbFollowedOnTwitter],
                                   @SETTING_VIBRATE_WATCH: [NSNumber numberWithBool:kbVibrateWatch],
                                   @SETTING_TAP_MODE: [NSNumber numberWithBool:kbTapMode],
                                   @SETTING_CAMERA_PREVIEW: [NSNumber numberWithBool:kbCameraPreview]
                                   };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];

//    SnapWatchViewController* mainController = (SnapWatchViewController *)  self.window.rootViewController;
//    [mainController loadSettings];

    return YES;
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    DebugLog(@"BEGIN");
    
}



- (void)applicationWillResignActive:(UIApplication *)application
{
    DebugLog(@"BEGIN");
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    SnapWatchViewController* mainController = (SnapWatchViewController *)  self.window.rootViewController;
    [mainController disconnectWatch];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    DebugLog(@"BEGIN");
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    DebugLog(@"BEGIN");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    DebugLog(@"BEGIN");
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    SnapWatchViewController* mainController = (SnapWatchViewController *)  self.window.rootViewController;
    [mainController loadSettings];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    DebugLog(@"BEGIN");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    SnapWatchViewController* mainController = (SnapWatchViewController *)  self.window.rootViewController;
    [mainController disconnectWatch];
}

@end
