//
//  DemoUtility.m
//  P4Missions
//
//  Created by DJI on 16/3/16.
//  Copyright © 2016 DJI. All rights reserved.
//

#import "DemoUtility.h"

void ShowResult(NSString *format, ...)
{
    va_list argumentList;
    va_start(argumentList, format);
    
    NSString* message = [[NSString alloc] initWithFormat:format arguments:argumentList];
    va_end(argumentList);
    NSString * newMessage = [message hasSuffix:@":(null)"] ? [message stringByReplacingOccurrencesOfString:@":(null)" withString:@" successful!"] : message;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:newMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    });
}

@implementation DemoUtility

+ (DJICamera *) fetchCamera {
    
    if (![DJISDKManager product]) {
        return nil;
    }
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).camera;
    }
    return nil;
}

+ (DJIGimbal *)fetchGimbal
{
    if (![DJISDKManager product]) {
        return nil;
    }
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).gimbal;
    }
    return nil;
}

+ (DJIFlightController *) fetchFlightController
{
    if (![DJISDKManager product]) {
        return nil;
    }
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).flightController;
    }
    return nil;
}

+ (CGPoint) pointToStreamSpace:(CGPoint)point withView:(UIView *)view
{
    DJIVideoPreviewer* previewer = [DJIVideoPreviewer instance];
    CGRect videoFrame = [previewer frame];
    CGPoint videoPoint = [previewer convertPoint:point toVideoViewFromView:view];
    CGPoint normalized = CGPointMake(videoPoint.x/videoFrame.size.width, videoPoint.y/videoFrame.size.height);
    return normalized;
}

+ (CGPoint) pointFromStreamSpace:(CGPoint)point{
    DJIVideoPreviewer* previewer = [DJIVideoPreviewer instance];
    CGRect videoFrame = [previewer frame];
    CGPoint videoPoint = CGPointMake(point.x*videoFrame.size.width,
                                     point.y*videoFrame.size.height);
    return videoPoint;
}

+ (CGPoint) pointFromStreamSpace:(CGPoint)point withView:(UIView *)view{
    DJIVideoPreviewer* previewer = [DJIVideoPreviewer instance];
    CGRect videoFrame = [previewer frame];
    CGPoint videoPoint = CGPointMake(point.x*videoFrame.size.width, point.y*videoFrame.size.height);
    return [previewer convertPoint:videoPoint fromVideoViewToView:view];
}

+ (CGSize) sizeToStreamSpace:(CGSize)size{
    DJIVideoPreviewer* previewer = [DJIVideoPreviewer instance];
    CGRect videoFrame = [previewer frame];
    return CGSizeMake(size.width/videoFrame.size.width, size.height/videoFrame.size.height);
}

+ (CGSize) sizeFromStreamSpace:(CGSize)size{
    DJIVideoPreviewer* previewer = [DJIVideoPreviewer instance];
    CGRect videoFrame = [previewer frame];
    return CGSizeMake(size.width*videoFrame.size.width, size.height*videoFrame.size.height);
}

+ (CGRect) rectFromStreamSpace:(CGRect)rect
{
    CGPoint origin = [DemoUtility pointFromStreamSpace:rect.origin];
    CGSize size = [DemoUtility sizeFromStreamSpace:rect.size];
    return CGRectMake(origin.x, origin.y, size.width, size.height);
}

+ (CGRect) rectToStreamSpace:(CGRect)rect withView:(UIView *)view
{
    CGPoint origin = [DemoUtility pointToStreamSpace:rect.origin withView:view];
    CGSize size = [DemoUtility sizeToStreamSpace:rect.size];
    return CGRectMake(origin.x, origin.y, size.width, size.height);
}

+ (CGRect) rectFromStreamSpace:(CGRect)rect withView:(UIView *)view
{
    CGPoint origin = [DemoUtility pointFromStreamSpace:rect.origin withView:view];
    CGSize size = [DemoUtility sizeFromStreamSpace:rect.size];
    return CGRectMake(origin.x, origin.y, size.width, size.height);
}

+ (CGRect) rectWithPoint:(CGPoint)point1 andPoint:(CGPoint)point2
{
    CGFloat origin_x = MIN(point1.x, point2.x);
    CGFloat origin_y = MIN(point1.y, point2.y);
    CGFloat width = fabs(point1.x - point2.x);
    CGFloat height = fabs(point1.y - point2.y);
    CGRect rect = CGRectMake(origin_x, origin_y, width, height);
    return rect;
}

+ (NSString*) stringFromPointingExecutionState:(DJITapFlyMissionState)state
{
    switch (state) {
        case DJITapFlyMissionStateCannotStart: return @"Can Not Fly";
        case DJITapFlyMissionStateExecuting: return @"Normal Flying";
        case DJITapFlyMissionStateUnknown: return @"Unknown";
        case DJITapFlyMissionStateDisconnected: return @"Aircraft disconnected";
        case DJITapFlyMissionStateRecovering: return @"Connection recovering";
        case DJITapFlyMissionStateNotSupported: return @"Not Supported";
        case DJITapFlyMissionStateReadyToStart: return @"Ready to Start";
        case DJITapFlyMissionStateExecutionPaused: return @"Execution Paused";
        case DJITapFlyMissionStateExecutionResetting: return @"Execution Resetting";
    }
}

