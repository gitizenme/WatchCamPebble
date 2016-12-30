//
//  SnapWatchSettingsTableViewController.m
//  SnapWatch
//
//  Created by Joe Chavez on 8/22/13.
//  Copyright (c) 2013 izen.me. All rights reserved.
//

#import "SnapWatchDebug.h"
#import "SnapWatchSettings.h"
#import "SnapWatchSettingsTableViewController.h"
#import <PebbleKit/PebbleKit.h>



@interface SnapWatchSettingsTableViewController ()

@property (nonatomic) NSUInteger flashMode;
@property (nonatomic) NSUInteger selfTimerSeconds;
@property (nonatomic) BOOL enablePhotoLocation;
@property (nonatomic) BOOL keepScreenOn;
@property (nonatomic) BOOL showInAppHelp;
@property (nonatomic) BOOL followedOnTwitter;
@property (nonatomic) bool vibrateWatch;
@property (nonatomic) bool tapMode;
@property (nonatomic) bool livePreview;
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) UIActionSheet *selectTwitterAccountActionSheet;

@end


@implementation SnapWatchSettingsTableViewController

@synthesize delegate = _delegate;
@synthesize flashLabelConstraint;
@synthesize flashSegmentedControlConstriant;

#define SECTION_ABOUT   0
#define SECTION_ABOUT_VERSION 0
#define SECTION_ABOUT_FOLLOW_PEBBLESNAP 1

#define SECTION_CAMERA  1
#define SECTION_CAMERA_ENABLE_PHOTO_LOCATION 2
#define SECTION_CAMERA_KEEP_SCREEN_ON 3
#define SECTION_CAMERA_VIBRATE_WATCH 4
#define SECTION_CAMERA_TAP_MODE 5
//#define SECTION_CAMERA_LIVE_PREVIEW 6

