//
//  ClearedLevelsSingleton.m
//  Fruit Catch
//
//  Created by Júlio Menezes Noronha on 25/02/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import "ClearedLevelsSingleton.h"

static ClearedLevelsSingleton *instance;

@implementation ClearedLevelsSingleton

+(ClearedLevelsSingleton *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ClearedLevelsSingleton alloc]initPrivate];
    });
    return instance;
}

- (id)initPrivate{
    self = [super init];
    if (self){
        self.lastLevelCleared = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastCleared"];
    }
    return self;
}

-(void)updateLastLevel
{
    self.lastLevelCleared = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastCleared"];
    self.lastLevelCleared++;
    [[NSUserDefaults standardUserDefaults] setInteger:self.lastLevelCleared forKey:@"lastCleared"];
}

@end
