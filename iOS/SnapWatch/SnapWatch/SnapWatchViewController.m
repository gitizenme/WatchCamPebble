//
//  SnapWatchViewController.m
//  SnapWatch
//
//  Created by Joe Chavez on 7/10/13.
//  Copyright (c) 2013 izen.me. All rights reserved.
//

#import "SnapWatchDebug.h"
#import "CameraPreviewImage.h"
#import "SnapWatchViewController.h"
#import "SnapWatchSettingsViewController.h"
#import "SnapWatchSettingsTableViewController.h"
#import "UIImage+Resizing.h"
#import "APLViewController.h"
#import "PebbleSnapMessageQueue.h"
#import "OverlayView.h"
#import <PebbleKit/PebbleKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>



@interface SnapWatchViewController () <PBPebbleCentralDelegate, SnapWatchSettingsTableViewControllerDelegate, SnapWatchSettingsViewControllerDelegate, APLViewControllerViewControllerDelegate>

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;

@end

@implementation SnapWatchViewController

@synthesize soundFileURLRef;
@synthesize soundFileObject;
@synthesize captureManager;
@synthesize username;
@synthesize userId;
@synthesize pwd;
@synthesize deviceToken;
@synthesize sessionId;

@synthesize overlayImageView;

PebbleSnapMessageQueue *messageQueue;
NSTimer *livePreviewTimer = nil;

CLLocationManager *locationManager;
CLLocation *currentLocation;
PBWatch *_targetWatch;
bool _isConnected = false;
bool _isAppMessagesSupported = false;
bool _usingFrontCamera = NO;
id _updateHandler = nil;
UIImage *lastImageCaptured;

AVCaptureFlashMode flashMode = kbFlashModeDefault;

float livePreviewTimerSeconds = kbLivePreviewTimerSecondsDefault;
int selfTimerSeconds = kbSelfTimerSecondsDefault;
bool addLocationDataToPhotos = kbAddLocationDataToPhotosKeyDefault;
bool firstTimeUse = kbFirstTimeUseDefault;
bool alreadyInstallWatchApp = kbAlreadyInstallWatchApp;
bool remindStartWatchApp = kbRemindStartWatchApp;
bool askUserToConnectPebbleWatchApp = kbAskUserToConnectPebbleWatchApp;
bool keepScreenOn = kbKeepScreenOn;
bool vibrateMode = kbVibrateWatch;
bool tapMode = kbTapMode;
bool livePreview = kbCameraPreview;
bool isMoveRecording = kbVideMode;


#pragma mark -
#pragma mark - UIActionSheetDelegate

UIActionSheet *askUserToInstallPebbleAppActionSheet;
UIActionSheet *askUserToOpenPebbleAppActionSheet;
UIActionSheet *askUserToConnectPebbleWatchActionSheet;

- (void)openPebbleAppInstallLocation:(NSString *)strUrl
{
    DebugLog(@"BEGIN");
    // https://dl.dropboxusercontent.com/u/122701/PebbleSnap/snapwatch.pbw
    
    NSURL *url = [NSURL URLWithString:strUrl];
    
    if (![[UIApplication sharedApplication] openURL:url])
        DebugLog(@"%@%@",@"Failed to open url:",[url description]);
}

-(void)processWatchAppInstall
{
    DebugLog(@"BEGIN");
    
//    NSURL *watchAppMetaUrl = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/122701/PebbleSnap/watch-ver.txt"];
//    NSString *urlFromRemote = [[NSString alloc] initWithContentsOfURL:watchAppMetaUrl encoding:NSUTF8StringEncoding error:&error];
    NSError *error;
    
    if(error == nil) {
        NSURL *url = [NSURL URLWithString:@"pebble://appstore/52cdb715aa4b651f4c00000b"];
        
        if (![[UIApplication sharedApplication] openURL:url])
            DebugLog(@"%@%@",@"Failed to open url:",[url description]);
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pebble Snap" message:@"Pebble Watch download location not available. Please try again later." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alert show];
    }
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    DebugLog(@"BEGIN");

    if(actionSheet == askUserToInstallPebbleAppActionSheet) {
        if (buttonIndex == 0) // Yes, show me
        {
//            [Flurry logEvent:@"askUserToInstallPebbleAppActionSheet.YES"];
            [self processWatchAppInstall];
        }
        else if(buttonIndex == 1) // No, not now
        {
//            [Flurry logEvent:@"askUserToInstallPebbleAppActionSheet.NO"];
        }
        else if(buttonIndex == 2) // Already installed it
        {
//            [Flurry logEvent:@"askUserToInstallPebbleAppActionSheet.INSTALLED"];
            alreadyInstallWatchApp = true;
            [self saveSettings];
        }
        askUserToInstallPebbleAppActionSheet = nil;
    }
    else if(actionSheet == askUserToOpenPebbleAppActionSheet) {
        if (buttonIndex == 0) // It's running
        {
//            [Flurry logEvent:@"askUserToOpenPebbleAppActionSheet.RUNNING"];
            alreadyInstallWatchApp = true;
            [self saveSettings];
        }
        else if(buttonIndex == 1) // Install it
        {
//            [Flurry logEvent:@"askUserToOpenPebbleAppActionSheet.INSTALL"];
            [self processWatchAppInstall];
        }
        else if(buttonIndex == 2) // Leave me alone
        {
//            [Flurry logEvent:@"askUserToOpenPebbleAppActionSheet.LEAVEMEALONE"];
            remindStartWatchApp = false;
            [self saveSettings];
        }
        askUserToInstallPebbleAppActionSheet = nil;
    }
    else if(actionSheet == askUserToConnectPebbleWatchActionSheet) {
        if (buttonIndex == 0) // Yes, show me
        {
//            [Flurry logEvent:@"askUserToConnectPebbleWatchActionSheet.YES"];
            [self openPebbleAppInstallLocation: @"itms-apps://itunes.apple.com/us/app/pebble-smartwatch/id592012721"];
        }
        else if(buttonIndex == 1) // No, not now
        {
//            [Flurry logEvent:@"askUserToConnectPebbleWatchActionSheet.NO"];
        }
        else if(buttonIndex == 2) // Already installed it
        {
//            [Flurry logEvent:@"askUserToConnectPebbleWatchActionSheet.INSTALLED"];
            askUserToConnectPebbleWatchApp = false;
            [self saveSettings];
        }
        askUserToConnectPebbleWatchActionSheet = nil;
    }
}


