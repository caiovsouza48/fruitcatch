//
//  kFactor.h
//  Fruit Catch
//
//  Created by Caio de Souza on 06/02/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEFAULT_K_FACTOR 1200

@interface kFactor : NSObject

@property(nonatomic) int startIndex;

@property(nonatomic) int endIndex;

@property(nonatomic) float value;

+ (NSArray *)getDefaults;

@end
