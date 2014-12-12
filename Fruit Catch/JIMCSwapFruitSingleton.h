//
//  JIMCSwapFruitSingleton.h
//  Fruit Catch
//
//  Created by Caio de Souza on 04/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JIMCFruit.h"
#import "JIMCSwap.h"
@interface JIMCSwapFruitSingleton : NSObject

@property(nonatomic) JIMCSwap *swap;
@property(nonatomic) NSMutableSet *fruits;

+ (JIMCSwapFruitSingleton *)sharedInstance;

@end