- (void)askUserToConnectPebbleWatch
{
    DebugLog(@"BEGIN");
	askUserToConnectPebbleWatchActionSheet = [[UIActionSheet alloc] initWithTitle:@"This iOS device is not connected to a Pebble Watch, install and connect?"
                                                                       delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil
                                                              otherButtonTitles:@"Yes, install and connect", @"No, not now", @"Already installed it", nil];
	askUserToConnectPebbleWatchActionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
	[askUserToConnectPebbleWatchActionSheet showInView:self.view]; // show from our table view (pops up in the middle of the table)
}


- (void)askUserToInstallPebbleApp
{
    DebugLog(@"BEGIN");
	askUserToInstallPebbleAppActionSheet = [[UIActionSheet alloc] initWithTitle:@"Install Pabble Cam Watch App?"
                                                             delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Yes, install it", @"No, not now", @"Already installed it", nil];
	askUserToInstallPebbleAppActionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
	[askUserToInstallPebbleAppActionSheet showInView:self.view]; // show from our table view (pops up in the middle of the table)
}

- (void)askUserToStartPebbleApp
{
    DebugLog(@"BEGIN");
    askUserToOpenPebbleAppActionSheet = [[UIActionSheet alloc] initWithTitle:@"Start Pebble Cam Watch App"
                                                                                      delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil
                                                                             otherButtonTitles:@"It's running", @"Install it", @"Leave me alone", nil];
	askUserToOpenPebbleAppActionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
	[askUserToOpenPebbleAppActionSheet showInView:self.view]; // show from our table view (pops up in the middle of the table)
}


- (void)sendWatchMessage:(NSNumber *)key messageId:(int)id {
    DebugLog(@"BEGIN");
    
    [messageQueue enqueue:@{key: [NSNumber numberWithUint8:id]}];

//    if(_targetWatch == nil) {
//        if(askUserToConnectPebbleWatchApp) {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pebble Snap" message:@"Pebble Watch not available. Please verify that your Pebble is on, connected and within range." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
//            [alert show];
//        }
//        return;
//    }
//    [_targetWatch appMessagesPushUpdate:@{key: [NSNumber numberWithUint8:id]} onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
//        if(!error) {
//            DebugLog(@"Pushed watch message: %@, %d", key, id);
//        } else {
//            DebugLog(@"Error pushing watch message: %@", error);
//            /*
//             Error pushing watch message:
//             Error Domain=com.pebble.iossdk.public
//             Code=8 "No app UUID has been set. Use -[PBWatch setAppUUID:] to set your app's UUID."
//             UserInfo=0x1d866140 {NSLocalizedDescription=No app UUID has been set. Use -[PBWatch setAppUUID:] to set your app's UUID.}
//             
//             Error pushing watch message:
//             Error Domain=com.pebble.iossdk.public
//             Code=9 "The watch app rejected the update that was pushed."
//             UserInfo=0x1d874150 {NSLocalizedDescription=The watch app rejected the update that was pushed.}
//             
//             Error pushing watch message: 
//             Error Domain=com.pebble.iossdk.public Code=4 "Sending of message timed out." 
//             UserInfo=0x17dd7bf0 {NSLocalizedDescription=Sending of message timed out.}
//             */
//            if([key isEqual: APP_CONNECT_KEY] && ([error code] == PBErrorCodeNoAppUUID) && !alreadyInstallWatchApp) {
//                [self askUserToInstallPebbleApp];
//            }
//            else if([key isEqual: APP_CONNECT_KEY] && ([error code] == PBErrorCodeAppMessageRejected && remindStartWatchApp)) {
//                [self askUserToStartPebbleApp];
//            }
//            else if([key isEqual: APP_CONNECT_KEY] && ([error code] == PBErrorCodeSendMessageTimeout && remindStartWatchApp)) {
//                [self askUserToStartPebbleApp];
//            }
//        }
//    }];
}

- (void)launchWatchApp {
    DebugLog(@"BEGIN");
    [_targetWatch appMessagesLaunch:^(PBWatch *watch, NSError *error) {
        if(!error) {
            DebugLog(@"Successfully launched Watch App on: %@", watch.name);
        } else {
            DebugLog(@"Error launching watch app: %@", error);
        }
    }];
}

- (void)killWatchApp {
    DebugLog(@"BEGIN");
    [_targetWatch appMessagesKill:^(PBWatch *watch, NSError *error) {
        if(!error) {
            DebugLog(@"Successfully killed Watch App on: %@", watch.name);
        } else {
            DebugLog(@"Error launching watch app: %@", error);
        }
    }];
}

- (void)saveSettings {
    DebugLog(@"BEGIN");

    if(livePreview) {
        [self configureLivePreview];
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:username forKey:@SETTING_USERNAME];
    [defaults setValue:pwd forKey:@SETTING_PWD];
    [defaults setValue:userId forKey:@SETTING_USERID];
    [defaults setValue:sessionId forKey:@SETTING_SESSIONID];
    [defaults setInteger:flashMode forKey:@SETTING_FLASH_MODE];
    [defaults setInteger:selfTimerSeconds forKey:@SETTING_SELF_TIMER_SECONDS];
    [defaults setBool:addLocationDataToPhotos forKey:@SETTING_ADD_LOCATION_TO_PHOTOS];
    [defaults setBool:firstTimeUse forKey:@SETTING_FIRST_TIME_USE];
    [defaults setBool:alreadyInstallWatchApp forKey:@SETTING_ALREADY_INSTALLED_WATCH_APP];
    [defaults setBool:remindStartWatchApp forKey:@SETTING_REMIND_START_WATCH_APP];
    [defaults setBool:askUserToConnectPebbleWatchApp forKey:@SETTING_REMIND_CONNECT_WATCH_APP];
    [defaults setBool:keepScreenOn forKey:@SETTING_KEEPSCREENON];
    [defaults setBool:vibrateMode forKey:@SETTING_VIBRATE_WATCH];
    [defaults setBool:tapMode forKey:@SETTING_TAP_MODE];
    [defaults setBool:livePreview forKey:@SETTING_CAMERA_PREVIEW];
    
    if([defaults synchronize]) {
        DebugLog(@"Settings saved to persistent store");
    }
    else {
        DebugLog(@"WARNING: Unable to save settings to persistent store");
    }

    DebugLog(@"Saved setting: %s, value: %@, default value: %s", SETTING_USERNAME, username, kbUsername);
    DebugLog(@"Saved setting: %s, value: %@, default value: %s", SETTING_USERID, userId, kbUserId);
    DebugLog(@"Saved setting: %s, value: %@, default value: %s", SETTING_SESSIONID, sessionId, kbSessionId);
    DebugLog(@"Saved setting: %s, value: %ld, default value: %ld", SETTING_FLASH_MODE, (long)flashMode, (long)kbFlashModeDefault);
    DebugLog(@"Saved setting: %s, value: %d, default value: %d", SETTING_SELF_TIMER_SECONDS, selfTimerSeconds, kbSelfTimerSecondsDefault);
    DebugLog(@"Saved setting: %s, value: %d, default value: %d", SETTING_ADD_LOCATION_TO_PHOTOS, addLocationDataToPhotos, kbAddLocationDataToPhotosKeyDefault);
    DebugLog(@"Saved setting: %s, value: %d, default value: %d", SETTING_FIRST_TIME_USE, firstTimeUse, kbFirstTimeUseDefault);
    DebugLog(@"Saved setting: %s, value: %d, default value: %d", SETTING_ALREADY_INSTALLED_WATCH_APP, alreadyInstallWatchApp, kbAlreadyInstallWatchApp);
    DebugLog(@"Saved setting: %s, value: %d, default value: %d", SETTING_REMIND_START_WATCH_APP, remindStartWatchApp, kbRemindStartWatchApp);
    DebugLog(@"Saved setting: %s, value: %d, default value: %d", SETTING_REMIND_CONNECT_WATCH_APP, askUserToConnectPebbleWatchApp, kbAskUserToConnectPebbleWatchApp);
    DebugLog(@"Saved setting: %s, value: %d, default value: %d", SETTING_KEEPSCREENON, keepScreenOn, kbKeepScreenOn);
    DebugLog(@"Saved setting: %s, value: %d, default value: %d", SETTING_VIBRATE_WATCH, vibrateMode, kbVibrateWatch);
    DebugLog(@"Saved setting: %s, value: %d, default value: %d", SETTING_TAP_MODE, tapMode, kbTapMode);
    DebugLog(@"Saved setting: %s, value: %d, default value: %d", SETTING_CAMERA_PREVIEW, livePreview, kbCameraPreview);

    
    CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
}

- (IBAction)livePreviewClicked:(id)sender {
    livePreview = !livePreview;
    [captureManager livePreview:livePreview];
    [self configureLivePreview];
    [self saveSettings];
}


- (void)configureLivePreview {
    if(livePreviewTimer != nil) {
        [livePreviewTimer invalidate];
    }
    
    if(_isConnected) {
        self.livePreviewButton.enabled = true;
        self.livePreviewButton.tintColor = [UIColor grayColor];
        if(livePreview) {
            self.livePreviewButton.tintColor = [UIColor greenColor];
            livePreviewTimer = [NSTimer scheduledTimerWithTimeInterval:livePreviewTimerSeconds
                                                                target:self
                                                                selector:@selector(livePreviewTimerFired:)
                                                                userInfo:nil
                                                                repeats:NO];
        }

    }
    else {
        self.livePreviewButton.enabled = false;
    }
}

- (void)loadSettings {
    DebugLog(@"BEGIN");
    
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    username = [defaults valueForKey:@SETTING_USERNAME];
    pwd = [defaults dataForKey:@SETTING_PWD];
    userId = [defaults valueForKey:@SETTING_USERID];
    sessionId = [defaults valueForKey:@SETTING_SESSIONID];
    flashMode = [defaults integerForKey:@SETTING_FLASH_MODE];
    selfTimerSeconds = (int)[defaults integerForKey:@SETTING_SELF_TIMER_SECONDS];
    addLocationDataToPhotos = [defaults boolForKey:@SETTING_ADD_LOCATION_TO_PHOTOS];
    firstTimeUse = [defaults boolForKey:@SETTING_FIRST_TIME_USE];
    remindStartWatchApp = [defaults boolForKey:@SETTING_ALREADY_INSTALLED_WATCH_APP];
    alreadyInstallWatchApp = [defaults boolForKey:@SETTING_REMIND_CONNECT_WATCH_APP];
    askUserToConnectPebbleWatchApp = [defaults boolForKey:@SETTING_REMIND_START_WATCH_APP];
    keepScreenOn = [defaults boolForKey:@SETTING_KEEPSCREENON];
    vibrateMode = [defaults boolForKey:@SETTING_VIBRATE_WATCH];
    tapMode =[defaults boolForKey:@SETTING_TAP_MODE];
    livePreview =[defaults boolForKey:@SETTING_CAMERA_PREVIEW];
    
    [self sendWatchMessage:APP_VIBRATE_MODE_KEY messageId:vibrateMode];
    [self setTapMode];

    DebugLog(@"Loaded setting: %s, value: %@, default value: %s", SETTING_USERNAME, username, kbUsername);
    DebugLog(@"Loaded setting: %s, value: %@, default value: %s", SETTING_USERID, userId, kbUserId);
    DebugLog(@"Loaded setting: %s, value: %@, default value: %s", SETTING_SESSIONID, sessionId, kbSessionId);
    DebugLog(@"Loaded setting: %s, value: %ld, default value: %ld", SETTING_FLASH_MODE, (long)flashMode, (long)kbFlashModeDefault);
    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_SELF_TIMER_SECONDS, selfTimerSeconds, kbSelfTimerSecondsDefault);
    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_ADD_LOCATION_TO_PHOTOS, addLocationDataToPhotos, kbAddLocationDataToPhotosKeyDefault);
    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_FIRST_TIME_USE, firstTimeUse, kbFirstTimeUseDefault);
    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_ALREADY_INSTALLED_WATCH_APP, alreadyInstallWatchApp, kbAlreadyInstallWatchApp);
    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_REMIND_START_WATCH_APP, remindStartWatchApp, kbRemindStartWatchApp);
    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_REMIND_CONNECT_WATCH_APP, askUserToConnectPebbleWatchApp, kbAskUserToConnectPebbleWatchApp);
    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_KEEPSCREENON, keepScreenOn, kbKeepScreenOn);
    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_VIBRATE_WATCH, vibrateMode, kbVibrateWatch);
    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_TAP_MODE, tapMode, kbTapMode);
    DebugLog(@"Loaded setting: %s, value: %d, default value: %d", SETTING_CAMERA_PREVIEW, livePreview, kbCameraPreview);


    // Write out the preferences.
    CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
    
    [self configureLivePreview];

    
    if(firstTimeUse) {
        // show the overlay view...
        //        [Flurry logEvent:@"firstTimeUse"];
        
        firstTimeUse = false;
        _statusLabel.text = @"";
        OverlayView *overlayView = [[NSBundle mainBundle] loadNibNamed:@"OverlayView"owner:self options:nil][0];
        
        [UIView transitionWithView:self.view
                          duration:0.5
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.view addSubview:overlayView];
                        }
                        completion:nil];
    }
    
    
}

