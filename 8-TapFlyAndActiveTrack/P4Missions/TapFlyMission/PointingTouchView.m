//
//  PointingTouchView.m
//  P4MissionsDemo
//
//  Created by DJI on 16/2/23.
//  Copyright © 2016年 DJI. All rights reserved.
//

#import "PointingTouchView.h"
#import "DemoUtility.h"

@interface PointingTouchView ()

@property(nonatomic, assign) CGPoint point;
@property(nonatomic, strong) UIColor* fillColor;

@end

@implementation PointingTouchView

-(void) awakeFromNib
{
    [super awakeFromNib];
    
    self.point = INVALID_POINT;
    self.fillColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
}

-(void) updatePoint:(CGPoint)point
{
    if (CGPointEqualToPoint(self.point, point)) {
        return;
    }
    
    self.point = point;
    [self setNeedsDisplay];
}

-(void) updatePoint:(CGPoint)point andColor:(UIColor*)color
{
    if (CGPointEqualToPoint(self.point, point) && [self.fillColor isEqual:color]) {
        return;
    }
    
    self.point = point;
    self.fillColor = color;
    [self setNeedsDisplay];
}

-(void) drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if (!CGPointEqualToPoint(self.point, INVALID_POINT)) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIColor* strokeColor = [UIColor grayColor];
        CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
        UIColor* fillColor = self.fillColor;
        CGContextSetFillColorWithColor(context, fillColor.CGColor); // Fill Color
        CGContextSetLineWidth(context, 2.5);// Line width
        CGContextAddArc(context, self.point.x, self.point.y, 40, 0, 2*M_PI, 0); // Draw a circle with radius 40
        CGContextDrawPath(context, kCGPathFillStroke);
    }
}

@end
