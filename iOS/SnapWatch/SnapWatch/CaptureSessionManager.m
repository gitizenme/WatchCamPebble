

#import "UIImage+Resizing.h"
#import "SnapWatchDebug.h"
#import "CaptureSessionManager.h"
#import <PebbleKit/PBBitmap.h>
#import <ImageIO/ImageIO.h>
#import "NSMutableDictionary+ImageMetadata.h"

@interface CaptureSessionManager () <AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>


@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.

@end

@implementation CaptureSessionManager


@synthesize captureSession;
@synthesize previewLayer;
@synthesize stillImageOutput;
@synthesize videoFrameOutput;
@synthesize movieFileOutput;
@synthesize stillImage;
@synthesize videoImage;
@synthesize videoInput;
@synthesize imageData;
@synthesize imageMetaData;
@synthesize assetsLibrary;
@synthesize messageQueue;
@synthesize isMovieRecording;
@synthesize isLivePreview;

AVCaptureDevice *_device;

#pragma mark Capture Session Configuration

- (id)init {
	if ((self = [super init])) {
		[self setCaptureSession:[[AVCaptureSession alloc] init]];
        [self setAssetsLibrary:[[ALAssetsLibrary alloc] init]];
        
        dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
        [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
        [self setSessionQueue:sessionQueue];
	}
	return self;
}

- (void)addVideoPreviewLayer {
	[self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:[self captureSession]]];

	[[self previewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
}

- (BOOL)changeToOrientation:(UIDeviceOrientation)toInterfaceOrientation {
    AVCaptureConnection *previewLayerConnection=self.previewLayer.connection;
    
    if ([previewLayerConnection isVideoOrientationSupported])
    {
        switch (toInterfaceOrientation)
        {
            case UIInterfaceOrientationPortrait:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                break;
            case UIInterfaceOrientationLandscapeRight:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight]; //home button on right. Refer to .h not doc
                break;
            case UIInterfaceOrientationLandscapeLeft:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft]; //home button on left. Refer to .h not doc
                break;
            default:
                [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortrait]; //for portrait upside down. Refer to .h not doc
                break;
        }
    }
    return YES;
}


- (void)flashMode:(AVCaptureFlashMode)mode {
    if(_device && _device.hasFlash && [_device isFlashModeSupported:mode]) {
        NSError *error;
        [_device lockForConfiguration:&error];
        [_device setFlashMode:mode];
        [_device unlockForConfiguration];
    }
}

-(void)livePreview:(BOOL)enable {
    isLivePreview = enable;
    if(isLivePreview) {
        [[self captureSession] addOutput:self.videoFrameOutput];
    }
    else {
        [[self captureSession] removeOutput:self.videoFrameOutput];
    }
}

- (void)selectCamera:(BOOL)front flashMode:(AVCaptureFlashMode)mode {
    NSArray *devices = [AVCaptureDevice devices];
    if ([devices count] > 1) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput;
//        AVCaptureDevicePosition position = [[videoInput device] position];
        AVCaptureDevice *frontCamera;
        AVCaptureDevice *backCamera;

        for (AVCaptureDevice *device in devices) {
            
            DebugLog(@"Device name: %@", [device localizedName]);
            
            if ([device hasMediaType:AVMediaTypeVideo]) {
                
                if ([device position] == AVCaptureDevicePositionBack) {
                    DebugLog(@"Device position : back");
                    backCamera = device;
                }
                else {
                    DebugLog(@"Device position : front");
                    frontCamera = device;
                }
            }
        }
        
        if (front) {
            newVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
            _device = frontCamera;
        }
        else {
            newVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
            _device = backCamera;
        }
        
        if(error != nil) {
            DebugLog(@"Error: %ld, description: %@, reason: %@, recovery: %@", (long)[error code], [error localizedDescription], [error localizedFailureReason], [error localizedRecoverySuggestion]);
        }
        
        if (newVideoInput != nil) {
            [[self captureSession] beginConfiguration];
            [[self captureSession] removeInput:[self videoInput]];
            if ([[self captureSession] canAddInput:newVideoInput]) {
                [[self captureSession] addInput:newVideoInput];
                [self setVideoInput:newVideoInput];
                videoInput = newVideoInput;
            } else {
                [[self captureSession] addInput:[self videoInput]];
            }
            [[self captureSession] commitConfiguration];
        } else {
            DebugLog(@"Couldn't add video input");
        }
        [self flashMode:mode];
    }
}

