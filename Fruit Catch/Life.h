//
//  Life.h
//  Fruit Catch
//
//  Created by Caio de Souza on 09/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Life : NSObject<NSCoding>

@property(nonatomic) NSInteger lifeCount;

@property(nonatomic) NSDate *lifeTime;

@property(nonatomic) int timerMinutes;

@property(nonatomic) int timerSeconds;

@property(nonatomic) int minutesPassed;

@property(nonatomic) int secondsPassed;

+ (Life *)sharedInstance;

- (void)loadFromFile;

- (void)saveToFile;

@end
