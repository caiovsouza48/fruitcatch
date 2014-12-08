//
//  SettingsSingleton.h
//  Fruit Catch
//
//  Created by Júlio Menezes Noronha on 08/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#define ON 1
#define OFF 0

@interface SettingsSingleton : NSObject

@property (nonatomic) NSInteger music;
@property (nonatomic) NSInteger SFX;

+(SettingsSingleton *) sharedInstance;
-(void)musicON_OFF;
-(void)soundON_OFF;

@end
