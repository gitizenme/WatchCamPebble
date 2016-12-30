//
//  SnapWatchSettingsTableViewController.h
//  SnapWatch
//
//  Created by Joe Chavez on 8/22/13.
//  Copyright (c) 2013 izen.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@protocol SnapWatchSettingsTableViewControllerDelegate;

@interface SnapWatchSettingsTableViewController : UITableViewController<UIActionSheetDelegate>

@property (weak, nonatomic) id <SnapWatchSettingsTableViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *flashLabelConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *flashSegmentedControlConstriant;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selfTimerLabelConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *selfTimerStepperConstraint;
@property (weak, nonatomic) IBOutlet UILabel *selfTimerSecondsLabel;
@property (weak, nonatomic) IBOutlet UIStepper *selfTimerSlider;
@property (weak, nonatomic) IBOutlet UISegmentedControl *flashModeSegmentControl;
@property (strong, nonatomic) IBOutlet UITableView *settingsTableView;

@end

@protocol SnapWatchSettingsTableViewControllerDelegate <NSObject>
- (void)snapWatchSettingsTableViewControllerDidCancel:(SnapWatchSettingsTableViewController *)controller;
- (void)snapWatchSettingsTableViewControllerDidFinish:(SnapWatchSettingsTableViewController *)controller;
@end