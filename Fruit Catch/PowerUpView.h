//
//  powerUpView.h
//  Fruit Catch
//
//  Created by Caio de Souza on 17/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JIMCPowerUp.h"

@interface PowerUpView : UIView


@property(nonatomic) NSArray *powerUps;


- (instancetype)initWithPowerUps:(NSArray *)powerUps;

- (instancetype)initWithPowerUpObjects:(JIMCPowerUp *)powerUp , ...;



@end
