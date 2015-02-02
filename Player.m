//
//  Player.m
//  Fruit Catch
//
//  Created by Caio de Souza on 13/01/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import "Player.h"

@implementation Player

- (id)initWithPlayerId:(NSString*)playerId alias:(NSString*)alias
{
    if ((self = [super init])) {
        _playerId = playerId;
        _alias = alias;
    }
    return self;
}

- (id)initWithPlayerId:(NSString*)playerId alias:(NSString*)alias elo:(float)elo
{
    if ((self = [super init])) {
        _playerId = playerId;
        _alias = alias;
        _elo = elo;
    }
    return self;
}




@end
