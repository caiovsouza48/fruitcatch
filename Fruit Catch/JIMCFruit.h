//
//  JIMCFruit.h
//  Fruit Catch
//
//  Created by max do nascimento on 24/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef struct{
    u_int16_t column;
    u_int16_t row;
    u_int16_t fruitType;
}JIMCFruitStruct;

static const NSUInteger NumFruitTypes = 5;

@interface JIMCFruit : NSObject<NSCoding>
@property (assign, nonatomic) NSInteger column;
@property (assign, nonatomic) NSInteger row;
@property (assign, nonatomic) NSUInteger fruitType;  // 1 - 6
@property (strong, nonatomic) SKSpriteNode *sprite;
@property(nonatomic) NSInteger fruitPowerUp;

+ (JIMCFruit *)fruitByStringRepresentation:(NSString *)stringRepresentation;
- (NSString *)stringRepresentation;
- (JIMCFruitStruct) structRepresentation;
- (NSString *)spriteName;
- (NSString *)highlightedSpriteName;

@end
