//
//  JIMCSwapFruitSingleton.h
//  Fruit Catch
//
//  Created by Caio de Souza on 04/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JIMCFruit.h"

@interface JIMCSwapFruitSingleton : NSObject




@property(nonatomic) JIMCFruit *fruit;

+ (JIMCSwapFruitSingleton *)sharedInstance;

@end
