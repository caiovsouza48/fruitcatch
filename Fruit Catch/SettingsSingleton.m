//
//  SettingsSingleton.m
//  Fruit Catch
//
//  Created by Júlio Menezes Noronha on 08/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import "SettingsSingleton.h"

@implementation SettingsSingleton

static SettingsSingleton *instance;

+ (SettingsSingleton *)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SettingsSingleton alloc]initPrivate];
    });
    return instance;
    
}

- (id)initPrivate{
    self = [super init];
    if (self){
        self.music = [[NSUserDefaults standardUserDefaults] integerForKey:@"Music"];
        self.SFX = [[NSUserDefaults standardUserDefaults] integerForKey:@"SFX"];
    }
    return self;
}

-(void)musicON_OFF
{
    if(self.music == ON){
        self.music = OFF;
    }else{
        self.music = ON;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:self.music forKey:@"Music"];
}

-(void)soundON_OFF
{
    if(self.SFX == ON){
        self.SFX = OFF;
    }else{
        self.SFX = ON;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:self.SFX forKey:@"SFX"];
}

@end
