//
//  OverlayView.m
//  Overlay
//
//  Created by Tom von Schwerdtner on 2/16/13.
//  Copyright (c) 2013 Tom von Schwerdtner. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "OverlayView.h"

@implementation OverlayView

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    self.alpha = 0.5;
//    self.opaque = NO;
//    self.modalView.backgroundColor = [UIColor clearColor];
//    self.photoImageView.backgroundColor = [UIColor clearColor];
//    NSString* imagePath = [[NSBundle mainBundle] pathForResource:@"HelpOverlay" ofType:@"png"];
//    UIImage* image = [[UIImage alloc] initWithContentsOfFile:imagePath];
//    self.photoImageView.image = image;

//    self.modalView.layer.shadowColor = [UIColor blackColor].CGColor;
//    self.modalView.layer.shadowOffset = CGSizeMake(0, 0);
//    self.modalView.layer.shadowOpacity = 1;
//    self.modalView.layer.shadowRadius = 2.0;
}

- (IBAction)closeButtonPressed:(id)sender {
    
    [UIView transitionWithView:self.superview
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [self removeFromSuperview];
                    }
                    completion:nil];
}

@end
