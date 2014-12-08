//
//  JIMCSwapFruitSingleton.m
//  Fruit Catch
//
//  Created by Caio de Souza on 04/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import "JIMCSwapFruitSingleton.h"

static JIMCSwapFruitSingleton *instance;

@implementation JIMCSwapFruitSingleton

+ (JIMCSwapFruitSingleton *)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JIMCSwapFruitSingleton alloc]initPrivate];
    });
    return instance;

}

- (id)initPrivate{
    self = [super init];
    if (self){
        self.fruit = [[JIMCFruit alloc]init];
    }
    return self;
}

@end
