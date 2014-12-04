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
    };
    
    return spriteNames[self.fruitType - 1];
}

- (NSString *)highlightedSpriteName {
    static NSString * const highlightedSpriteNames[] = {
        @"laranja",
        @"morango",
        @"limao",
        @"uva",
        @"banana",
    };
    
    return highlightedSpriteNames[self.fruitType - 1];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"type:%ld square:(%ld,%ld)", (long)self.fruitType, (long)self.column, (long)self.row];
}

@end