#define SECTION_APP     2
#define SECTION_APP_INSTALL_WATCH_APP 0
#define SECTION_APP_IN_APP_HELP 1
#define SECTION_APP_ONLINE_HELP 2

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _flashMode = [defaults integerForKey:@SETTING_FLASH_MODE];
    _flashModeSegmentControl.selectedSegmentIndex = _flashMode;

    _selfTimerSeconds = [defaults integerForKey:@SETTING_SELF_TIMER_SECONDS];
    _selfTimerSlider.value = _selfTimerSeconds;
    [self updateSelfTimerLabel];
    
    _enablePhotoLocation = [defaults boolForKey:@SETTING_ADD_LOCATION_TO_PHOTOS];
    _keepScreenOn = [defaults boolForKey:@SETTING_KEEPSCREENON];
    _showInAppHelp = [defaults boolForKey:@SETTING_FIRST_TIME_USE];
    _followedOnTwitter = [defaults boolForKey:@SETTING_FOLLOWONTWITTER];
    _vibrateWatch = [defaults boolForKey:@SETTING_VIBRATE_WATCH];
    _tapMode = [defaults boolForKey:@SETTING_TAP_MODE];
    _livePreview = [defaults boolForKey:@SETTING_CAMERA_PREVIEW];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        flashLabelConstraint.constant = 60;
        _selfTimerLabelConstraint.constant = 60;
        _selfTimerStepperConstraint.constant = 60;
    }
    else {
        flashLabelConstraint.constant = 20;
        _selfTimerLabelConstraint.constant = 20;
        _selfTimerStepperConstraint.constant = 20;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
 */

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DebugLog(@"BEGIN");

    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    NSUInteger section = [indexPath section];
    NSUInteger row = [indexPath row];
    
    switch (section)
    {
        case SECTION_ABOUT:
            if (row == SECTION_ABOUT_VERSION) {
                NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
                NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                NSString * displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                cell.textLabel.text = displayName;
                
                NSString *appInfoLabelText = [NSString stringWithFormat:@"v%@ (%@)", appVersionString, appBuildString];
                cell.detailTextLabel.text = appInfoLabelText;
            }
            else if(row == SECTION_ABOUT_FOLLOW_PEBBLESNAP) {
                if(_followedOnTwitter) {
                    [cell textLabel].text = @"Following @watch_cam";
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
            }
            break;
            
        case SECTION_CAMERA:
            if(row == SECTION_CAMERA_ENABLE_PHOTO_LOCATION) {
                if(_enablePhotoLocation) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
            else if(row == SECTION_CAMERA_KEEP_SCREEN_ON) {
                if(_keepScreenOn) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
            else if(row == SECTION_CAMERA_VIBRATE_WATCH) {
                if(_vibrateWatch) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
//            else if(row == SECTION_CAMERA_LIVE_PREVIEW) {
//                if(_livePreview) {
//                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
//                }
//                else {
//                    cell.accessoryType = UITableViewCellAccessoryNone;
//                }
//            }
            else if(row == SECTION_CAMERA_TAP_MODE) {
                if(_tapMode) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
            break;
            
        case SECTION_APP:
            if(row == SECTION_APP_IN_APP_HELP) {
                if(_showInAppHelp) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
            break;
    }
    
    return cell;
}

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    DebugLog(@"BEGIN");
    
    if(actionSheet == _selectTwitterAccountActionSheet) {
        if (buttonIndex != (_selectTwitterAccountActionSheet.numberOfButtons-1)) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            ACAccountType *type = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
            NSArray *accountsArray = [_accountStore accountsWithAccountType:type];
            [dict setObject:[accountsArray objectAtIndex:buttonIndex] forKey:@"account"];
            [self performSelectorOnMainThread:@selector(followWithAccountInfo:) withObject:dict waitUntilDone:NO];
        }
    }
}

#pragma mark - Table view delegate

-(void) followTwitterUser {
    DebugLog(@"BEGIN");

    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        // Create account store, followed by a twitter account identifier
        _accountStore = [[ACAccountStore alloc] init];
        
        ACAccountType *type = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        [_accountStore requestAccessToAccountsWithType:type options:nil completion:^(BOOL granted, NSError *error) {
            if(granted) {
                NSArray *accountsArray = [_accountStore accountsWithAccountType:type];
                // Sanity check
                if ([accountsArray count] == 1)
                {
                    //Create dictionary to pass to followWithAccountInfo: method
                    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                    //Follow the username with your first logged in account
                    [dict setObject:[accountsArray objectAtIndex:0] forKey:@"account"];
//                    [dict setObject:row forKey:@"row"];
                    [self performSelectorOnMainThread:@selector(followWithAccountInfo:) withObject:dict waitUntilDone:NO];
                }
                else if(accountsArray.count > 1) {
                    
                    
                    _selectTwitterAccountActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select Twitter Account"
                                                                                   delegate:self
                                                                          cancelButtonTitle:nil
                                                                     destructiveButtonTitle:nil
                                                                          otherButtonTitles:nil];

                    for (int idx = 0; idx < accountsArray.count; idx++) {
                        ACAccount *acct = [accountsArray objectAtIndex:idx];
                        DebugLog(@"Found Twitter account: %@", acct.username);
                        [_selectTwitterAccountActionSheet addButtonWithTitle:acct.username];
                    }
                    [_selectTwitterAccountActionSheet addButtonWithTitle:@"Cancel"];
                    
                    _selectTwitterAccountActionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
                    [_selectTwitterAccountActionSheet showInView:self.view]; // show from our table view (pops up in the middle of the table)
                    
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Twitter Account Not Found" message:@"There are now registered Twitter accounts on this device." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
                    [alert show];
                }
            }
        }];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Twitter Not Installed" message:@"Please install the Twitter app from the App store to follow @watch_cam" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alert show];
    }
}

-(void) followWithAccountInfo:(NSDictionary *) dictionary {
    DebugLog(@"BEGIN");

    ACAccount *acct = [dictionary objectForKey:@"account"];
    // Build a twitter request for following the username specified
    SLRequest *postRequest = [SLRequest requestForServiceType: SLServiceTypeTwitter
                       requestMethod: SLRequestMethodPOST
                                 URL: [NSURL URLWithString:@"http://api.twitter.com/1.1/friendships/create.json"]
                          parameters: [NSDictionary dictionaryWithObjectsAndKeys:@"watch_cam", @"screen_name", @"true", @"follow", nil] ];
    
    // Post the request
    [postRequest setAccount:acct];
    // Block handler to manage the response
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         DebugLog(@"Follow on Twitter result: %ld", (long)urlResponse.statusCode);

         if(urlResponse.statusCode == 200) {
             NSIndexPath *myIP = [NSIndexPath indexPathForRow:SECTION_ABOUT_FOLLOW_PEBBLESNAP inSection:SECTION_ABOUT];
             UITableViewCell *row = [_settingsTableView cellForRowAtIndexPath:myIP];
             [row textLabel].text = @"Following @watch_cam";
             row.accessoryType = UITableViewCellAccessoryCheckmark;
             _followedOnTwitter = true;
             NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
             [defaults setBool:_followedOnTwitter forKey:@SETTING_FOLLOWONTWITTER];
             CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
         }
         else {
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem With Twitter" message:@"A problem occured when trying to follow @watch_cam on Twitter. Please try again later." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
             [alert show];
         }
     }];
}

- (void)followPebbleSnap: (UITableViewCell *)row  {
    DebugLog(@"BEGIN");
    [self followTwitterUser];
}

