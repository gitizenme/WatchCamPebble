//
//  SnapWatchViewController.h
//  SnapWatch
//
//  Created by Joe Chavez on 7/10/13.
//  Copyright (c) 2013 izen.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>

#import "SnapWatchSettings.h"
#import "CaptureSessionManager.h"



@interface SnapWatchViewController : UIViewController <CLLocationManagerDelegate, UIActionSheetDelegate> {
	CFURLRef		soundFileURLRef;
	SystemSoundID	soundFileObject;
}

- (void) saveSettings;
- (void) loadSettings;
- (void) takePicture;
- (void) disconnectWatch;
- (void) connectWatch;
- (void) openPebbleAppInstallLocation:(NSString *)strUrl;
- (void) deviceOrientationDidChange:(UIInterfaceOrientation) interfaceOrientation;
- (void) imageSaved:(NSNotification *)notification;
- (void) imageCaptured:(NSNotification *)notification;
- (void) processWatchAppInstall;


- (IBAction)captureButtonClicked:(id)sender;

@property (readwrite)	CFURLRef		soundFileURLRef;
@property (readonly)	SystemSoundID	soundFileObject;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *photoViewButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (weak, nonatomic) IBOutlet UIView *cameraTransitionView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *captureButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIView *captureView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *livePreviewButton;

@property (retain, nonatomic) UIImageView *overlayImageView;

@property (retain) CaptureSessionManager *captureManager;
@property (retain) NSString *username;
@property (retain) NSString *userId;
@property (retain) NSString *sessionId;
@property (retain) NSData *pwd;
@property (retain) NSString *deviceToken;

@property (nonatomic) BOOL isMovieRecording;

@property (nonatomic) BOOL isPebbleFirmware2;


@end
