//
//  Match.m
//  CatRace
//
//  Created by Ray Wenderlich on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Match.h"

@implementation Match
@synthesize state = _state;
@synthesize players = _players;

- (id)initWithState:(MatchState)state players:(NSArray*)players 
{
    if ((self = [super init])) {
        _state = state;
        _players = players;
    }
    return self;
}



@end