- (void)sendImageToWatch: (UIImage *)image {
    
    NSData *bitmap = nil;
    
    if (self.isPebbleFirmware2) {
        UIImage *previewImage = [image squareImageWithImage:image scaledToSize:CGSizeMake(128,128)];
        bitmap = [CameraPreviewImage ditheredBitmapDataFromImage:previewImage withHeight:128 width:128];
    }
    else {
        UIImage *previewImage = [image squareImageWithImage:image scaledToSize:CGSizeMake(120,168)];
        bitmap = [CameraPreviewImage colorBitmapDataFromImage:previewImage withHeight:120 width:168 livePreview:livePreview pebbleFirmware2:self.isPebbleFirmware2];
    }
    
//    UIImage *magickImage = [[UIImage alloc] initWithData:bitmap];
//    overlayImageView.image = magickImage;
    
    size_t bitmap_length = [bitmap length];
    [messageQueue enqueue:@{APP_IMAGE_BEGIN: [NSNumber numberWithLong:bitmap_length]}];
    
    for(size_t i = 0; i < bitmap_length; i += MAX_OUTGOING_SIZE) {
        NSMutableData *outgoing = [[NSMutableData alloc] initWithCapacity:MAX_OUTGOING_SIZE];
        [outgoing appendData:[bitmap subdataWithRange:NSMakeRange(i, MIN(MAX_OUTGOING_SIZE, bitmap_length - i))]];
        [messageQueue enqueue:@{APP_IMAGE_DATA: outgoing}];
    }

    [messageQueue enqueue:@{APP_IMAGE_END: @1}];
}

