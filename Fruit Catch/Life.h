//
//  Life.h
//  Fruit Catch
//
//  Created by Caio de Souza on 09/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Life : NSObject<NSCoding>

@property(nonatomic) NSInteger lifeCount;

@property(nonatomic) NSDate *lifeTime;

- (instancetype) initFromZero;

@end
