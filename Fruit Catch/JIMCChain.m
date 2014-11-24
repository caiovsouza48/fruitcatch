//
//  JIMCChain.m
//  Fruit Catch
//
//  Created by max do nascimento on 24/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import "JIMCChain.h"

@implementation JIMCChain {
    NSMutableArray *_fruits;
}

- (void)addFruit:(JIMCFruit *)fruit {
    if (_fruits == nil) {
        _fruits = [NSMutableArray array];
    }
    [_fruits addObject:fruit];
}

- (NSArray *)fruits {
    return _fruits;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"type:%ld fruits:%@", (long)self.chainType, self.fruits];
}

@end