- (void)livePreviewTimerFired:(NSTimer *)timer {
    DebugLog(@"BEGIN");
    if(livePreview == true) {
        [self sendImageToWatch:[self captureManager].videoImage];
        if(livePreviewTimer != nil) {
            [livePreviewTimer invalidate];
        }
        livePreviewTimer = [NSTimer scheduledTimerWithTimeInterval:livePreviewTimerSeconds
                                                            target:self
                                                          selector:@selector(livePreviewTimerFired:)
                                                          userInfo:nil
                                                           repeats:NO];
        
    }
}



- (void)aplViewControllerDidFinish:(APLViewController *)controller {
    DebugLog(@"BEGIN");
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)snapWatchSettingsTableViewControllerDidCancel:(SnapWatchSettingsTableViewController *)controller {
    DebugLog(@"BEGIN");
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)snapWatchSettingsTableViewControllerDidFinish:(SnapWatchSettingsTableViewController *)controller {
    DebugLog(@"BEGIN");
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self loadSettings];
    [self selectFlash];
    [self setVibrateMode];
    [self setTapMode];
    [self configureLivePreview];
    [self trackLocation:addLocationDataToPhotos];
    if(firstTimeUse) {
        remindStartWatchApp = kbRemindStartWatchApp;
        alreadyInstallWatchApp = kbAlreadyInstallWatchApp;
        firstTimeUse = kbFirstTimeUseDefault;
        askUserToConnectPebbleWatchApp = kbAskUserToConnectPebbleWatchApp;
        [self saveSettings];
    }
    [UIApplication sharedApplication].idleTimerDisabled = keepScreenOn;
}

- (void)snapWatchSettingsViewControllerDidCancel:(SnapWatchSettingsViewController *)controller {
    DebugLog(@"BEGIN");
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)snapWatchSettingsViewControllerDidFinish:(SnapWatchSettingsViewController *)controller selfTimerSeconds:(int)seconds flashMode:(long)mode addLocationDataToPhotos:(BOOL)addLocation showHelpOption:(BOOL)showHelp keepScreenOnOption:(BOOL)keepScreenOnNew {
    DebugLog(@"BEGIN");
    flashMode = mode;
    [self selectFlash];
    selfTimerSeconds = seconds;
    addLocationDataToPhotos = addLocation;
    [self trackLocation:addLocationDataToPhotos];
    if(showHelp) {
        remindStartWatchApp = kbRemindStartWatchApp;
        alreadyInstallWatchApp = kbAlreadyInstallWatchApp;
        firstTimeUse = kbFirstTimeUseDefault;
        askUserToConnectPebbleWatchApp = kbAskUserToConnectPebbleWatchApp;
    }
    keepScreenOn = keepScreenOnNew;
    [self saveSettings];
    _statusLabel.text = @"Settings saved";
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    [UIApplication sharedApplication].idleTimerDisabled = keepScreenOn;
    
    //    [[UIApplication sharedApplication] unregisterForRemoteNotifications];

}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    DebugLog(@"BEGIN");
    return YES;
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    DebugLog(@"BEGIN");
    return YES;
}


- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DebugLog(@"BEGIN");
    if ([[segue identifier] isEqualToString:@"ShowSettingsViewController"])
    {
        SnapWatchSettingsViewController *viewController = segue.destinationViewController;
        viewController.delegate = self;
        viewController.flashMode = flashMode;
        viewController.selfTimerSeconds = selfTimerSeconds;
        viewController.addLocationDataToPhotos = addLocationDataToPhotos;
        viewController.keepScreenOn = keepScreenOn;
//        [Flurry logEvent:@"ShowSettingsViewController"];
    }
    else if ([[segue identifier] isEqualToString:@"ShowSettingsTableViewController"]) {
        UINavigationController *navigationController = segue.destinationViewController;
		SnapWatchSettingsTableViewController *viewController  = [[navigationController viewControllers] objectAtIndex:0];
		viewController.delegate = self;
        //        [Flurry logEvent:@"ShowPhotoLibraryViewController"];
    }
    else if ([[segue identifier] isEqualToString:@"ShowPhotoLibraryViewController"]) {

        //     if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {

        APLViewController *viewController = segue.destinationViewController;
        viewController.delegate = self;
        viewController.image = lastImageCaptured;
//        [Flurry logEvent:@"ShowPhotoLibraryViewController"];
    }

}

- (void) disableToolbar {
    DebugLog(@"BEGIN");
    self.photoViewButton.enabled = false;
    self.settingsButton.enabled = false;
    self.captureButton.enabled = false;
}

- (void) enableToolbar {
    DebugLog(@"BEGIN");
    self.photoViewButton.enabled = true;
    self.settingsButton.enabled = true;
    self.captureButton.enabled = true;
}

- (void) disconnectWatch {
    DebugLog(@"BEGIN");
//    [Flurry logEvent:@"disconnectWatch"];
    if(isMoveRecording && [self captureManager].isMovieRecording) {
        [[self captureManager] toggleMovieRecording];
    }

    [messageQueue clear];
    [self killWatchApp];
    [self sendWatchMessage:APP_CONNECT_KEY messageId:NO];
    if(locationManager) {
        [locationManager stopMonitoringSignificantLocationChanges];
    }

    [self saveSettings];
    [self captureButton].tintColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    self.livePreviewButton.enabled = false;
    _isConnected = false;
    [_targetWatch closeSession:nil];
    if(_updateHandler) {
        [_targetWatch appMessagesRemoveUpdateHandler:_updateHandler];
        _updateHandler = nil;
    }
    [[PBPebbleCentral defaultCentral] setDelegate:nil];
    NSString *message = [NSString stringWithFormat:@"Disconnected from Pebble"];
    _statusLabel.text = message;
    _targetWatch = nil;
}

- (void) connectWatch {
    DebugLog(@"BEGIN");
    
    // Initialize with the last connected watch:
    [self setTargetWatch:[[PBPebbleCentral defaultCentral] lastConnectedWatch]];

    [self trackLocation:addLocationDataToPhotos];
}

- (void)selectCamera:(BOOL)selectFront {
    DebugLog(@"BEGIN");
    _usingFrontCamera = selectFront;
    
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
						   forView:[self captureView]
							 cache:YES];
	[UIView commitAnimations];
	[[self captureManager] selectCamera:_usingFrontCamera flashMode:flashMode]; // set to YES for Front Camera, No for Back camera
    [self sendWatchMessage:APP_SELECT_CAMERA_KEY messageId:_usingFrontCamera];
//    [Flurry logEvent:@"UsingFrontCamera"];

}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    DebugLog(@"BEGIN");
    // If it's a relatively recent event, turn off updates to save power
    CLLocation* location = [locations lastObject];
    currentLocation = location;
    DebugLog(@"latitude %+.6f, longitude %+.6f\n",
          currentLocation.coordinate.latitude,
          currentLocation.coordinate.longitude);

}

- (void)trackLocation:(BOOL)on
{
    DebugLog(@"BEGIN");
    addLocationDataToPhotos = on;
    if(on) {
        if(![CLLocationManager locationServicesEnabled]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"Please turn on location services for your phone in Settings." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
            [alert show];
            addLocationDataToPhotos = false;
        }
//        if(![CLLocationManager authorizationStatus]) {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Photo Location" message:@"Please turn on location services for Pebble Snap in Settings." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
//            [alert show];
//            addLocationDataToPhotos = false;
//            [Flurry logEvent:@"trackLocation - Pebble Snap Photo Location"];
//        }
    }
    
    if(addLocationDataToPhotos) {
        if(locationManager == nil) {
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
        }
        
        [locationManager startMonitoringSignificantLocationChanges];
    }
    else {
        if(locationManager) {
            [locationManager stopMonitoringSignificantLocationChanges];
        }
    }
}


- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    DebugLog(@"BEGIN");
    [super viewDidLoad];


    messageQueue = [[PebbleSnapMessageQueue alloc] init];

    
	// Do any additional setup after loading the view, typically from a nib.
    [[PBPebbleCentral defaultCentral] setDelegate:self];
    
    // Initialize with the last connected watch:
//    [self setTargetWatch:[[PBPebbleCentral defaultCentral] lastConnectedWatch]];

    
    NSURL *tickSound   = [[NSBundle mainBundle] URLForResource: @"tick"
                                                withExtension: @"aiff"];
    
    self.soundFileURLRef = (__bridge CFURLRef) tickSound;
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (
                                      
                                      soundFileURLRef,
                                      &soundFileObject
                                      );
    
    [self captureButton].tintColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
	[self setCaptureManager:[[CaptureSessionManager alloc] init]];
	[[self captureManager] addVideoInputForCamera:_usingFrontCamera flashMode:flashMode]; // set to YES for Front Camera, No for Back camera
    [[self captureManager] addStillImageOutput];
    [[self captureManager] addVideoCaptureOutput];
	[[self captureManager] addVideoPreviewLayer];
	[self captureManager].messageQueue = messageQueue;

    
	CGRect layerRect = [[[self view] layer] bounds];
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    layerRect.size = screenSize;
    
    [[self captureView] setBounds:layerRect];
    [[[self captureManager] previewLayer] setBounds:layerRect];
    [[[self captureManager] previewLayer] setPosition:CGPointMake(CGRectGetMidX(layerRect),CGRectGetMidY(layerRect))];
	[[[self captureView] layer] addSublayer:[[self captureManager] previewLayer]];
    
