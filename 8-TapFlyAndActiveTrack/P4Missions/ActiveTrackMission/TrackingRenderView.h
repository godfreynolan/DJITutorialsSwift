//
//  TrackingRenderView.h
//  P4MissionsDemo
//
//  Created by DJI on 16/2/26.
//  Copyright © 2016年 DJI. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TrackingRenderViewDelegate <NSObject>

@optional

-(void) renderViewDidTouchAtPoint:(CGPoint)point;

-(void) renderViewDidMoveToPoint:(CGPoint)endPoint fromPoint:(CGPoint)startPoint isFinished:(BOOL)finished;

@end

@interface TrackingRenderView : UIView

@property(nonatomic, weak) id<TrackingRenderViewDelegate> delegate;

@property(nonatomic, assign) CGRect trackingRect;

@property(nonatomic, assign) BOOL isDottedLine;

@property(nonatomic, strong) NSString* text;

-(void) updateRect:(CGRect)rect fillColor:(UIColor*)fillColor;

@end
