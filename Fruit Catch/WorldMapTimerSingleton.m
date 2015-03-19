//
//  WorldMapTimerSingleton.m
//  Fruit Catch
//
//  Created by Caio de Souza on 18/03/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import "WorldMapTimerSingleton.h"

@implementation WorldMapTimerSingleton

static WorldMapTimerSingleton *SINGLETON = nil;

static bool isFirstAccess = YES;


#pragma mark - Public Method

+ (id)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isFirstAccess = NO;
        SINGLETON = [[super alloc] init];
    });
    
    return SINGLETON;
}

- (void)doUpdateLives{

}

- (id) init
{
    if(SINGLETON){
       // self.vidasDefaultTimer
        self.vidasCountDownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateLifeLabelTimer:) userInfo:nil repeats:YES];
        return SINGLETON;
    }
    if (isFirstAccess) {
        [self doesNotRecognizeSelector:_cmd];
    }
    self = [super init];
    return self;
}

- (void)updateLifeLabelTimer:(NSTimer *)timer{
    NSLog(@"Update no singleton chamado");
    int minute = [Life sharedInstance].timerMinutes;
    int second = [Life sharedInstance].timerSeconds;
    if((minute || second>=0) && minute>=0)
    {
        if(second==0)
        {
            minute-=1;
            [Life sharedInstance].minutesPassed += 1;
            second=59;
            [Life sharedInstance].secondsPassed = 0;
        }
        else if(minute>0)
        {
            
            second-=1;
            [Life sharedInstance].secondsPassed += 1;
        }
       
        //[self updateUserInfoWithMinute:minute  andSecond:second];
        
        [Life sharedInstance].timerMinutes = minute;
        [Life sharedInstance].timerSeconds = second;
        
    }
    else
    {
        [self.vidasCountDownTimer invalidate];
    }

    
}

- (void) reset{
    [self.vidasCountDownTimer invalidate];
    self.vidasCountDownTimer = nil;
    self.vidasCountDownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateLifeLabelTimer:) userInfo:nil repeats:YES];
}


@end
