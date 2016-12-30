//
//  UIImage+Resizing.m
//  SnapWatch
//
//  Created by Joe Chavez on 11/16/13.
//  Copyright (c) 2013 izen.me. All rights reserved.
//

#import "UIImage+Resizing.h"

@implementation UIImage (Resizing)

/**
 * Creates a resized, autoreleased copy of the image, with the given dimensions.
 * @return an autoreleased, resized copy of the image
 */
- (UIImage*) resizedImageWithSize:(CGSize)size
{
	UIGraphicsBeginImageContext(CGSizeMake(size.width, size.height));
	
	[self drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
	
	// An autoreleased image
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return newImage;
}


/**
 * Creates a resized, autoreleased copy of the image, with the given dimensions.
 * @return an autoreleased, resized copy of the image
 */
- (UIImage*) resizedImageWithScale:(CGSize)size
{
    float oldWidth = self.size.width;
    float scaleFactor = size.width / oldWidth;
    
    float newHeight = self.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
	UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
	
	[self drawInRect:CGRectMake(0.0f, 0.0f, newWidth, newHeight)];
	
	// An autoreleased image
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return newImage;
}

- (UIImage *)squareImageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {

    
//    CGSize imageSize = image.size;
//    CGFloat width = imageSize.width;
//    CGFloat height = imageSize.height;
//    if (width != height) {
//        CGFloat newDimension = MIN(width, height);
//        CGFloat widthOffset = (width - newDimension) / 2;
//        CGFloat heightOffset = (height - newDimension) / 2;
//        UIGraphicsBeginImageContextWithOptions(CGSizeMake(newDimension, newDimension), NO, 0.);
//        [image drawAtPoint:CGPointMake(-widthOffset, -heightOffset)
//                 blendMode:kCGBlendModeCopy
//                     alpha:1.];
//        image = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//    }
//    
    double ratio;
    double delta;
    CGPoint offset;
    
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.width);
    
    //figure out if the picture is landscape or portrait, then
    //calculate scale factor and offset
    if (image.size.width > image.size.height) {
        ratio = newSize.width / image.size.width;
        delta = (ratio*image.size.width - ratio*image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize.width / image.size.height;
        delta = (ratio*image.size.height - ratio*image.size.width);
        offset = CGPointMake(0, delta/2);
    }
    
    //make the final clipping rect based on the calculated values
    CGRect clipRect = CGRectMake(-offset.x, -offset.y,
                                 (ratio * image.size.width) + delta,
                                 (ratio * image.size.height) + delta);
    
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
