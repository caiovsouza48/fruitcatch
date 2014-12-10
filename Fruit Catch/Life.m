//
//  Life.m
//  Fruit Catch
//
//  Created by Caio de Souza on 09/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import "Life.h"

@implementation Life

- (id) initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (self){
        self.lifeCount = [aDecoder decodeIntegerForKey:@"lifeCount"];
        self.lifeTime = [aDecoder decodeObjectForKey:@"lifeTime"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeInteger:self.lifeCount forKey:@"lifeCount"];
    [aCoder encodeObject:self.lifeTime forKey:@"lifeTime"];
}

- (instancetype) initFromZero{
    self = [super init];
    if (self){
        self.lifeCount = 1;
        self.lifeTime = [NSDate date];
    }
    return self;
}

- (NSString *)description{
    return [NSString stringWithFormat:@"Life Object:\n Life Count = %ld - Life Time = %@",(long)self.lifeCount,self.lifeTime];
}

@end
