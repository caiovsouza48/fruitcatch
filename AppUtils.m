//
//  AppUtils.m
//  Fruit Catch
//
//  Created by Caio de Souza on 03/02/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import "AppUtils.h"

@implementation AppUtils

+ (NSString *)getAppDataDir {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"appData"];
    
}

+ (NSString *)getAppLifeDir {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"appLives"];
    
}

@end
