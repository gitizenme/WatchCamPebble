

#include <wand/MagickWand.h>
#include <wand/pixel-wand.h>

#import "SnapWatchDebug.h"
#import "CameraPreviewImage.h"

static inline uint8_t pixelShade(uint8_t* i) {
    return (i[0] * 0.21) + (i[1] * 0.72) + (i[2] * 0.07);
}

static inline size_t offset(size_t width, size_t x, size_t y) {
    return (y * width) + (x); // RGBA
}

#define DIFFUSE_ERROR(a, b) if((a) < width && (b) < height) grey[(b)*width+(a)] = MAX(0, MIN(255, grey[(b)*width+(a)] + (int16_t)(0.125 * (float)err)))

@implementation CameraPreviewImage

+ (NSData*)ditheredBitmapDataFromImage:(UIImage *)image withHeight:(NSUInteger)height width:(NSUInteger)width {
    if(!image) return nil;
    
    uint8_t *output = [self ditheredBitmapFromImage:image withHeight:height width:width];
    NSData *output_data = [NSData dataWithBytes:output length:((width*height/8)+12)];
    free(output);
    return output_data;
}

+ (uint8_t*)ditheredBitmapFromImage:(UIImage *)image withHeight:(NSUInteger)height width:(NSUInteger)width {
    if(!image) return nil;
    // Resize it
    
    CGImageRef cg = image.CGImage;
    CGContextRef context = [self newBitmapRGBA8ContextFromImage:cg withHeight:height width:width];
    if(!context) return nil;
	
	CGRect rect = CGRectMake(0, 0, width, height);
	
	// Draw image into the context to get the raw image data
	CGContextDrawImage(context, rect, cg);
	
	// Get a pointer to the data
	uint8_t *bitmap = (uint8_t*)CGBitmapContextGetData(context);
    // A greyscale version
    uint8_t *grey = malloc(width * height);
    // And the output
    uint8_t *output = malloc((width * height / 8)+12);
    memset(output, 0, width * height / 8);
    memset(grey, 0, width * height);
    
    // Build up the greyscale image
    for(int i = 0; i < width * height; ++i) {
        grey[i] = pixelShade(&bitmap[i*4]);
    }
    CFRelease(context);
    // Dither it to black and white
    for(int y = 0; y < width; ++y) {
        for(int x = 0; x < height; ++x) {
            int i = offset(width, x, y); // RGBA
            uint8_t shade = grey[i];
            uint8_t actual_shade = shade > 130 ? 255 : 0;
            int16_t err = shade - actual_shade;
            //NSLog(@"err = %d; diff = %d", err, (uint8_t)(0.125 * err));
            grey[i] = actual_shade;
            
            // Dithering
            DIFFUSE_ERROR(x+1, y);
            DIFFUSE_ERROR(x+2, y);
            DIFFUSE_ERROR(x-1, y+1);
            DIFFUSE_ERROR(x, y+1);
            DIFFUSE_ERROR(x+1, y+1);
            DIFFUSE_ERROR(x, y+2);
        }
    }
    
    for(size_t i = 0; i < width*height; ++i) {
        output[(i/8)+12] |= (grey[i]&1) << ((i%8));
    }
    free(grey);
    return output;
}

+ (NSData *)colorBitmapDataFromImage:(UIImage *)image withHeight:(NSUInteger)height width:(NSUInteger)width livePreview:(BOOL)isLivePreview pebbleFirmware2:(BOOL)isPebbleFirmware2 {

    MagickWandGenesis();

    MagickWand *palette = NewMagickWand();
    MagickWand *watchImage = NewMagickWand();

    NSData *imgData=UIImagePNGRepresentation(image);
    MagickReadImageBlob(watchImage, [imgData bytes], [imgData length]);

    NSString *pebbleColorsFilePath = [[NSBundle mainBundle] pathForResource:@"pebble_colors_64" ofType:@"gif"];
    MagickReadImage(palette,
                    [pebbleColorsFilePath cStringUsingEncoding:NSASCIIStringEncoding]
                    );
    
/*
 
 Dither Grayscale
 
 convert myimage.png \
 -adaptive-resize '144x168>' \
 -fill '#FFFFFF00' -opaque none \
 -type Grayscale -colorspace Gray \
 -black-threshold 30% -white-threshold 70% \
 -ordered-dither 2x1 \
 -colors 2 -depth 1 \
 -define png:compression-level=9 -define png:compression-strategy=0 \
 -define png:exclude-chunk=all \
 myimage.pbl.png
 
 Color
 
 convert myimage.png \
 -adaptive-resize '144x168>' \
 -fill '#FFFFFF00' -opaque none \
 -dither FloydSteinberg \
 -remap pebble_colors_64.gif \
 -define png:compression-level=9 -define png:compression-strategy=0 \
 -define png:exclude-chunk=all \
 myimage.pbl.png
*/
    
    MagickSetFormat(watchImage, "png");
    MagickSetOption(watchImage, "png:compression-filter", "8");
    MagickSetOption(watchImage, "png:compression-level", "9");
    MagickSetOption(watchImage, "png:compression-strategy", "4");
    MagickSetOption(watchImage, "png:exclude-chunk", "all");

    if (isLivePreview) {
        MagickSetImageType(watchImage, GrayscaleType);
        MagickSetColorspace(watchImage, GRAYColorspace);
        MagickThresholdImageChannel(watchImage, BlackChannel, 0.30f);
        MagickOrderedPosterizeImage(watchImage, "2x1");
        MagickSetDepth(watchImage, 1);
        MagickQuantizeImage(
                            watchImage,            // MagickWand
                            2,   // Target number colors
                            GRAYColorspace,   // Colorspace
                            1,       // Optimal depth
                            MagickFalse,      // Dither
                            MagickFalse      // Quantization error
                            );
    }
    else {
        MagickRemapImage(watchImage, palette, FloydSteinbergDitherMethod);
        MagickQuantizeImage(
                            watchImage,            // MagickWand
                            4,   // Target number colors
                            RGBColorspace,   // Colorspace
                            1,       // Optimal depth
                            MagickTrue,      // Dither
                            MagickFalse      // Quantization error
                            );
        
    }
    
//    MagickAdaptiveResizeImage(watchImage, 120, 120);
    //    PixelWand *pixelWand = NewPixelWand();
    //    PixelSetRed(pixelWand, 1);
    //    PixelSetGreen(pixelWand, 1);
    //    PixelSetBlue(pixelWand, 1);
    //    MagickSetImageColor(watchImage, pixelWand);
//    MagickSetImageOpacity(watchImage, 1);
//    MagickSetImageFormat(watchImage, "png");
//    MagickSetImageProperty(watchImage, "png:exclude-chunk", "all");
//    MagickSetImageCompression(watchImage, UndefinedCompression);
//    MagickSetImageCompressionQuality(watchImage, 9);
    
    size_t my_size;
    unsigned char * my_image = MagickGetImageBlob(watchImage, &my_size);
    NSData * data = [[NSData alloc] initWithBytes:my_image length:my_size];
    
    DebugLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>> Image size: %zu", my_size);
    
    MagickRelinquishMemory(my_image);
    
    if(watchImage) {
        watchImage = DestroyMagickWand(watchImage);
    }
    if(palette) {
        palette = DestroyMagickWand(palette);
    }
  
    MagickWandTerminus();
    
    return data;
    
}


