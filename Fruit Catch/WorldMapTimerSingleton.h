//
//  WorldMapTimerSingleton.h
//  Fruit Catch
//
//  Created by Caio de Souza on 18/03/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "Life.h"
@interface WorldMapTimerSingleton : NSObject

/**
 * gets singleton object.
 * @return singleton
 */
+ (WorldMapTimerSingleton*)sharedInstance;

- (void)reset;

- (void)resetUploadLives;

@property(nonatomic) NSTimer *vidasCountDownTimer;

@property(nonatomic) NSTimer *vidasDefaultTimer;

@end
