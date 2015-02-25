//
//  ClearedLevelsSingleton.h
//  Fruit Catch
//
//  Created by Júlio Menezes Noronha on 25/02/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClearedLevelsSingleton : NSObject

@property (nonatomic) NSInteger lastLevelCleared;

+(ClearedLevelsSingleton *)sharedInstance;
-(void)updateLastLevel;

@end