+ (UIImage *)ditheredUIImageFromImage:(UIImage *)i withHeight:(NSUInteger)height width:(NSUInteger)width {
   
    
        int kRed = 1;
        int kGreen = 2;
        int kBlue = 4;
        
        int colors = kGreen | kBlue | kRed;
        int m_width = width;
        int m_height = height;
        
        uint32_t *rgbImage = (uint32_t *) malloc(m_width * m_height * sizeof(uint32_t));
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(rgbImage, m_width, m_height, 8, m_width * 4, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        CGContextSetShouldAntialias(context, NO);
        CGContextDrawImage(context, CGRectMake(0, 0, m_width, m_height), [i CGImage]);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        
        // now convert to grayscale
        uint8_t *m_imageData = (uint8_t *) malloc(m_width * m_height);
        for(int y = 0; y < m_height; y++) {
            for(int x = 0; x < m_width; x++) {
                uint32_t rgbPixel=rgbImage[y*m_width+x];
                uint32_t sum=0,count=0;
                if (colors & kRed) {sum += (rgbPixel>>24)&255; count++;}
                if (colors & kGreen) {sum += (rgbPixel>>16)&255; count++;}
                if (colors & kBlue) {sum += (rgbPixel>>8)&255; count++;}
                m_imageData[y*m_width+x]=sum/count;
            }
        }
        free(rgbImage);
        
        // convert from a gray scale image back into a UIImage
        uint8_t *result = (uint8_t *) calloc(m_width * m_height *sizeof(uint32_t), 1);
        
        // process the image back to rgb
        for(int i = 0; i < m_height * m_width; i++) {
            result[i*4]=0;
            int val=m_imageData[i];
            result[i*4+1]=val;
            result[i*4+2]=val;
            result[i*4+3]=val;
        }
        
        // create a UIImage
        colorSpace = CGColorSpaceCreateDeviceRGB();
        context = CGBitmapContextCreate(result, m_width, m_height, 8, m_width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
        CGImageRef image = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        UIImage *resultUIImage = [UIImage imageWithCGImage:image];
        CGImageRelease(image);
        
        free(m_imageData);
        
        // make sure the data will be released by giving it to an autoreleased NSData
        [NSData dataWithBytesNoCopy:result length:m_width * m_height];
        
        return resultUIImage;

}

+ (CGContextRef) newBitmapRGBA8ContextFromImage:(CGImageRef)image withHeight:(NSUInteger)height width:(NSUInteger)width {
	CGContextRef context = NULL;
	CGColorSpaceRef colorSpace;
	uint32_t *bitmapData;
	
	colorSpace = CGColorSpaceCreateDeviceRGB();
	
	if(!colorSpace) return nil;
	
	// Allocate memory for image data
	bitmapData = (uint32_t *)malloc(width * 4 * height);
	
	if(!bitmapData) {
		CGColorSpaceRelease(colorSpace);
		return nil;
	}
	
	//Create bitmap context
	context = CGBitmapContextCreate(bitmapData,
                                    width,
                                    height,
                                    8,
                                    width * 4,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast);	// RGBA
	if(!context) {
		free(bitmapData);
	}
	
	CGColorSpaceRelease(colorSpace);
	
	return context;
}

@end
