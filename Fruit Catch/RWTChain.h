//
//  RWTChain.h
//  Fruit Catch
//
//  Created by max do nascimento on 24/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RWTCookie;

typedef NS_ENUM(NSUInteger, ChainType) {
    ChainTypeHorizontal,
    ChainTypeVertical,
    
    // Note: add any other shapes you want to detect to this list.
    //ChainTypeL,
    //ChainTypeT,
};

@interface RWTChain : NSObject

// The RWTCookies that are part of this chain.
@property (strong, nonatomic, readonly) NSArray *cookies;

// Whether this chain is horizontal or vertical.
@property (assign, nonatomic) ChainType chainType;

// How many points this chain is worth.
@property (assign, nonatomic) NSUInteger score;

- (void)addCookie:(RWTCookie *)cookie;

@end