-(void)processWatchAppInstall
{
    DebugLog(@"BEGIN");
    
    NSError *error;
//    NSURL *watchAppMetaUrl = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/122701/PebbleSnap/watch-ver.txt"];
//    NSString *urlFromRemote = [[NSString alloc] initWithContentsOfURL:watchAppMetaUrl encoding:NSUTF8StringEncoding error:&error];
    
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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DebugLog(@"BEGIN");

    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    bool followedOnTwitter = [defaults boolForKey:@SETTING_FOLLOWONTWITTER];

    NSUInteger section = [indexPath section];
    NSUInteger row = [indexPath row];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    switch (section)
    {
        case SECTION_ABOUT:
            if(row == SECTION_ABOUT_FOLLOW_PEBBLESNAP) {
                if(!followedOnTwitter) {
                    [self followPebbleSnap:cell];
                }
            }
            break;
            
        case SECTION_CAMERA:
            if(row == SECTION_CAMERA_ENABLE_PHOTO_LOCATION) {
                _enablePhotoLocation = !_enablePhotoLocation;
                if(_enablePhotoLocation) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:_enablePhotoLocation forKey:@SETTING_ADD_LOCATION_TO_PHOTOS];
                CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
            }
            else if(row == SECTION_CAMERA_KEEP_SCREEN_ON) {
                _keepScreenOn = !_keepScreenOn;
                if(_keepScreenOn) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:_keepScreenOn forKey:@SETTING_KEEPSCREENON];
                CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
            }
            else if(row == SECTION_CAMERA_VIBRATE_WATCH) {
                _vibrateWatch = !_vibrateWatch;
                if(_vibrateWatch) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:_vibrateWatch forKey:@SETTING_VIBRATE_WATCH];
                CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
            }
//            else if(row == SECTION_CAMERA_LIVE_PREVIEW) {
//                _livePreview = !_livePreview;
//                if(_livePreview) {
//                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
//                }
//                else {
//                    cell.accessoryType = UITableViewCellAccessoryNone;
//                }
//                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//                [defaults setBool:_livePreview forKey:@SETTING_CAMERA_PREVIEW];
//                CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
//            }
            else if(row == SECTION_CAMERA_TAP_MODE) {
                _tapMode = !_tapMode;
                if(_tapMode) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:_tapMode forKey:@SETTING_TAP_MODE];
                CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
            }
            break;

        case SECTION_APP:
            if(row == SECTION_APP_IN_APP_HELP) {
                _showInAppHelp = !_showInAppHelp;
                if(_showInAppHelp) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:_showInAppHelp forKey:@SETTING_FIRST_TIME_USE];
                CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
            }
            else if(row == SECTION_APP_INSTALL_WATCH_APP) {
                [self processWatchAppInstall];
            }
            else if(row == SECTION_APP_ONLINE_HELP) {
                NSURL *url = [NSURL URLWithString:@"http://pebblesnap.com/pebble-snap-for-ios/"];
                
                if (![[UIApplication sharedApplication] openURL:url])
                    DebugLog(@"%@%@",@"Failed to open url:",[url description]);
            }
            break;
    }
}

- (IBAction)flashSettingChanged:(id)sender {
    DebugLog(@"BEGIN");
    _flashMode = [(UISegmentedControl *)sender selectedSegmentIndex];
    DebugLog(@"flashMode = %lu", (unsigned long)_flashMode);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:_flashMode forKey:@SETTING_FLASH_MODE];
    CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
}

- (IBAction)backButtonClicked:(id)sender {
    DebugLog(@"BEGIN");
    [self.delegate snapWatchSettingsTableViewControllerDidFinish:self];
}

- (void)updateSelfTimerLabel {
    if(_selfTimerSeconds > 0) {
        if(_selfTimerSeconds > 1) {
            _selfTimerSecondsLabel.text = [NSString stringWithFormat:@"%lu secs", (unsigned long)_selfTimerSeconds];
        }
        else {
            _selfTimerSecondsLabel.text = [NSString stringWithFormat:@"%lu sec", (unsigned long)_selfTimerSeconds];
        }
    }
    else {
        _selfTimerSecondsLabel.text = [NSString stringWithFormat:@"Off"];
    }
}

- (IBAction)selfTimerSettingChanged:(id)sender {
    DebugLog(@"BEGIN");
    float rawValue = [_selfTimerSlider value];
    _selfTimerSeconds = round(rawValue);
    DebugLog(@"selfTimerSeconds = %lu", (unsigned long)_selfTimerSeconds);
    [self updateSelfTimerLabel];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:_selfTimerSeconds forKey:@SETTING_SELF_TIMER_SECONDS];
    CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
}

- (void)viewDidUnload {
    [self setSelfTimerLabelConstraint:nil];
    [self setSelfTimerStepperConstraint:nil];
    [self setSelfTimerSecondsLabel:nil];
    [self setSelfTimerSecondsLabel:nil];
    [self setSelfTimerSlider:nil];
    [self setFlashModeSegmentControl:nil];
    [super viewDidUnload];
}
@end
