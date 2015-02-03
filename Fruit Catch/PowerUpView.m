//
//  powerUpView.m
//  Fruit Catch
//
//  Created by Caio de Souza on 17/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import "powerUpView.h"

@implementation PowerUpView


- (instancetype) initWithPowerUps:(NSArray *)powerUps{
    self = [super initWithFrame:self.frame];
    if (self){
        CGRect oldRect;
        oldRect.size.width = 55 * powerUps.count;
        oldRect.size.height = 80;
        oldRect.origin.x = 280;
        oldRect.origin.y = 300;
        self.frame = oldRect;
        self.powerUps = powerUps;
    }
    return self;
}

- (instancetype) initWithPowerUpObjects:(JIMCPowerUp *)powerUp, ...{
    self = [super initWithFrame:self.frame];
    if (self){
        va_list args;
        va_start(args, powerUp);
        NSMutableArray *mutableArray = [NSMutableArray array];
        id powerUp = nil;
        while ((powerUp = va_arg(args, id))){
            [mutableArray addObject:(JIMCPowerUp *)powerUp];
        }
        va_end(args);
        self.powerUps = [mutableArray copy];
        CGRect oldRect = self.frame;
        oldRect.size.width = 55 * self.powerUps.count;
        self.frame = oldRect;
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    const CGFloat yPosition = self.center.y;
    CGFloat xPosition = 10;
    
    for (JIMCPowerUp *powerUp in self.powerUps) {
        UIImageView *imageView = [[UIImageView alloc]initWithImage:powerUp.image];
        [imageView setFrame:CGRectMake(xPosition, yPosition, 36, 36)];
        [self addSubview:imageView];
        xPosition += 36;
    }
}


@end
