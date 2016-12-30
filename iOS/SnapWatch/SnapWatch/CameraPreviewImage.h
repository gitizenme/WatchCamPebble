//
//  KBPebbleImage.h
//  pebbleremote
//
//  Created by Katharine Berry on 27/05/2013.
//  Copyright (c) 2013 Katharine Berry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CameraPreviewImage : NSObject

+ (uint8_t*)ditheredBitmapFromImage:(UIImage *)image withHeight:(NSUInteger)height width:(NSUInteger)width;
+ (NSData *)ditheredBitmapDataFromImage:(UIImage *)image withHeight:(NSUInteger)height width:(NSUInteger)width;
+ (UIImage *)ditheredUIImageFromImage:(UIImage *)image withHeight:(NSUInteger)height width:(NSUInteger)width;
+ (NSData *)colorBitmapDataFromImage:(UIImage *)image withHeight:(NSUInteger)height width:(NSUInteger)width livePreview:(BOOL)isLivePreview pebbleFirmware2:(BOOL)isPebbleFirmware2;



@end
