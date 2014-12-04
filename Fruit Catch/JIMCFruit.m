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
        @"Croissant",
        @"Cupcake",
        @"Danish",
        @"Donut",
        @"Macaroon",
        @"SugarCookie",
    };
    
    return spriteNames[self.fruitType - 1];
}

- (NSString *)highlightedSpriteName {
    static NSString * const highlightedSpriteNames[] = {
        @"Croissant-Highlighted",
        @"Cupcake-Highlighted",
        @"Danish-Highlighted",
        @"Donut-Highlighted",
        @"Macaroon-Highlighted",
        @"SugarCookie-Highlighted",
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