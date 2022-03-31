//
//  PointingTouchView.h
//  P4MissionsDemo
//
//  Created by DJI on 16/2/23.
//  Copyright © 2016年 DJI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PointingTouchView : UIView

-(void) updatePoint:(CGPoint)point;
-(void) updatePoint:(CGPoint)point andColor:(UIColor*)color;

@end
