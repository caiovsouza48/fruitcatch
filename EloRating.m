//
//  EloRating.m
//  Fruit Catch
//
//  Created by Caio de Souza on 06/02/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import "EloRating.h"
#import "kFactor.h"

@interface EloRating(){
     int _SUPPORTED_PLAYERS;
    
    //Score Constants
    float _WIN;
    float _DRAW;
    float _LOSS;
    
    NSArray *kFactors;
    
    
}

@end

@implementation EloRating


- (id)init{
    self = [super init];
    if (self){
        _WIN = 1.0;
        _DRAW = 0.5;
        _LOSS = 0.0;
        _SUPPORTED_PLAYERS = 2;
        kFactors = [kFactor getDefaults];
    }
    return self;
}



- (int)getScoreConstantByGameResult:(JIMCGameResult) resultType{
    switch (resultType) {
        case WIN:
            return _WIN;
        case LOSS:
            return _LOSS;
        case DRAW:
            return _DRAW;
    }
    return _DRAW;
}

- (int) getNewRating:(int)rating OpponentRating:(int)opponentRating GameResult:(JIMCGameResult)resultType{
    double scoreConstant = [self getScoreConstantByGameResult:resultType];
    return [self manageNewRating:rating OponnentRating:opponentRating Score:scoreConstant];

}

- (int)manageNewRating:(int)rating OponnentRating:(int) opponentRating Score:(double)score{
    double  kFactor = [self getKFactorByRating:rating];
    double expectedScore = [self getExpectedScoreWithRating:rating OpponentRating:opponentRating];
    int newRating = [self calculateNewRating:rating Score:score ExpectedScore:expectedScore kFactor:kFactor];
    return newRating;
}


- (double) getKFactorByRating:(int)rating{
    for (int i=0; i < kFactors.count; i++) {
        kFactor *currentFactor = (kFactor *)kFactors[i];
        if ((rating >= currentFactor.startIndex) && (rating <= currentFactor.endIndex)){
            return currentFactor.value;
        }
    }
    return DEFAULT_K_FACTOR;
}



- (double) getExpectedScoreWithRating:(int)rating OpponentRating:(int)opponentRating{
    return 1.0 / (1.0 + pow(10.0, (double)(opponentRating - rating) / 400.0));
}

- (int) calculateNewRating:(int)oldRating Score:(double)score ExpectedScore:(double)expectedScore kFactor:(double)kfactor{
    return oldRating + (int) (kfactor * (score - expectedScore));
    
}

@end
