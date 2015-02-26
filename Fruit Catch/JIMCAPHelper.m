//
//  JIMCAPHelper.m
//  Fruit Catch
//
//  Created by Ítalo Araujo on 25/02/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import "JIMCAPHelper.h"

@implementation JIMCAPHelper

+ (JIMCAPHelper *)sharedInstance {
    static dispatch_once_t once;
    static JIMCAPHelper * sharedInstance;
    dispatch_once(&once, ^{
        NSSet * productIdentifiers = [NSSet setWithObjects:
                                      @"br.BEPiD.com.FruitCatch.001",
                                      nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

@end