//    overlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"overlaygraphic.png"]];
//    [overlayImageView setFrame:CGRectMake(30, 100, 120, 168)];
//    [[self captureView] addSubview:overlayImageView];
    
//    UIButton *overlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [overlayButton setImage:[UIImage imageNamed:@"livepreviewbutton.png"] forState:UIControlStateNormal];
//    [overlayButton setFrame:CGRectMake(130, 320, 60, 30)];
//    [overlayButton setTintColor:[UIColor redColor]];
//    [overlayButton addTarget:self action:@selector(scanButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//    [[self view] addSubview:overlayButton];
    
//    UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 50, 120, 30)];
//    [self setScanningLabel:tempLabel];
//	[scanningLabel setBackgroundColor:[UIColor clearColor]];
//	[scanningLabel setFont:[UIFont fontWithName:@"Courier" size: 18.0]];
//	[scanningLabel setTextColor:[UIColor redColor]];
//	[scanningLabel setText:@"Saving..."];
//    [scanningLabel setHidden:YES];
//	[[self view] addSubview:scanningLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageCaptured:) name:kImageCaptured object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageSaved:) name:kImageSaved object:nil];
	[[captureManager captureSession] startRunning];
}

- (void)didReceiveMemoryWarning
{
    DebugLog(@"BEGIN");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc {
    DebugLog(@"BEGIN");
    
    AudioServicesDisposeSystemSoundID (soundFileObject);
    CFRelease (soundFileURLRef);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    DebugLog(@"BEGIN");
    [self deviceOrientationDidChange:toInterfaceOrientation];
}

// UIDeviceOrientationDidChangeNotification selector
- (void) deviceOrientationDidChange:(UIInterfaceOrientation) interfaceOrientation
{
    DebugLog(@"BEGIN");
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    // Don't update the reference orientation when the device orientation is face up/down or unknown.
    if ( UIDeviceOrientationIsPortrait(orientation) || UIDeviceOrientationIsLandscape(orientation) ) {
        [captureManager changeToOrientation:orientation];
    }
}

NSTimer *countdownTimer;
int countdownStart;

- (void)updateSecondsStatus:(int) seconds {
    DebugLog(@"BEGIN");
    NSString *secs = @"seconds";
    if(seconds == 1) {
        secs = @"second";
    }
    NSString *message = [NSString stringWithFormat:@"%d %@", seconds, secs];
    [self statusLabel].text = message;
    
}

- (void)movieRecordButtonPressed {
    DebugLog(@"BEGIN");
    [self animateCapture];
    [[self captureManager] toggleMovieRecording];
    if(!isMoveRecording) {
        isMoveRecording = true;
        [self captureButton].tintColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
        [self statusLabel].text = @"Video Recording: ON";
    }
    else {
        isMoveRecording = false;
        [self captureButton].tintColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
        [self statusLabel].text = @"Video Recording: OFF";
    }
    [self sendWatchMessage:APP_VIDEO_MODE_KEY messageId:isMoveRecording];

}

- (void)scanButtonPressed {
    DebugLog(@"BEGIN");
    [self disableToolbar];
    if(selfTimerSeconds > 0) {
//        [Flurry logEvent:[NSString stringWithFormat:@"Take Picture using self timer: %d seconds", selfTimerSeconds]];
        countdownStart = selfTimerSeconds;
        [self updateSecondsStatus:countdownStart];
        countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(countdownShutterRelease:)
                                       userInfo:nil
                                        repeats:YES];
        
        [NSTimer scheduledTimerWithTimeInterval:selfTimerSeconds
                                         target:self
                                       selector:@selector(releaseShutter:)
                                       userInfo:nil
                                        repeats:NO];
    }
    else {
        [self takePicture];
    }
}

- (void)countdownShutterRelease:(NSTimer*)theTimer {
    DebugLog(@"BEGIN");
    countdownStart--;
    if(countdownStart <= 0) {
        [countdownTimer invalidate];
    }
    else {
        AudioServicesPlaySystemSound(soundFileObject);
        [self updateSecondsStatus:countdownStart];
    }
}

- (void)releaseShutter:(NSTimer*)theTimer {
    DebugLog(@"BEGIN");
    [self takePicture];
}


- (void) animateCapture {
	[UIView beginAnimations:nil context:nil];
	
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:0.30];  //.25 looks nice as well.
	[self captureView].alpha = 0.0;
	
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration:0.30];  //.25 looks nice as well.
	[self captureView].alpha = 1.0;
    
	[UIView commitAnimations];
    
}

- (void)takePicture {
    DebugLog(@"BEGIN");
//    [Flurry logEvent:@"Take Picture"];
    [self animateCapture];
    [[self captureManager] captureStillImage];    
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    DebugLog(@"BEGIN");
    if (error != NULL) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Image couldn't be saved" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
    }
    else {
        lastImageCaptured = image;
        _statusLabel.text = @"Photo saved to Camera Roll";
    }
    [self enableToolbar];
}

- (void)setVibrateMode
{
    DebugLog(@"BEGIN");
    [self sendWatchMessage:APP_VIBRATE_MODE_KEY messageId:vibrateMode];
    if(vibrateMode == true) {
        _statusLabel.text = @"Watch vibration ON";
    }
    else {
        _statusLabel.text = @"Watch vibration OFF";
    }
    [self saveSettings];
}


- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
	CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)[[self captureManager] previewLayer] captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
	[captureManager focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)setTapMode
{
    DebugLog(@"BEGIN");
    [self sendWatchMessage:APP_TAP_MODE_KEY messageId:tapMode];
    if(tapMode == true) {
        _statusLabel.text = @"Tap to Snap ON";
    }
    else {
        _statusLabel.text = @"Tap to Snap OFF";
    }
    [self saveSettings];
}

