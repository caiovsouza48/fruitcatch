//
//  Player.h
//  Fruit Catch
//
//  Created by Caio de Souza on 13/01/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Player : NSObject

@property (retain) NSString *playerId;
@property (retain) NSString *alias;
@property(nonatomic) int jogadaX;
@property(nonatomic) int jogadaY;
@property(nonatomic) int jogadaCount;
@property(nonatomic) float elo;


- (id)initWithPlayerId:(NSString*)playerId alias:(NSString*)alias;

- (id)initWithPlayerId:(NSString*)playerId alias:(NSString*)alias elo:(float)elo;



@end
