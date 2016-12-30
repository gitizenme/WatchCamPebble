//
//  SnapWatchSettingsViewController.h
//  SnapWatch
//
//  Created by Joe Chavez on 7/13/13.
//  Copyright (c) 2013 izen.me. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SnapWatchSettingsViewControllerDelegate;

@interface SnapWatchSettingsViewController : UIViewController

@property (nonatomic) long flashMode;
@property (nonatomic) int selfTimerSeconds;
@property (nonatomic) bool addLocationDataToPhotos;
@property (nonatomic) bool showHelp;
@property (nonatomic) bool keepScreenOn;
- (IBAction)locationOptionSelected:(id)sender;


@property (weak, nonatomic) IBOutlet UISwitch *addLocationDataToPhotosSwitch;
@property (weak, nonatomic) IBOutlet UISlider *selfTimerSlider;
@property (weak, nonatomic) id <SnapWatchSettingsViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UISegmentedControl *flashModeControl;
@property (weak, nonatomic) IBOutlet UILabel *selfTimerSecondsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *showHelpSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *keepScreenOnSwitch;
- (IBAction)selfTimerValueChanged:(id)sender;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)help:(id)sender;
- (IBAction)installWatchApp:(id)sender;
- (IBAction)tellAFriend:(id)sender;

@end

@protocol SnapWatchSettingsViewControllerDelegate <NSObject>
- (void)snapWatchSettingsViewControllerDidCancel:(SnapWatchSettingsViewController *)controller;
- (void)snapWatchSettingsViewControllerDidFinish:(SnapWatchSettingsViewController *)controller selfTimerSeconds:(int)seconds flashMode:(long)mode addLocationDataToPhotos:(BOOL)addLocation showHelpOption:(BOOL)showHelp keepScreenOnOption:(BOOL)keepScreenOn;
@end