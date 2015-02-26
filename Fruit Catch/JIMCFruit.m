//
//  JIMCFruit.m
//  Fruit Catch
//
//  Created by max do nascimento on 24/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import "JIMCFruit.h"

@implementation JIMCFruit

- (NSString *)spriteName {
    static NSString * const spriteNames[] = {
        @"laranja",
        @"morango",
        @"limao",
        @"uva",
        @"banana",
        @"cogumelo",
        @"laranja_pu_h",
        @"morango_pu_h",
        @"limao_pu_h",
        @"uva_pu_h",
        @"banana_pu_h",
    };
    
    return spriteNames[self.fruitType - 1];
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (self){
        self.sprite = [aDecoder decodeObjectForKey:@"sprite"];
        self.column = [aDecoder decodeIntegerForKey:@"column"];
        self.row = [aDecoder decodeIntegerForKey:@"row"];
        self.fruitType = [aDecoder decodeIntegerForKey:@"fruitType"];
        self.fruitPowerUp = [aDecoder decodeIntegerForKey:@"fruitPowerUp"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.sprite forKey:@"sprite"];
    [aCoder encodeInteger:self.column forKey:@"column"];
    [aCoder encodeInteger:self.row forKey:@"row"];
    [aCoder encodeInteger:self.fruitType forKey:@"fruitType"];
    [aCoder encodeInteger:self.fruitPowerUp forKey:@"fruitPowerUp"];
}

- (JIMCFruitStruct)structRepresentation{
    JIMCFruitStruct fruitStruct;
    fruitStruct.column = self.column;
    fruitStruct.row = self.row;
    fruitStruct.fruitType = self.fruitType;
    return fruitStruct;
}

- (NSString *)stringRepresentation{
    return [NSString stringWithFormat:@"%ld,%ld,%lu",(long)self.column,(long)self.row,(unsigned long)self.fruitType];
}

- (NSString *)highlightedSpriteName {
    static NSString * const highlightedSpriteNames[] = {
        @"laranja",
        @"morango",
        @"limao",
        @"uva",
        @"banana",
        @"cogumelo",
        @"laranja_pu_h",
        @"morango_pu_h",
        @"limao_pu_h",
        @"uva_pu_h",
        @"banana_pu_h",
       
    };
    
    return highlightedSpriteNames[self.fruitType - 1];
}

+ (JIMCFruit *)fruitByStringRepresentation:(NSString *)stringRepresentation{
    JIMCFruit *fruit = [[JIMCFruit alloc]init];
    NSArray *componentsArray = [stringRepresentation componentsSeparatedByString:@","];
    fruit.column = [componentsArray[0] intValue];
    fruit.row = [componentsArray[1] intValue];
    fruit.fruitType = [componentsArray[2] intValue];
    return fruit;
}

//- (BOOL)isEqual:(id)other
//{
//    if (other == self) {
//        return YES;
//    } else if (![super isEqual:other]) {
//        return NO;
//    } else {
//        JIMCFruit *otherFruit = (JIMCFruit *)other;
//        return ((self.column == otherFruit.column) && (self.row == otherFruit.row));
//    }
//}
//
//- (NSUInteger)hash
//{
//    NSUInteger hash = 0;
//    hash += self.column;
//    hash += self.row;
//    hash += [self.sprite hash];
//    hash += [self.spriteName hash];
//    return hash;
//}

- (NSString *)description {
    return [NSString stringWithFormat:@"type:%ld square:(%ld,%ld)", (long)self.fruitType, (long)self.column, (long)self.row];
}

@end