- (void)addVideoInputForCamera:(BOOL)front flashMode:(AVCaptureFlashMode)mode {
    DebugLog(@"BEGIN");

    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        
        DebugLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                DebugLog(@"Device position : back");
                backCamera = device;
            }
            else {
                DebugLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }
    
    NSError *error = nil;
    
    if (front) {
        _device = frontCamera;
        AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        if (!error) {
            if ([[self captureSession] canAddInput:frontFacingCameraDeviceInput]) {
                [[self captureSession] addInput:frontFacingCameraDeviceInput];
                [self setVideoInput:frontFacingCameraDeviceInput];
            } else {
                DebugLog(@"Couldn't add front facing video input");
                NSLog(@"%@", error);
            }
        }
    } else {
        _device = backCamera;
        AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        if (!error) {
            if ([[self captureSession] canAddInput:backFacingCameraDeviceInput]) {
                [[self captureSession] addInput:backFacingCameraDeviceInput];
                [self setVideoInput:backFacingCameraDeviceInput];
            } else {
                DebugLog(@"Couldn't add back facing video input");
                NSLog(@"%@", error);
            }
        }
    }
    [self flashMode:mode];

    AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    
    if (error)
    {
        NSLog(@"%@", error);
    }
    
    if ([captureSession canAddInput:audioDeviceInput])
    {
        [captureSession addInput:audioDeviceInput];
    }

}

- (void)addVideoCaptureOutput
{
    DebugLog(@"BEGIN");

    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
 
    self.videoFrameOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoFrameOutput.alwaysDiscardsLateVideoFrames = YES;
    dispatch_queue_t queue;
    queue = dispatch_queue_create("cameraQueue", NULL);
    [self.videoFrameOutput setSampleBufferDelegate:self queue:queue];
    // Set the video output to store frame in BGRA (It is supposed to be faster)
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [self.videoFrameOutput setVideoSettings:videoSettings];
    
    if(isLivePreview) {
        [[self captureSession] addOutput:self.videoFrameOutput];
    }
    
}

#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if(isLivePreview) {
        
        DebugLog(@"BEGIN");

        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        /*Get information about the image*/
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        /*Create a CGImageRef from the CVImageBufferRef*/
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        
        /*We release some components*/
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
       
        /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly).
         Same thing as for the CALayer we are not in the main thread so ...*/
        videoImage = [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
        
        /*We relase the CGImageRef*/
        CGImageRelease(newImage);
       
        /*We unlock the  image buffer*/
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    }
}

- (void)addStillImageOutput
{
    [self setStillImageOutput:[[AVCaptureStillImageOutput alloc] init]];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [[self stillImageOutput] setOutputSettings:outputSettings];
    
//    AVCaptureConnection *videoConnection = nil;
//    for (AVCaptureConnection *connection in [[self stillImageOutput] connections]) {
//        for (AVCaptureInputPort *port in [connection inputPorts]) {
//            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
//                videoConnection = connection;
//                break;
//            }
//        }
//        if (videoConnection) {
//            break;
//        }
//    }
    
    [[self captureSession] addOutput:[self stillImageOutput]];
}

- (void)saveImageToPhotosAlbum:(CLLocation *)location
{
    
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary*)imageMetaData];
    if(location != nil) {
        [metadata setLocation:location];
        DebugLog(@"attachements: %@", metadata);

    }

    [[self assetsLibrary] writeImageDataToSavedPhotosAlbum: [self imageData] metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
        if(error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kImageSaved object:nil userInfo:@{@"error": error}];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kImageSaved object:nil];
        }
    }];
}


- (BOOL)shouldAutorotate
{
	// Disable autorotation of the interface when recording is in progress.
	return ![self lockInterfaceRotation];
}

