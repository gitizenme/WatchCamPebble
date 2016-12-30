/*
     File: APLViewController.m
 Abstract: Main view controller for the application.
  Version: 2.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "SnapWatchDebug.h"
#import "APLViewController.h"
#import "DMActivityInstagram.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>


//#import "Flurry.h"

 
@interface APLViewController () <UIScrollViewDelegate>

// @property (nonatomic, weak) IBOutlet UIToolbar *toolBar;

- (void)centerScrollViewContents;
- (void)scrollViewDoubleTapped:(UITapGestureRecognizer*)recognizer;
- (void)scrollViewTwoFingerTapped:(UITapGestureRecognizer*)recognizer;

@end



@implementation APLViewController

@synthesize imageView = _imageView;
@synthesize scrollView = _scrollView;
@synthesize popoverController;
@synthesize imagePickerController;
@synthesize delegate = _delegate;
@synthesize image;
@synthesize movieUrl;
@synthesize isVideo;

- (void)centerScrollViewContents {
    DebugLog(@"BEGIN");
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    
    self.imageView.frame = contentsFrame;
}

- (void)scrollViewTwoFingerTapped:(UITapGestureRecognizer*)recognizer {
    DebugLog(@"BEGIN");
    // Zoom out slightly, capping at the minimum zoom scale specified by the scroll view
    CGFloat newZoomScale = self.scrollView.zoomScale / 1.5f;
    newZoomScale = MAX(newZoomScale, self.scrollView.minimumZoomScale);
    [self.scrollView setZoomScale:newZoomScale animated:YES];
}

- (void)scrollViewDoubleTapped:(UITapGestureRecognizer*)recognizer {
    DebugLog(@"BEGIN");
    // 1
    CGPoint pointInView = [recognizer locationInView:self.imageView];
    
    // 2
    CGFloat newZoomScale = self.scrollView.zoomScale * 1.5f;
    newZoomScale = MIN(newZoomScale, self.scrollView.maximumZoomScale);
    
    // 3
    CGSize scrollViewSize = self.scrollView.bounds.size;
    
    CGFloat w = scrollViewSize.width / newZoomScale;
    CGFloat h = scrollViewSize.height / newZoomScale;
    CGFloat x = pointInView.x - (w / 2.0f);
    CGFloat y = pointInView.y - (h / 2.0f);
    
    CGRect rectToZoomTo = CGRectMake(x, y, w, h);
    
    // 4
    [self.scrollView zoomToRect:rectToZoomTo animated:YES];
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    DebugLog(@"BEGIN");
    // Return the view that you want to zoom
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    DebugLog(@"BEGIN");
    // The scroll view has zoomed, so you need to re-center the contents
    [self centerScrollViewContents];
//    UIView* zoomView = [scrollView.delegate viewForZoomingInScrollView:scrollView];
//    CGRect zvf = zoomView.frame;
//    if(zvf.size.width < scrollView.bounds.size.width)
//    {
//        zvf.origin.x = (scrollView.bounds.size.width - zvf.size.width) / 2.0;
//    }
//    else
//    {
//        zvf.origin.x = 0.0;
//    }
//    if(zvf.size.height < scrollView.bounds.size.height)
//    {
//        zvf.origin.y = (scrollView.bounds.size.height - zvf.size.height) / 2.0;
//    }
//    else
//    {
//        zvf.origin.y = 0.0;
//    }
//    zoomView.frame = zvf;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    DebugLog(@"BEGIN");
    [super viewDidLoad];
//    [Flurry logPageView];

    // 1
//    UIImage *localImage = [UIImage imageNamed:@"photo1.png"];
//    self.imageView = [[UIImageView alloc] initWithImage:localImage];
    self.imageView.image = image;
    self.imageView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
    
    self.imageView.frame = (CGRect){.origin=CGPointMake(0.0f, 0.0f), .size=self.imageView.image.size};
    [self.scrollView addSubview:self.imageView];
    
    // 2
    self.scrollView.contentSize = self.imageView.image.size;
    
    // 3
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewDoubleTapped:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.numberOfTouchesRequired = 1;
    [self.scrollView addGestureRecognizer:doubleTapRecognizer];
    
    UITapGestureRecognizer *twoFingerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewTwoFingerTapped:)];
    twoFingerTapRecognizer.numberOfTapsRequired = 1;
    twoFingerTapRecognizer.numberOfTouchesRequired = 2;
    [self.scrollView addGestureRecognizer:twoFingerTapRecognizer];
}

- (void)setupScrollView {
    // 4
    CGRect scrollViewFrame = self.scrollView.frame;
    CGFloat scaleWidth = scrollViewFrame.size.width / self.scrollView.contentSize.width;
    CGFloat scaleHeight = scrollViewFrame.size.height / self.scrollView.contentSize.height;
    CGFloat minScale = MIN(scaleWidth, scaleHeight);
//    self.scrollView.minimumZoomScale = minScale;
//    self.scrollView.contentSize = self.imageView.image.size;
    
    // 5
//    self.scrollView.maximumZoomScale = 6.0f;
    self.scrollView.zoomScale = minScale;
//    self.scrollView.minimumZoomScale = 0.5f;

    [self.scrollView setContentMode:UIViewContentModeScaleToFill];
    [self.imageView sizeToFit];
    [self.scrollView setContentSize:CGSizeMake(self.imageView.frame.size.width, self.imageView.frame.size.height)];
    
    
    // 6
    [self centerScrollViewContents];
    
}

- (void)viewDidAppear:(BOOL)animated {
    DebugLog(@"BEGIN");
    [super viewDidAppear:animated];
    [self setupScrollView];
    
}

- (IBAction)showImagePickerForPhotoLibrary:(id)sender {
    DebugLog(@"BEGIN");
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)setImage:(UIImage *)newImage {
    DebugLog(@"BEGIN");
    if(newImage != nil) {
        image = newImage;
        self.imageView.image = image;
        [self setupScrollView];
    }
}

- (IBAction)sharePhoto:(id)sender {
    DebugLog(@"BEGIN");
    
    if (image != nil) {
        DMActivityInstagram *instagramActivity = [[DMActivityInstagram alloc] init];
        
        instagramActivity.presentFromButton = (UIBarButtonItem *)sender;
        // this will only be used if the image doesn't need to be resized.
        
        NSString *shareText = @" - my latest #selfie";
        
        NSArray *activityItems = @[image, shareText];
        NSArray *applicationActivities = @[instagramActivity];
        if(self.isVideo) {
            activityItems = @[movieUrl, shareText];
        }
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:applicationActivities];
        if(!self.isVideo) {
            activityController.excludedActivityTypes = @[UIActivityTypeMessage];
        }
        [self presentViewController:activityController animated:YES completion:nil];
    }
}

//- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
//    DebugLog(@"BEGIN");
//    if (self.popoverController.isPopoverVisible)
//        return NO;
//    else
//        return YES;
//}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    DebugLog(@"BEGIN");

    if(imagePickerController == nil) {
        imagePickerController = [[UIImagePickerController alloc] init];
    }
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: UIImagePickerControllerSourceTypeCamera];
    imagePickerController.allowsEditing = false;
    imagePickerController.delegate = self;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if(popoverController == nil) {
            UIPopoverController *aPopover = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
            aPopover.delegate = self;
            self.popoverController = aPopover;
        }
        [self.popoverController presentPopoverFromBarButtonItem:_showCameraRollButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else {
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }
}

//- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
//    DebugLog(@"BEGIN");
//    return NO;
//}

//- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
//    DebugLog(@"BEGIN");
//
//}


- (void) closePopover {
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad &&
       self.popoverController.isPopoverVisible) {
        [self.popoverController dismissPopoverAnimated:true];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}


// This method is called when an image has been chosen from the library or taken from the camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    DebugLog(@"BEGIN");
    
    [self closePopover];

    if([info valueForKey:UIImagePickerControllerMediaType] == (NSString *)kUTTypeImage) {
        self.isVideo = false;
        UIImage *newImage = [info valueForKey:UIImagePickerControllerOriginalImage];
        [self setImage:newImage];
    }
    else if([info valueForKey:UIImagePickerControllerMediaType] == (NSString *)kUTTypeMovie) {
        self.isVideo = true;
        movieUrl = [info valueForKey:UIImagePickerControllerMediaURL];
        MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:movieUrl];
        
        UIImage *thumbnail = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
        [self setImage:thumbnail];
        //Player autoplays audio on init
        [player stop];
    }
}

- (IBAction)done:(id)sender {
    DebugLog(@"BEGIN");
 
    [self closePopover];

    [[self delegate] aplViewControllerDidFinish:self];
    imagePickerController = nil;
    popoverController = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    DebugLog(@"BEGIN");

    [self closePopover];

    [self dismissViewControllerAnimated:YES completion:NULL];
    imagePickerController = nil;
    popoverController = nil;
}


@end

