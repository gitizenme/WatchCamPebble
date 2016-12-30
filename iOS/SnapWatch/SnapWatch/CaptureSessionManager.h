

#import "SnapWatchSettings.h"
#import "PebbleSnapMessageQueue.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>


#define kImageCaptured @"imageCapturedSuccessfully"
#define kImageSaved @"imageSavedSuccessfully"

@interface CaptureSessionManager : NSObject  {
    
}

@property (retain) AVCaptureVideoDataOutput *videoFrameOutput;
@property (retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (retain) AVCaptureSession *captureSession;
@property (nonatomic,retain) AVCaptureDeviceInput *videoInput;
@property (retain) AVCaptureStillImageOutput *stillImageOutput;
@property (retain) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, retain) UIImage *stillImage;
@property (nonatomic, retain) UIImage *videoImage;
@property (nonatomic, retain) NSData *imageData;
@property (nonatomic, retain) NSMutableDictionary* imageMetaData;
@property (retain) ALAssetsLibrary* assetsLibrary;
@property (retain) PebbleSnapMessageQueue* messageQueue;
@property (nonatomic) BOOL isMovieRecording;
@property (nonatomic) BOOL isLivePreview;

- (void)addVideoPreviewLayer;
- (void)addStillImageOutput;
- (void)addVideoCaptureOutput;
- (void)captureStillImage;
- (void)selectCamera:(BOOL)front flashMode:(AVCaptureFlashMode)mode;;
- (void)addVideoInputForCamera:(BOOL)front flashMode:(AVCaptureFlashMode)mode;
- (BOOL)changeToOrientation:(UIDeviceOrientation)toInterfaceOrientation;
- (void)flashMode:(AVCaptureFlashMode)mode;
- (void)saveImageToPhotosAlbum:(CLLocation *)location;
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange;
- (void)toggleMovieRecording;
- (void)livePreview:(BOOL)enable;


@end