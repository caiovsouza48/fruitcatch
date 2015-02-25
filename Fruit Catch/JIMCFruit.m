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