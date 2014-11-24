//
//  JIMCSwap.m
//  Fruit Catch
//
//  Created by max do nascimento on 24/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import "JIMCSwap.h"
#import "JIMCFruit.h"

@implementation JIMCSwap

// By overriding this method you can use [NSSet containsObject:] to look for
// a matching JIMCSwap object in that collection.
- (BOOL)isEqual:(id)object {
    
    // You can only compare this object against other JIMCSwap objects.
    if (![object isKindOfClass:[JIMCSwap class]]) return NO;
    
    // Two swaps are equal if they contain the same cookie, but it doesn't
    // matter whether they're called A in one and B in the other.
    JIMCSwap *other = (JIMCSwap *)object;
    return (other.cookieA == self.cookieA && other.cookieB == self.cookieB) ||
    (other.cookieB == self.cookieA && other.cookieA == self.cookieB);
}

// If you override isEqual: you also need to override hash. The rule is that
// if two objects are equal, then their hashes must also be equal.
- (NSUInteger)hash {
    return [self.cookieA hash] ^ [self.cookieB hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ swap %@ with %@", [super description], self.cookieA, self.cookieB];
}

@end