- (void)selectFlash
{
    DebugLog(@"BEGIN");
    if(flashMode > AVCaptureFlashModeAuto) {
        flashMode = AVCaptureFlashModeOff;
    }
//    [Flurry logEvent:[NSString stringWithFormat:@"Change flash mode: %d", flashMode]];

    [self sendWatchMessage:APP_SELECT_FLASH_KEY messageId:flashMode];
    if(flashMode == AVCaptureFlashModeOff) {
        _statusLabel.text = @"Flash mode is OFF";
    }
    else if(flashMode == AVCaptureFlashModeOn) {
        _statusLabel.text = @"Flash mode is ON";
    }
    else if(flashMode == AVCaptureFlashModeAuto) {
        _statusLabel.text = @"Flash mode is AUTO";
    }
    [[self captureManager] flashMode:flashMode];
    [self saveSettings];
}

- (void)imageSaved:(NSNotification *)notification {
    DebugLog(@"BEGIN");
    if([notification userInfo]) {
        NSError *error = [[notification userInfo] objectForKey:@"error"];
        if (error != NULL) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Image couldn't be saved" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
    }
    else {
        lastImageCaptured = [captureManager stillImage];
        [self sendImageToWatch:lastImageCaptured];

        _statusLabel.text = @"Photo saved to Camera Roll";
    }
    [self enableToolbar];
}
- (void)imageCaptured:(NSNotification *)notification
{
    DebugLog(@"BEGIN");
    if([notification userInfo]) {
        NSError *error = [[notification userInfo] objectForKey:@"error"];
        if (error != NULL) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Photo couldn't be taken" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
    }
    else {
        if(addLocationDataToPhotos) {
            [[self captureManager] saveImageToPhotosAlbum: currentLocation];
        }
        else {
            [[self captureManager] saveImageToPhotosAlbum: nil];
        }
    
        _statusLabel.text = @"Photo taken";
    }
}

- (BOOL)handleWatchMessage:(PBWatch *)watch HTTPRequestFromMessage:(NSDictionary *)update {
    DebugLog(@"BEGIN");
    if (_targetWatch == watch || [watch isEqual:_targetWatch]) {
        for (id key in update) {
            
            NSInteger buttonPressed = [[update objectForKey:key] integerValue];
            NSString *message = [NSString stringWithFormat:@"key: %@, value: %ld \n", key, (long)buttonPressed];
            DebugLog(@"%@", message);
            
            if(buttonPressed == CMD_UP) {
                DebugLog(@"Up Pressed!");
                _usingFrontCamera = !_usingFrontCamera;
                [self selectCamera:_usingFrontCamera];
            }
            else if(buttonPressed == CMD_DOWN) {
                DebugLog(@"Down Pressed!");
                flashMode++;
                [self selectFlash];
            }
            else if(buttonPressed == CMD_SINGLE_CLICK) {
                DebugLog(@"Single Click!");
                _statusLabel.text = @"Click!";
                [self scanButtonPressed];
            }
            else if(buttonPressed == CMD_LONG_CLICK) {
                DebugLog(@"Long Click!");
                [self movieRecordButtonPressed];
            }
        }
    }
    
    return YES;
}

- (IBAction)touchHelpOverlay:(id)sender {
    DebugLog(@"BEGIN");
    firstTimeUse = false;
    [self saveSettings];
    if(_isAppMessagesSupported) {
        NSString *message = [NSString stringWithFormat:@"Ready to take photos...%@", [_targetWatch name]];
        _statusLabel.text = message;
    }
}


- (void)connectToPebble {
    DebugLog(@"BEGIN");

//    [self loadSettings];
    [self trackLocation:addLocationDataToPhotos];

    if (_targetWatch) {
//        DebugLog(@"watch.versionInfo.serialNumber = %@", _targetWatch.versionInfo.serialNumber);
//        DebugLog(@"watch.versionInfo.hardwareVersion = %@", _targetWatch.versionInfo.hardwareVersion);
//        
//        DebugLog(@"watch.versionInfo.recoveryFirmwareMetadata.version.timestamp = %u", (unsigned int)_targetWatch.versionInfo.recoveryFirmwareMetadata.version.timestamp);
//        DebugLog(@"watch.versionInfo.recoveryFirmwareMetadata.version.os = %ld", (long)_targetWatch.versionInfo.recoveryFirmwareMetadata.version.os);
//        DebugLog(@"watch.versionInfo.recoveryFirmwareMetadata.version.tag = %@", _targetWatch.versionInfo.recoveryFirmwareMetadata.version.tag);
//        DebugLog(@"watch.versionInfo.recoveryFirmwareMetadata.version.major = %ld", (long)_targetWatch.versionInfo.recoveryFirmwareMetadata.version.major);
//        DebugLog(@"watch.versionInfo.recoveryFirmwareMetadata.version.minor = %ld", (long)_targetWatch.versionInfo.recoveryFirmwareMetadata.version.minor);
//        
//        DebugLog(@"watch.versionInfo.runningFirmwareMetadata.version.timestamp = %u", (unsigned int)_targetWatch.versionInfo.runningFirmwareMetadata.version.timestamp);
//        DebugLog(@"watch.versionInfo.runningFirmwareMetadata.version.os = %ld", (long)_targetWatch.versionInfo.runningFirmwareMetadata.version.os);
//        DebugLog(@"watch.versionInfo.runningFirmwareMetadata.version.tag = %@", _targetWatch.versionInfo.runningFirmwareMetadata.version.tag);
//        DebugLog(@"watch.versionInfo.runningFirmwareMetadata.version.major = %ld", (long)_targetWatch.versionInfo.runningFirmwareMetadata.version.major);
//        DebugLog(@"watch.versionInfo.runningFirmwareMetadata.version.minor = %ld", (long)_targetWatch.versionInfo.runningFirmwareMetadata.version.minor);

        [self captureButton].tintColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
        if(!firstTimeUse) {
            NSString *message = [NSString stringWithFormat:@"Ready to take photos...%@", [_targetWatch name]];
            _statusLabel.text = message;
        }
        
        messageQueue.watch = _targetWatch;
        
        // "6f9302fc-ed64-435a-ae1a-83308fe11802
//        uint8_t bytes[] = { 0x6F, 0x93, 0x02, 0xFC, 0xED, 0x64, 0x43, 0x5A, 0xAE, 0x1A, 0x83, 0x30, 0x8F, 0xE1, 0x18, 0x02 };
//        NSData *uuid = [NSData dataWithBytes:bytes length:sizeof(bytes)];
//        [_targetWatch appMessagesSetUUID:uuid];
//        [[PBPebbleCentral defaultCentral] setAppUUID:[NSData dataWithBytes:bytes length:16]];
        
        uuid_t myAppUUIDbytes;
        NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:@"6f9302fc-ed64-435a-ae1a-83308fe11802"];
        [myAppUUID getUUIDBytes:myAppUUIDbytes];
        [[PBPebbleCentral defaultCentral] setAppUUID:[NSData dataWithBytes:myAppUUIDbytes length:16]];

        _updateHandler = [_targetWatch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
            return [self handleWatchMessage:watch HTTPRequestFromMessage:update];
        }];
        
        [self launchWatchApp];

        _isConnected = true;
        [self configureLivePreview];
        [self sendWatchMessage:APP_CONNECT_KEY messageId:YES];
        
        
