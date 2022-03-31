//
//  TapFlyViewController.m
//  P4Missions
//
//  Created by DJI on 15/3/16.
//  Copyright © 2016 DJI. All rights reserved.
//

#import "TapFlyViewController.h"
#import "PointingTouchView.h"
#import "DemoUtility.h"
#import "DJIScrollView.h"

@interface TapFlyViewController () <DJIVideoFeedListener>

@property (weak, nonatomic) IBOutlet UIView *fpvView;
@property (weak, nonatomic) IBOutlet PointingTouchView *touchView;
@property (weak, nonatomic) IBOutlet UIButton* startMissionBtn;
@property (weak, nonatomic) IBOutlet UIButton* stopMissionBtn;
@property (weak, nonatomic) IBOutlet UILabel* speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *horiObstacleAvoidLabel;
@property (weak, nonatomic) IBOutlet UISwitch *bypassSwitcher;
@property (weak, nonatomic) IBOutlet UISlider *speedSlider;

@property (weak, nonatomic) DJIScrollView* statusView;
@property (nonatomic, assign) BOOL isMissionRunning;
@property (nonatomic, assign) float speed;
@property (nonatomic, strong) NSMutableString *logString;
@property (nonatomic, strong) DJITapFlyMission* tapFlyMission;
@property (nonatomic) NSError *previousError;

@end

@implementation TapFlyViewController

