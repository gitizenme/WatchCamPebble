//
//  UIImage+Resizing.h
//  SnapWatch
//
//  Created by Joe Chavez on 11/16/13.
//  Copyright (c) 2013 izen.me. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resizing)
- (UIImage*) resizedImageWithSize:(CGSize)size;
- (UIImage *)squareImageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end
