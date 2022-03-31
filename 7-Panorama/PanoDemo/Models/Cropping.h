//
//  Cropping.h
//  PanoDemo
//
//  Created by DJI on 15/7/31.
//

#import <Foundation/Foundation.h>

@interface Cropping : NSObject

+ (bool) cropWithMat: (const cv::Mat &)src andResult:(cv::Mat &)dest;

@end
