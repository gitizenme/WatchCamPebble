//
//  SnapWatchSettingsViewController.m
//  SnapWatch
//
//  Created by Joe Chavez on 7/13/13.
//  Copyright (c) 2013 izen.me. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "SnapWatchDebug.h"
#import "SnapWatchSettingsViewController.h"
//#import "Flurry.h"

@interface SnapWatchSettingsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *appInfoLabel;

@end


@implementation SnapWatchSettingsViewController

@synthesize delegate = _delegate;
@synthesize flashMode;
@synthesize selfTimerSeconds;
@synthesize addLocationDataToPhotos;
@synthesize keepScreenOn;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)updateSelfTimerLabel {
    if(selfTimerSeconds > 0) {
        [self selfTimerSecondsLabel].text = [NSString stringWithFormat:@"%d seconds", selfTimerSeconds];
    }
    else {
        [self selfTimerSecondsLabel].text = [NSString stringWithFormat:@"Off"];
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    [Flurry logPageView];
	// Do any additional setup after loading the view.
    [self updateSelfTimerLabel];
    [self selfTimerSlider].value = selfTimerSeconds;
    [self flashModeControl].selectedSegmentIndex = flashMode;
    [self addLocationDataToPhotosSwitch].on = addLocationDataToPhotos;
    [self keepScreenOnSwitch].on = keepScreenOn;
    
    
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString * displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    
    NSString *appInfoLabelText = [NSString stringWithFormat:@"%@ v%@ (%@) by izen.me © 2013", displayName, appVersionString, appBuildString];
    [self appInfoLabel].text = appInfoLabelText;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)selfTimerValueChanged:(id)sender {
    float rawValue = [[self selfTimerSlider] value];
    selfTimerSeconds = round(rawValue);
    [self updateSelfTimerLabel];
}



- (IBAction)done:(id)sender {
    float rawValue = [[self selfTimerSlider] value];
    selfTimerSeconds = round(rawValue);
    flashMode = [self flashModeControl].selectedSegmentIndex;
    addLocationDataToPhotos = [self addLocationDataToPhotosSwitch].on;
    _showHelp = [self showHelpSwitch].on;
    keepScreenOn = [self keepScreenOnSwitch].on;
    
    [[self delegate] snapWatchSettingsViewControllerDidFinish:self selfTimerSeconds:selfTimerSeconds flashMode:flashMode addLocationDataToPhotos:addLocationDataToPhotos showHelpOption:_showHelp keepScreenOnOption:keepScreenOn];
}

- (IBAction)cancel:(id)sender {
    [[self delegate] snapWatchSettingsViewControllerDidCancel:self];
}

-(void)processWatchAppInstall
{
    DebugLog(@"BEGIN");
    
    NSURL *watchAppMetaUrl = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/122701/PebbleSnap/watch-ver.txt"];
    NSError *error;
    NSString *urlFromRemote = [[NSString alloc] initWithContentsOfURL:watchAppMetaUrl encoding:NSUTF8StringEncoding error:&error];
    
    if(error == nil) {
        NSURL *url = [NSURL URLWithString:urlFromRemote];
        
        if (![[UIApplication sharedApplication] openURL:url])
            DebugLog(@"%@%@",@"Failed to open url:",[url description]);
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pebble Snap" message:@"Pebble Watch download location not available. Please try again later." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alert show];
    }
    
}

- (IBAction)installWatchApp:(id)sender {
    [self processWatchAppInstall];
}

- (IBAction)tellAFriend:(id)sender {
    
}

- (IBAction)help:(id)sender {
    DebugLog(@"BEGIN");
    
    NSURL *url = [NSURL URLWithString:@"http://izen.me/apps/pebble-snap/"];
    
    if (![[UIApplication sharedApplication] openURL:url])
        DebugLog(@"%@%@",@"Failed to open url:",[url description]);
}

- (IBAction)locationOptionSelected:(id)sender {
    
    if([self addLocationDataToPhotosSwitch].on) {
        if(![CLLocationManager locationServicesEnabled]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"Please turn on location services for your phone in Settings." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
            [alert show];
            [self addLocationDataToPhotosSwitch].on = false;
        }
//        if(![CLLocationManager authorizationStatus]) {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enable Photo Location" message:@"Please turn on location services for Pebble Snap in Settings." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
//            [alert show];
//            [self addLocationDataToPhotosSwitch].on = true;
//        }
    }
    
}

@end
