//
//  AppDelegate.h
//  Fruit Catch
//
//  Created by Caio de Souza on 24/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "Nextpeer/Nextpeer.h"
#import "MultiplayerGameViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate,NextpeerDelegate,NPTournamentDelegate>

@property (strong, nonatomic) UIWindow *window;

@property(nonatomic)  MultiplayerGameViewController *multiGVC;


@end

