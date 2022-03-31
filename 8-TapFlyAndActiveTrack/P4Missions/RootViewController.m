//
//  RootViewController.m
//  P4Missions
//
//  Created by DJI on 15/3/16.
//  Copyright © 2016 DJI. All rights reserved.
//

#import "RootViewController.h"
#import "DemoUtility.h"

#define ENTER_DEBUG_MODE 0

@interface RootViewController ()<DJISDKManagerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *tapFlyMissionButton;
@property (weak, nonatomic) IBOutlet UIButton *activeTrackMissionButton;

@end

@implementation RootViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"TapFly & ActiveTrack Missions Demo";
    [self registerApp];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Custom Methods

- (void)registerApp
{
    //Please enter the App Key in the info.plist file to register the app.
    [DJISDKManager registerAppWithDelegate:self];
}

- (void)showAlertViewWithTitle:(NSString *)title withMessage:(NSString *)message
{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark DJISDKManagerDelegate Method

- (void)productConnected:(DJIBaseProduct *)product
{
    if (product) {
        [self.tapFlyMissionButton setEnabled:YES];
        [self.activeTrackMissionButton setEnabled:YES];
    }else
    {
        [self.tapFlyMissionButton setEnabled:NO];
        [self.activeTrackMissionButton setEnabled:NO];
    }
    
    //If this demo is used in China, it's required to login to your DJI account to activate the application. Also you need to use DJI Go app to bind the aircraft to your DJI account. For more details, please check this demo's tutorial.
    [[DJISDKManager userAccountManager] logIntoDJIUserAccountWithAuthorizationRequired:NO withCompletion:^(DJIUserAccountState state, NSError * _Nullable error) {
        if (error) {
            ShowResult(@"Login failed: %@", error.description);
        }
    }];
}

- (void)productDisconnected
{
    [self.tapFlyMissionButton setEnabled:NO];
    [self.activeTrackMissionButton setEnabled:NO];
}

- (void)appRegisteredWithError:(NSError *)error
{
    if (error) {
        NSString* message = @"Register App Failed! Please enter your App Key and check the network.";
        [self.tapFlyMissionButton setEnabled:NO];
        [self.activeTrackMissionButton setEnabled:NO];
        [self showAlertViewWithTitle:@"Register App" withMessage:message];

    }else
    {
        NSLog(@"registerAppSuccess");
#if ENTER_DEBUG_MODE
        [DJISDKManager enableBridgeModeWithBridgeAppIP:@"10.61.12.100"];
#else
        [DJISDKManager startConnectionToProduct];
#endif
    
    }
}

@end