#pragma mark - Inherited Methods

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[DJIVideoPreviewer instance] setView:self.fpvView];
    [[DJISDKManager videoFeeder].primaryVideoFeed addListener:self withQueue:nil];
    [[DJIVideoPreviewer instance] start];

    [self updateBypassStatus];
    [self updateSpeedSlider];
    
    if ([self isMissionRunning]) {
        [self shouldShowStartMissionButton:NO];
    }
    else {
        [self hideMissionControlButton];
    }
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[DJIVideoPreviewer instance] unSetView];
    [[DJISDKManager videoFeeder].primaryVideoFeed removeListener:self];

}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"TapFly Mission";
    
    self.logString = [NSMutableString string];
    self.speed = 5.0;
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onScreenTouched:)];
    [self.touchView addGestureRecognizer:tapGesture];
    
    self.startMissionBtn.layer.cornerRadius = self.startMissionBtn.frame.size.width * 0.5;
    self.startMissionBtn.layer.borderColor = [UIColor blueColor].CGColor;
    self.startMissionBtn.layer.borderWidth = 1.2;
    self.startMissionBtn.layer.masksToBounds = YES;
    
    self.stopMissionBtn.layer.cornerRadius = self.stopMissionBtn.frame.size.width * 0.5;
    self.stopMissionBtn.layer.borderColor = [UIColor blueColor].CGColor;
    self.stopMissionBtn.layer.borderWidth = 1.2;
    self.stopMissionBtn.layer.masksToBounds = YES;

    [self.speedLabel setTextColor:[UIColor whiteColor]];
    [self.horiObstacleAvoidLabel setTextColor:[UIColor whiteColor]];
    
    self.statusView = [DJIScrollView viewWithViewController:self];
    self.statusView.fontSize = 18;

    weakSelf(target);
    [[self missionOperator] addListenerToEvents:self withQueue:dispatch_get_main_queue() andBlock:^(DJITapFlyMissionEvent * _Nonnull event) {
        weakReturn(target);
        [target didReceiveEvent:event];
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Custom Methods

- (DJITapFlyMissionOperator *) missionOperator {
    return [DJISDKManager missionControl].tapFlyMissionOperator;
}

- (BOOL)isExecutingState:(DJITapFlyMissionState)state {
    return (state == DJITapFlyMissionStateExecutionResetting ||
            state == DJITapFlyMissionStateExecutionPaused ||
            state == DJITapFlyMissionStateExecuting);
}

- (BOOL)isMissionRunning {
    return [self isExecutingState:[self missionOperator].currentState];
}

-(void)updateBypassStatus {
    weakSelf(target);
    [[self missionOperator] getHorizontalObstacleBypassEnabledWithCompletion:^(BOOL boolean, NSError * _Nullable error) {
        weakReturn(target);
        if (error) {
            ShowResult(@"Get Horizontal Bypass failed: %@", error.description);
        }
        else {
            target.bypassSwitcher.on = boolean;
        }
    }];
}

-(void)updateSpeedSlider {
    weakSelf(target);
    [[self missionOperator] getAutoFlightSpeedWithCompletion:^(float floatValue, NSError * _Nullable error) {
        weakReturn(target);
        if (error) {
            ShowResult(@"Get Auto flight speed failed: %@", error.description);
        }
        else {
            target.speedLabel.text = [NSString stringWithFormat:@"%0.1fm/s", floatValue];
            target.speedSlider.value = floatValue / 10.0;
        }
    }];
}

-(void)didReceiveEvent:(DJITapFlyMissionEvent *)event {
    
    if ([self isExecutingState:event.currentState]) {
        [self shouldShowStartMissionButton:NO];
    }
    else {
        [self.touchView updatePoint:INVALID_POINT];
        [self hideMissionControlButton];
    }
    
    if ([self isExecutingState:event.previousState] &&
        ![self isExecutingState:event.currentState]) {
        if (event.error) {
            ShowResult(@"Mission interrupted with error:%@", event.error.description);
        }
        else {
            ShowResult(@"Mission Stopped without error. ");
        }
    }
    
    NSMutableString* logString = [[NSMutableString alloc] init];
    [logString appendFormat:@"Previous State:%@\n", [DemoUtility stringFromTapFlyState:event.previousState]];
    [logString appendFormat:@"Current State:%@\n", [DemoUtility stringFromTapFlyState:event.currentState]];
    
    if (event.executionState) {
        DJITapFlyExecutionState* status = event.executionState;
        CGPoint point = status.imageLocation;
        point = [DemoUtility pointFromStreamSpace:point];
        if (CGPointEqualToPoint(point, CGPointZero)) {
            point = INVALID_POINT;
        }
        
        UIColor *color = [UIColor greenColor];
        if (event.currentState == DJITapFlyMissionStateExecuting) {
            color = [[UIColor greenColor] colorWithAlphaComponent:0.5];
        }
        else if (event.currentState == DJITapFlyMissionStateExecutionResetting)
        {
            color = [[UIColor redColor] colorWithAlphaComponent:0.5];
        }
        else if (event.currentState == DJITapFlyMissionStateExecutionPaused) {
            color = [[UIColor yellowColor] colorWithAlphaComponent:0.5];
        }
        else {
            color = [[UIColor grayColor] colorWithAlphaComponent:0.5];
        }
        
        [self.touchView updatePoint:point andColor:color];
        [logString appendFormat:@"Speed:%f\n", event.executionState.speed],
        [logString appendFormat:@"ByPass Direction:%@\n", [DemoUtility stringFromByPassDirection:event.executionState.bypassDirection]];
        [logString appendFormat:@"Direction:{%f, %f, %f}\n",
         event.executionState.direction.x,
         event.executionState.direction.y,
         event.executionState.direction.z];
        [logString appendFormat:@"View Point:{%f, %f}\n", point.x, point.y];
        [logString appendFormat:@"Heading:%f", event.executionState.relativeHeading];
    }
    
    if (event.error) {
        self.previousError = event.error;
    }
    if (self.previousError) {
        [logString appendFormat:@"Error:%@\n", self.previousError.localizedDescription];
    }
    if ([self missionOperator].persistentError) {
        [logString appendFormat:@"Persistent Error:%@\n", [self missionOperator].persistentError.localizedDescription];
    }
    [self.statusView writeStatus:logString];
}

-(void) onScreenTouched:(UIGestureRecognizer*)recognizer
{
    CGPoint point = [recognizer locationInView:self.touchView];
    [self.touchView updatePoint:point andColor:[[UIColor greenColor] colorWithAlphaComponent:0.5]];
    
    point = [DemoUtility pointToStreamSpace:point withView:self.touchView];
    [self startTapFlyMissionWithPoint:point];
}

-(void) startTapFlyMissionWithPoint:(CGPoint)point
{
    if (!self.tapFlyMission) {
        self.tapFlyMission = [[DJITapFlyMission alloc] init];
    }
    self.tapFlyMission.imageLocationToCalculateDirection = point;
    self.tapFlyMission.tapFlyMode = DJITapFlyModeForward;
    [self shouldShowStartMissionButton:YES];
    
}

- (void) shouldShowStartMissionButton:(BOOL)show
{
    if (show) {
        self.startMissionBtn.hidden = NO;
        self.stopMissionBtn.hidden = YES;
    }else
    {
        self.startMissionBtn.hidden = YES;
        self.stopMissionBtn.hidden = NO;
    }
}

-(void) hideMissionControlButton
{
    [self.startMissionBtn setHidden:YES];
    [self.stopMissionBtn setHidden:YES];
}

#pragma mark IBAction Methods

- (IBAction)showStatusButtonAction:(id)sender {
    [self.statusView setHidden:NO];
    [self.statusView show];
}

-(IBAction) onSliderValueChanged:(UISlider*)slider
{
    float speed = slider.value * 10;
    self.speed = speed;
    self.speedLabel.text = [NSString stringWithFormat:@"%0.1fm/s", speed];
    if (self.isMissionRunning) {
        
        weakSelf(target);
        [[self missionOperator] setAutoFlightSpeed:self.speed withCompletion:^(NSError * _Nullable error) {
            weakReturn(target);
            if (error) {
                NSLog(@"Set TapFly Auto Flight Speed:%0.1f Error:%@", speed, error.localizedDescription);
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [target updateSpeedSlider];
            });

        }];
    }
}

-(IBAction) onSwitchValueChanged:(UISwitch*)sender
{
    weakSelf(target);
    [[self missionOperator] setHorizontalObstacleBypassEnabled:sender.isOn withCompletion:^(NSError * _Nullable error) {
        if (error) {
            ShowResult(@"Set Horizontal Obstacle Bypass Enabled failed: %@", error.description);
        }
        [target updateBypassStatus];
    }];
}

-(IBAction) onStartMissionButtonAction:(UIButton*)sender
{
    weakSelf(target);
    
    [[self missionOperator] startMission:self.tapFlyMission withCompletion:^(NSError * _Nullable error) {
        ShowResult(@"Start Mission:%@", error.localizedDescription);
        weakReturn(target);
        if (!error) {
            [target shouldShowStartMissionButton:NO];
        }else
        {
            [target.touchView updatePoint:INVALID_POINT];
            ShowResult(@"StartMission Failed: %@", error.description);
        }
    }];
}

-(IBAction) onStopMissionButtonAction:(UIButton*)sender
{
    
    weakSelf(target);

    [[self missionOperator] stopMissionWithCompletion:^(NSError * _Nullable error) {
        ShowResult(@"Stop Mission:%@", error.localizedDescription);
        if (!error) {
            weakReturn(target);
            [self.touchView updatePoint:INVALID_POINT];
            [target hideMissionControlButton];
        }else
        {
            ShowResult(@"StopMission Failed: %@", error.description);
        }

    }];

}

#pragma mark - DJIVideoFeedListener

-(void)videoFeed:(DJIVideoFeed *)videoFeed didUpdateVideoData:(NSData *)videoData {
    [[DJIVideoPreviewer instance] push:(uint8_t *)videoData.bytes length:(int)videoData.length];
}

@end
