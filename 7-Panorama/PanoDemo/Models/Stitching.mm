//
//  Stitching.m
//  PanoDemo
//
//  Created by DJI on 15/7/30.
//

#import "Stitching.h"
#import "Cropping.h"
#import "StitchingWrapper.h"
#import "OpenCVConversion.h"
#import <UIKit/UIKit.h>

#define HIGHT_COMPRESS_RATIO 0.2
#define LOW_COMPRESS_RATIO 1.0

@implementation Stitching

+ (UIImage *)imageWithArray:(NSMutableArray *)imageArray {
    cv::Mat stitchedImage;
    cv::Mat croppedImage;
    if ([self stitchImageWithArray:imageArray andResult:stitchedImage]) {
        if ([Cropping cropWithMat:stitchedImage andResult:croppedImage]) {
            return [OpenCVConversion UIImageFromCVMat:croppedImage];
        } else {
            NSLog(@"Failed to crop image");
        }
    } else {
        NSLog(@"Failed to stitch image");
    }
    return nil;
}

+ (bool) stitchImageWithArray:(NSMutableArray*)imageArray andResult:(cv::Mat &) result {
    if (imageArray == nil || imageArray.count == 0) {
        return false;
    }

    float ratio = HIGHT_COMPRESS_RATIO;
    UIImage *image = [imageArray firstObject];
    if (image.size.height < 1000) {
        ratio = LOW_COMPRESS_RATIO;
    }

    NSMutableArray* compressedImageArray =[NSMutableArray new];
    for(UIImage *rawImage in imageArray){
        UIImage *compressedImage=[self compressedToRatio:rawImage ratio:ratio];
        [compressedImageArray addObject:compressedImage];
    }
    [imageArray removeAllObjects];
    
    
    if ([compressedImageArray count]==0) {
        NSLog (@"imageArray is empty");
        return false;
    }
    cv::vector<cv::Mat> matArray;
    
    for (id image in compressedImageArray) {
        if ([image isKindOfClass: [UIImage class]]) {
            cv::Mat matImage = [OpenCVConversion cvMat3FromUIImage:image];
            matArray.push_back(matImage);
        }
    }
    NSLog(@"Stitching...");
    if(!stitch(matArray, result)){
        return false;
    }
    
    return true;
}


//compress the photo width and height to COMPRESS_RATIO
+ (UIImage *)compressedToRatio:(UIImage *)img ratio:(float)ratio {
    CGSize compressedSize;
    compressedSize.width=img.size.width*ratio;
    compressedSize.height=img.size.height*ratio;
    UIGraphicsBeginImageContext(compressedSize);
    [img drawInRect:CGRectMake(0, 0, compressedSize.width, compressedSize.height)];
    UIImage* compressedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return compressedImage;
}

@end
