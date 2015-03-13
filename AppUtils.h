//
//  AppUtils.h
//  Fruit Catch
//
//  Created by Caio de Souza on 03/02/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#define SECRET @"0x777C4f3"
#define USER_SECRET @"0x444F@c3b0ok"
#define MULTIPLAYER_SECRET @"0xSt4rWar$"

@interface AppUtils : NSObject

+ (NSString *)getAppDataDir;

+ (NSString *)getAppLifeDir;

+ (NSString *)getAppMultiplayer;

@end
