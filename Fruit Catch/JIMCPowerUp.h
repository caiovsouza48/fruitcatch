//
//  JIMCPowerUp.h
//  Fruit Catch
//
//  Created by Caio de Souza on 25/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@interface JIMCPowerUp : NSObject


@property(nonatomic) NSString *powerUpName;

@property(nonatomic) UIImage *image;

@property(nonatomic) NSUInteger level;

@property(nonatomic) float experience;

@property(nonatomic) BOOL isUpdatable;

@property(nonatomic) CGPoint position;


- (void)executePowerUpForNode:(SKNode *)node Line:(NSInteger)line Column:(NSInteger)column;

@end