//        [_targetWatch appMessagesGetIsSupported:^(PBWatch *watch, BOOL isAppMessagesSupported) {
//            _isAppMessagesSupported = isAppMessagesSupported;
//            if (_isAppMessagesSupported) {
//                [self captureButton].tintColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.20 alpha:1.0];
//                self.livePreviewButton.enabled = true;
//                if(!firstTimeUse) {
//                    NSString *message = [NSString stringWithFormat:@"Ready to take photos...%@", [_targetWatch name]];
//                    _statusLabel.text = message;
//                }
// 
//                messageQueue.watch = _targetWatch;
//
//                uint8_t bytes[] = { 0x6F, 0x93, 0x02, 0xFC, 0xED, 0x64, 0x43, 0x5A, 0xAE, 0x1A, 0x83, 0x30, 0x8F, 0xE1, 0x18, 0x02 };
//                NSData *uuid = [NSData dataWithBytes:bytes length:sizeof(bytes)];
//                [_targetWatch appMessagesSetUUID:uuid];
//                
//                 // "6f9302fc-ed64-435a-ae1a-83308fe11802
//                
////                uuid_t myAppUUIDbytes;
////                NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:@"6f9302fc-ed64-435a-ae1a-83308fe11802"];
////                [myAppUUID getUUIDBytes:myAppUUIDbytes];
////                [[PBPebbleCentral defaultCentral] setAppUUID:[NSData dataWithBytes:myAppUUIDbytes length:16]];
//                _updateHandler = [_targetWatch appMessagesAddReceiveUpdateHandler:^BOOL(PBWatch *watch, NSDictionary *update) {
//                    return [self handleWatchMessage:watch HTTPRequestFromMessage:update];
//                }];
//                _isConnected = true;
//                [self sendWatchMessage:APP_CONNECT_KEY messageId:YES];
//            }
//            else {
//                if([watch isConnected]) {
//                    NSString *message = [NSString stringWithFormat:@"Unable to take photos...%@", [_targetWatch name]];
//                    _statusLabel.text = message;
//                    //                [scanningLabel setText:message];
//                    
//                    [[[UIAlertView alloc] initWithTitle:@"Warning!" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//                }
//                else {
//                    if(!alreadyInstallWatchApp && !firstTimeUse) {
//                        [self askUserToInstallPebbleApp];
//                    }
//                }
//            }
//        }];
        
    }
    else {
        DebugLog(@"connectToPebble Failed!");
    }
    
}

- (IBAction)captureButtonClicked:(id)sender {
    DebugLog(@"BEGIN");
    if(_isConnected) {
        [self disconnectWatch];        
    }
    else {
        if(_targetWatch == nil) {
            [self connectWatch];
        }
    }
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)setTargetWatch:(PBWatch*)watch {
    DebugLog(@"BEGIN");

    _targetWatch = watch;
    if(_targetWatch != nil) {
        [self captureButton].tintColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0];
        [self connectToPebble];
        if(!firstTimeUse) {
            NSString *message = [NSString stringWithFormat:@"Connected to %@", [_targetWatch name]];
            _statusLabel.text = message;
        }
        
        NSLog(@"Pebble name: %@", _targetWatch.name);
        NSLog(@"Pebble serial number: %@", _targetWatch.serialNumber);
        
        [_targetWatch getVersionInfo:^(PBWatch *watch, PBVersionInfo *versionInfo ) {
            NSLog(@"Pebble firmware os version: %li", (long)versionInfo.runningFirmwareMetadata.version.os);
            
            self.isPebbleFirmware2 = false;
            if(versionInfo.runningFirmwareMetadata.version.os == 2) {
                self.isPebbleFirmware2 = true;
            }
            
            NSLog(@"Pebble firmware major version: %li", (long)versionInfo.runningFirmwareMetadata.version.major);
            NSLog(@"Pebble firmware minor version: %li", (long)versionInfo.runningFirmwareMetadata.version.minor);
            NSLog(@"Pebble firmware suffix version: %@", versionInfo.runningFirmwareMetadata.version.suffix);
        }
                                  onTimeout:^(PBWatch *watch) {
                                      NSLog(@"Timed out trying to get version info from Pebble.");
                                  }
         ];
    }
    else {
        _isConnected = false;
        NSString *message = [NSString stringWithFormat:@"Unable to connect to Pebble Watch"];
        DebugLog(@"%@", message);
        if(askUserToConnectPebbleWatchApp) {
            [self askUserToConnectPebbleWatch];
        }
        _statusLabel.text = message;
        _updateHandler = nil;
    }
}

/*
 *  PBPebbleCentral delegate methods
 */

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidConnect:(PBWatch*)watch isNew:(BOOL)isNew {
    DebugLog(@"BEGIN");
    
    [self setTargetWatch:watch];
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch {
    DebugLog(@"BEGIN");
    if (_targetWatch == watch || [watch isEqual:_targetWatch]) {
        [self disconnectWatch];
    }
}

- (IBAction)installWatchApp:(id)sender {
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"snapwatch" ofType:@"pbw];
//    NSURL *url = [NSURL fileURLWithPath:path];
    
}

@end
