//
//  MyScene.h
//  Fruit Catch
//
//  Created by max do nascimento on 24/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//
#import <UIKit/UIKit.h>

#import <SpriteKit/SpriteKit.h>

@class MultiplayerGameViewController;
@class JIMCLevel;
@class JIMCSwap;
@class JIMCPowerUp;
@class JIMCFruit;
@class GameViewController;

static const CGFloat TileWidth = 34.0;
static const CGFloat TileHeight = 36.0;

@interface MyScene : SKScene

@property(nonatomic,weak) MultiplayerGameViewController *multiplayerViewController;

@property (nonatomic, weak) GameViewController *viewController;

@property (strong, nonatomic) JIMCLevel *level;

@property ( nonatomic) SKAction *swapSound;
@property ( nonatomic) SKAction *invalidSwapSound;
@property ( nonatomic) SKAction *matchSound;
@property ( nonatomic) SKAction *fallingFruitSound;
@property ( nonatomic) SKAction *addFruitSound;

@property (strong, nonatomic) SKNode *gameLayer;
@property (strong, nonatomic) SKNode *fruitsLayer;
@property (strong, nonatomic) SKNode *tilesLayer;
@property (strong, nonatomic) SKNode *power;
@property(nonatomic) CGPoint playerLastTouch;
@property(nonatomic) BOOL lastTouchAssigned;
@property(nonatomic) CGPoint swipeFromLastPoint;
@property(nonatomic) BOOL playerLastSwipeFromAssigned;
@property (nonatomic) BOOL shouldPlay;

// The scene handles touches. If it recognizes that the user makes a swipe,
// it will call this swipe handler. This is how it communicates back to the
// ViewController that a swap needs to take place. You can also use a delegate
// for this.
@property (copy, nonatomic) void (^swipeHandler)(JIMCSwap *swap);



- (void)addSpritesForFruits:(NSSet *)fruits;
- (void)addTiles;
- (void)removeAllFruitSprites;
- (NSSet *)executePowerUp:(JIMCPowerUp *)powerUp;
- (void)addSpritesForFruit:(JIMCFruit *)fruit;

- (void)animatePowerUp:(JIMCPowerUp *)powerUp completion:(dispatch_block_t)completion;
- (void)animateSwap:(JIMCSwap *)swap completion:(dispatch_block_t)completion;
- (void)animateInvalidSwap:(JIMCSwap *)swap completion:(dispatch_block_t)completion;
- (void)animateMatchedFruits:(NSSet *)chains completion:(dispatch_block_t)completion;
- (void)animateFallingFruits:(NSArray *)columns completion:(dispatch_block_t)completion;
- (void)animateNewFruits:(NSArray *)columns completion:(dispatch_block_t)completion;
- (void)animateGameOver;
- (void)animateBeginGame;
- (void)winLose:(BOOL)win ;

- (void)touchAtColumRowCGPoint:(CGPoint)point OpponentSwipe:(CGPoint)opponentSwipe;
- (void)animateOpponentTapAtPoint:(CGPoint)opponentMove OpponentSwipeTo:(CGPoint)opponentSwipe;

@end
