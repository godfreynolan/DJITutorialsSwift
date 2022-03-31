//
//  TrackingRenderView.m
//  P4MissionsDemo
//
//  Created by DJI on 16/2/26.
//  Copyright © 2016年 DJI. All rights reserved.
//

#import "TrackingRenderView.h"

#define TEXT_RECT_WIDTH (40)
#define TEXT_RECT_HEIGHT (40)

@interface TrackingRenderView ()

@property(nonatomic, strong) UIColor* fillColor;
@property(nonatomic, assign) CGPoint startPoint;
@property(nonatomic, assign) CGPoint endPoint;
@property(nonatomic, assign) BOOL isMoved;

@end

@implementation TrackingRenderView

#pragma mark - UIResponder Methods

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event
{
    self.isMoved = NO;
    self.startPoint = [[touches anyObject] locationInView:self];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event
{
    self.isMoved = YES;
    self.endPoint = [[touches anyObject] locationInView:self];
    if (self.delegate && [self.delegate respondsToSelector:@selector(renderViewDidMoveToPoint:fromPoint:isFinished:)]) {
        [self.delegate renderViewDidMoveToPoint:self.endPoint fromPoint:self.startPoint isFinished:NO];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event
{
    self.endPoint = [[touches anyObject] locationInView:self];
    if (self.isMoved) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(renderViewDidMoveToPoint:fromPoint:isFinished:)]) {
            [self.delegate renderViewDidMoveToPoint:self.endPoint fromPoint:self.startPoint isFinished:YES];
        }
    }
    else
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(renderViewDidTouchAtPoint:)]) {
            [self.delegate renderViewDidTouchAtPoint:self.startPoint];
        }
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.endPoint = [[touches anyObject] locationInView:self];
    if (self.isMoved) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(renderViewDidMoveToPoint:fromPoint:isFinished:)]) {
            [self.delegate renderViewDidMoveToPoint:self.endPoint fromPoint:self.startPoint isFinished:YES];
        }
    }
}

-(void) updateRect:(CGRect)rect fillColor:(UIColor*)fillColor
{
    if (CGRectEqualToRect(rect, self.trackingRect)) {
        return;
    }
    
    self.fillColor = fillColor;
    self.trackingRect = rect;
    [self setNeedsDisplay];
}

-(void) setText:(NSString *)text
{
    if ([_text isEqualToString:text]) {
        return;
    }
    
    _text = text;
    [self setNeedsDisplay];
}

-(void) drawRect:(CGRect)rect
{
    [super drawRect:rect];

    if (CGRectEqualToRect(self.trackingRect, CGRectNull)) {
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor* strokeColor = [UIColor grayColor];
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
    UIColor* fillColor = self.fillColor;
    CGContextSetFillColorWithColor(context, fillColor.CGColor); //Fill Color
    CGContextSetLineWidth(context, 1.8); //Width of line
    
    if (self.isDottedLine) {
        CGFloat lenghts[] = {10, 10};
        CGContextSetLineDash(context, 0, lenghts, 2);
    }

    CGContextAddRect(context, self.trackingRect);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    if (self.text) {
        CGFloat origin_x = self.trackingRect.origin.x + 0.5*self.trackingRect.size.width - 0.5* TEXT_RECT_WIDTH;
        CGFloat origin_y = self.trackingRect.origin.y + 0.5*self.trackingRect.size.height - 0.5* TEXT_RECT_HEIGHT;
        CGRect textRect = CGRectMake(origin_x , origin_y, TEXT_RECT_WIDTH, TEXT_RECT_HEIGHT);
        NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        UIFont* font = [UIFont boldSystemFontOfSize:35];
        NSDictionary* dic = @{NSFontAttributeName:font,NSParagraphStyleAttributeName:paragraphStyle,NSForegroundColorAttributeName:[UIColor whiteColor]};
        [self.text drawInRect:textRect withAttributes:dic];
    }
}

@end