+ (NSString*) stringFromTrackingExecutionState:(DJIActiveTrackTargetState)state
{
    switch (state) {
        case DJIActiveTrackTargetStateTrackingWithHighConfidence: return @"Normal Tracking";
        case DJIActiveTrackTargetStateTrackingWithLowConfidence: return @"Tracking Uncertain Target";
        case DJIActiveTrackTargetStateWaitingForConfirmation: return @"Need Confirm";
        case DJIActiveTrackTargetStateCannotConfirm: return @"Waiting";
        case DJIActiveTrackTargetStateUnknown: return @"Unknown";
    }
}

+ (NSString*) stringFromByPassDirection:(DJIBypassDirection)direction
{
    switch (direction) {
        case DJIBypassDirectionNone: return @"None";
        case DJIBypassDirectionOver: return @"From Top";
        case DJIBypassDirectionLeft: return @"From Left";
        case DJIBypassDirectionRight: return @"From Right";
        case DJIBypassDirectionUnknown: return @"Unknown";
    }
    return nil;
}

+(NSString *)stringFromActiveTrackState:(DJIActiveTrackMissionState)state {
    switch (state) {
        case DJIActiveTrackMissionStateReadyToStart:
            return @"ReadyToStart";
        case DJIActiveTrackMissionStateUnknown:
            return @"Unknown";
        case DJIActiveTrackMissionStateRecovering:
            return @"Recovering";
        case DJIActiveTrackMissionStateCannotStart:
            return @"CannotStart";
        case DJIActiveTrackMissionStateDisconnected:
            return @"Disconnected";
        case DJIActiveTrackMissionStateNotSupported:
            return @"NotSupported";
        case DJIActiveTrackMissionStateCannotConfirm:
            return @"CannotConfirm";
        case DJIActiveTrackMissionStateDetectingHuman:
            return @"DetectingHuman";
        case DJIActiveTrackMissionStateAircraftFollowing:
            return @"AircraftFollowing";
        case DJIActiveTrackMissionStateOnlyCameraFollowing:
            return @"OnlyCameraFollowing";
        case DJIActiveTrackMissionStateFindingTrackedTarget:
            return @"FindingTrackedTarget";
        case DJIActiveTrackMissionStateWaitingForConfirmation:
            return @"WaitingForConfirmation";
        case DJIActiveTrackMissionStatePerformingQuickShot:
            return @"QuickShot";
    }
    return nil;
}

+(NSString *)stringFromTargetState:(DJIActiveTrackTargetState)state {
    switch (state) {
        case DJIActiveTrackTargetStateTrackingWithLowConfidence:
            return @"Low Confident";
        case DJIActiveTrackTargetStateTrackingWithHighConfidence:
            return @"High Confident";
        case DJIActiveTrackTargetStateCannotConfirm:
            return @"Cannot Confirm";
        case DJIActiveTrackTargetStateUnknown:
            return @"Unknown";
        case DJIActiveTrackTargetStateWaitingForConfirmation:
            return @"Waiting For Confirmation";
    }
    return nil;
}

+(NSString *)stringFromCannotConfirmReason:(DJIActiveTrackCannotConfirmReason)reason {
    switch (reason) {
        case DJIActiveTrackCannotConfirmReasonNone:
            return @"None";
        case DJIActiveTrackCannotConfirmReasonUnknown:
            return @"Unknown";
        case DJIActiveTrackCannotConfirmReasonTargetTooFar:
            return @"Target Too Far";
        case DJIActiveTrackCannotConfirmReasonAircraftTooLow:
            return @"Aircraft Too Low";
        case DJIActiveTrackCannotConfirmReasonTargetTooClose:
            return @"Target Too Close";
        case DJIActiveTrackCannotConfirmReasonTargetTooHigh:
            return @"Target Too High";
        case DJIActiveTrackCannotConfirmReasonUnstableTarget:
            return @"Unstable Target";
        case DJIActiveTrackCannotConfirmReasonAircraftTooHigh:
            return @"Aircraft Too High";
        case DJIActiveTrackCannotConfirmReasonBlockedByObstacle:
            return @"Blocked by Obstacle";
        case DJIActiveTrackCannotConfirmReasonGimbalAttitudeError:
            return @"Gimbal Attitude Error";
        case DJIActiveTrackCannotConfirmReasonObstacleSensorError:
            return @"Sensor Error";
    }
    return nil;
}


+(NSString *)stringFromTapFlyState:(DJITapFlyMissionState)state {
    switch (state) {
        case DJITapFlyMissionStateReadyToStart:
            return @"ReadyToStart";
        case DJITapFlyMissionStateUnknown:
            return @"Unknown";
        case DJITapFlyMissionStateExecuting:
            return @"Executing";
        case DJITapFlyMissionStateRecovering:
            return @"Recovering";
        case DJITapFlyMissionStateCannotStart:
            return @"CannotStart";
        case DJITapFlyMissionStateDisconnected:
            return @"Disconnected";
        case DJITapFlyMissionStateNotSupported:
            return @"NotSupported";
        case DJITapFlyMissionStateExecutionPaused:
            return @"ExecutionPaused";
        case DJITapFlyMissionStateExecutionResetting:
            return @"ExecutionResetting";
    }
}

@end
