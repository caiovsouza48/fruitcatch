//
//  MyScene.h
//  Fruit Catch
//
//  Created by max do nascimento on 24/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class JIMCLevel;
@class JIMCSwap;

@interface MyScene : SKScene

@property (strong, nonatomic) JIMCLevel *level;

// The scene handles touches. If it recognizes that the user makes a swipe,
// it will call this swipe handler. This is how it communicates back to the
// ViewController that a swap needs to take place. You can also use a delegate
// for this.
@property (copy, nonatomic) void (^swipeHandler)(JIMCSwap *swap);

- (void)addSpritesForFruits:(NSSet *)fruits;
- (void)addTiles;
- (void)removeAllFruitSprites;

- (void)animateSwap:(JIMCSwap *)swap completion:(dispatch_block_t)completion;
- (void)animateInvalidSwap:(JIMCSwap *)swap completion:(dispatch_block_t)completion;
- (void)animateMatchedFruits:(NSSet *)chains completion:(dispatch_block_t)completion;
- (void)animateFallingFruits:(NSArray *)columns completion:(dispatch_block_t)completion;
- (void)animateNewFruits:(NSArray *)columns completion:(dispatch_block_t)completion;
- (void)animateGameOver;
- (void)animateBeginGame;

@end
