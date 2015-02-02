//
//  Match.h
//  CatRace
//
//  Created by Ray Wenderlich on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MatchStateActive = 0,
    MatchStateGameOver
} MatchState;

@interface Match : NSObject {
    MatchState _state;
    NSArray * _players;
}

@property  MatchState state;
@property (retain) NSArray *players;

- (id)initWithState:(MatchState)state players:(NSArray*)players;

@end
