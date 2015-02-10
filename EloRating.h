//
//  EloRating.h
//  Fruit Catch
//
//  Created by Caio de Souza on 06/02/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, JIMCGameResult){
    WIN = 1,
    LOSS = 2,
    DRAW = 3
};

@interface EloRating : NSObject

- (int) getNewRating:(int)rating OpponentRating:(int)opponentRating GameResult:(JIMCGameResult)resultType;



@end
