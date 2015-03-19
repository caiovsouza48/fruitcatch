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
#import <AdColony/AdColony.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,NextpeerDelegate,NPTournamentDelegate,NPNotificationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property(nonatomic) NSDictionary *rewardData;
@property (nonatomic) NSString* plistPath;

@end