#pragma mark File Output Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    DebugLog(@"BEGIN");
   
	if (error)
		NSLog(@"%@", error);
	
    self.isMovieRecording = false;

	[self setLockInterfaceRotation:NO];
	
	// Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
	UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
	[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
	
	[[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        DebugLog(@"BEGIN");

		if (error)
			NSLog(@"%@", error);
		
		[[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:&error];
		if (error)
			NSLog(@"%@", error);
		
        [captureSession removeOutput:self.movieFileOutput];
        
		if (backgroundRecordingID != UIBackgroundTaskInvalid)
			[[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
	}];
}

- (void)toggleMovieRecording
{
    DebugLog(@"BEGIN");
    
    if(!self.isMovieRecording) {
        if ([captureSession canAddOutput:self.movieFileOutput])
        {
            DebugLog(@"ADD: movie FILE output");
            [captureSession addOutput:self.movieFileOutput];
        }
    }

	
	dispatch_async([self sessionQueue], ^{
		if (![[self movieFileOutput] isRecording])
		{
            DebugLog(@"START recording");
            self.isMovieRecording = true;

            [self setLockInterfaceRotation:YES];
            AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if ([connection isVideoStabilizationSupported]) {
                [connection setEnablesVideoStabilizationWhenAvailable:YES];
            }
            
            if ([[UIDevice currentDevice] isMultitaskingSupported])
            {
                // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
                [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
            }
            
            // Update the orientation on the movie file output video connection before starting recording.
            [[[self movieFileOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[self previewLayer] connection] videoOrientation]];
            
            // Start recording to a temporary file.
            NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"mov"]];
            [[self movieFileOutput] startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
		}
		else
		{
            DebugLog(@"STOP recording");
			[[self movieFileOutput] stopRecording];
		}
	});
}

- (void)captureStillImage
{
	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in [[self stillImageOutput] connections]) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) {
            break;
        }
	}
    
    UIDeviceOrientation deviceOrienation = [UIDevice currentDevice].orientation;
    AVCaptureVideoOrientation videoOrienation = AVCaptureVideoOrientationPortrait;
    if(UIDeviceOrientationIsLandscape(deviceOrienation)) {
        if(deviceOrienation == UIDeviceOrientationLandscapeLeft) {
            videoOrienation = AVCaptureVideoOrientationLandscapeRight;
        }
        else if(deviceOrienation == UIDeviceOrientationLandscapeRight) {
            videoOrienation = AVCaptureVideoOrientationLandscapeLeft;
        }
    }
    else if(UIDeviceOrientationIsPortrait(deviceOrienation)) {
        if(deviceOrienation == UIDeviceOrientationPortrait) {
            videoOrienation = AVCaptureVideoOrientationPortrait;
        }
        else if(deviceOrienation == UIDeviceOrientationPortraitUpsideDown) {
            videoOrienation = AVCaptureVideoOrientationPortraitUpsideDown;
        }
    }
    
    [videoConnection setVideoOrientation:videoOrienation];
	DebugLog(@"about to request a capture from: %@", [self stillImageOutput]);
	[[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:videoConnection
                                                         completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
                                                             CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
                                                             if (exifAttachments) {
                                                                 DebugLog(@"attachements: %@", exifAttachments);
                                                             } else {
                                                                 DebugLog(@"no attachments");
                                                             }
                                                             [self setImageMetaData:[[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary *)(exifAttachments)]];
                                                             NSData *imageDataLocal = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                                                             UIImage *image = [[UIImage alloc] initWithData:imageDataLocal];
                                                             [self setStillImage:image];
                                                             [self setImageData:imageDataLocal];
                                                             
                                                             if(error) {
                                                                 [[NSNotificationCenter defaultCenter] postNotificationName:kImageCaptured object:nil userInfo:@{@"error": error}];
                                                             }
                                                             else {
                                                                 [[NSNotificationCenter defaultCenter] postNotificationName:kImageCaptured object:nil];

                                                             }

                                                             
                                                         }];
}


- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
	dispatch_async([self sessionQueue], ^{
		AVCaptureDevice *device = [[self videoInput] device];
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
			{
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
			{
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}
			[device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	});
}


- (void)dealloc {
    
	[[self captureSession] stopRunning];
    
	previewLayer = nil;
	captureSession = nil;
    stillImageOutput = nil;
    stillImage = nil;    
}

@end