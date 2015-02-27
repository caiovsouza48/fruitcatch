#import "MyScene.h"
#import "JIMCFruit.h"
#import "JIMCLevel.h"
#import "JIMCSwap.h"
#import "SettingsSingleton.h"
#import "GameOverScene.h"
#import "GameViewController.h"
#import "WorldMap.h"
#import "PowerUP.h"
#import "ClearedLevelsSingleton.h"


@interface MyScene ()

@property(nonatomic) GameOverScene *gameOverScreen;


// The column and row numbers of the fruit that the player first touched
// when he started his swipe movement.
@property (assign, nonatomic) NSInteger swipeFromColumn;
@property (assign, nonatomic) NSInteger swipeFromRow;

// Sprite that is drawn on top of the fruit that the player is trying to swap.
@property (strong, nonatomic) SKSpriteNode *selectionSprite;

@property (strong, nonatomic) SKAction *swapSound;
@property (strong, nonatomic) SKAction *invalidSwapSound;
@property (strong, nonatomic) SKAction *matchSound;
@property (strong, nonatomic) SKAction *fallingFruitSound;
@property (strong, nonatomic) SKAction *addFruitSound;

@property (strong, nonatomic) SKCropNode *cropLayer;
@property (strong, nonatomic) SKNode *maskLayer;

@property (nonatomic) BOOL win;

@end

@implementation MyScene

- (NSSet *)executePowerUp:(JIMCPowerUp *)powerUp{
    return nil;
}

- (void)animatePowerUp:(JIMCPowerUp *)powerUp completion:(dispatch_block_t)completion{
}

-(SKAction *)colorizeWithColor:(UIColor *)color BlendFactor:(NSInteger)blendFactor
{
    SKAction *colorize = [SKAction colorizeWithColor:color colorBlendFactor:blendFactor duration:0];
    return colorize;
}

- (id)initWithSize:(CGSize)size {
    
    _shouldPlay = YES;
    
    if ((self = [super initWithSize:size])) {
        
        self.anchorPoint = CGPointMake(0.5, 0.5);
        
        // Put an image on the background. Because the scene's anchorPoint is
        // (0.5, 0.5), the background image will always be centered on the screen.
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"fundo.png"];
       // background.blendMode = SKBlendModeScreen; //Clareia o fundo
        [self addChild:background];
        
        // Add a new node that is the container for all other layers on the playing
        // field. This gameLayer is also centered in the screen.
        self.gameLayer = [SKNode node];
        self.gameLayer.hidden = YES;
        [self addChild:self.gameLayer];
        
        CGPoint layerPosition = CGPointMake(-TileWidth*NumColumns/2, -TileHeight*NumRows/2);
        
        // The tiles layer represents the shape of the level. It contains a sprite
        // node for each square that is filled in.
        self.tilesLayer = [SKNode node];
        self.tilesLayer.position = layerPosition;
        [self.gameLayer addChild:self.tilesLayer];
        
        // We use a crop layer to prevent fruits from being drawn across gaps
        // in the level design.
        self.cropLayer = [SKCropNode node];
        [self.gameLayer addChild:self.cropLayer];
        
        // The mask layer determines which part of the fruitsLayer is visible.
        self.maskLayer = [SKNode node];
        self.maskLayer.position = layerPosition;
        self.cropLayer.maskNode = self.maskLayer;
        
        // This layer holds the JIMCFruit sprites. The positions of these sprites
        // are relative to the fruitsLayer's bottom-left corner.
        self.fruitsLayer = [SKNode node];
        self.fruitsLayer.position = layerPosition;
        [self.cropLayer addChild:self.fruitsLayer];
        
       // self.power = [[SKSpriteNode alloc]initWithImageNamed:@"fazendeiro"];
        //self.power.position = CGPointMake(0, 0);
        //[self.gameLayer addChild:self.power];
        
        // NSNotFound means that these properties have invalid values.
        self.swipeFromColumn = self.swipeFromRow = NSNotFound;
        
        self.selectionSprite = [SKSpriteNode node];
        
        [self preloadResources];
    }
    return self;
}

- (void)preloadResources {
    self.swapSound = [SKAction playSoundFileNamed:@"Chomp.wav" waitForCompletion:NO];
    self.invalidSwapSound = [SKAction playSoundFileNamed:@"Error.wav" waitForCompletion:NO];
    self.matchSound = [SKAction playSoundFileNamed:@"Ka-Ching.wav" waitForCompletion:NO];
    self.fallingFruitSound = [SKAction playSoundFileNamed:@"Scrape.wav" waitForCompletion:NO];
    self.addFruitSound = [SKAction playSoundFileNamed:@"Drip.wav" waitForCompletion:NO];
    
    [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
}

#pragma mark - Conversion Routines

// Converts a column,row pair into a CGPoint that is relative to the fruitLayer.
- (CGPoint)pointForColumn:(NSInteger)column row:(NSInteger)row {
    return CGPointMake(column*TileWidth + TileWidth/2, row*TileHeight + TileHeight/2);
}

// Converts a point relative to the fruitLayer into column and row numbers.
- (BOOL)convertPoint:(CGPoint)point toColumn:(NSInteger *)column row:(NSInteger *)row {
    
    // "column" and "row" are output parameters, so they cannot be nil.
    NSParameterAssert(column);
    NSParameterAssert(row);
    
    // Is this a valid location within the fruits layer? If yes,
    // calculate the corresponding row and column numbers.
    if (point.x >= 0 && point.x < NumColumns*TileWidth &&
        point.y >= 0 && point.y < NumRows*TileHeight) {
        
        *column = point.x / TileWidth;
        *row = point.y / TileHeight;
        return YES;
        
    } else {
        *column = NSNotFound;  // invalid location
        *row = NSNotFound;
        return NO;
    }
}

#pragma mark - Game Setup

- (void)addTiles {
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            
            // If there is a tile at this position, then create a new tile
            // sprite and add it to the mask layer.
            if ([self.level tileAtColumn:column row:row] != nil) {
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:@"MaskTile"];
                tileNode.position = [self pointForColumn:column row:row];
                [self.maskLayer addChild:tileNode];
            }
        }
    }
    
    // The tile pattern is drawn *in between* the level tiles. That's why
    // there is an extra column and row of them.
    for (NSInteger row = 0; row <= NumRows; row++) {
        for (NSInteger column = 0; column <= NumColumns; column++) {
            
            BOOL topLeft     = (column > 0)          && (row < NumRows) && [self.level tileAtColumn:column - 1 row:row];
            BOOL bottomLeft  = (column > 0)          && (row > 0)       && [self.level tileAtColumn:column - 1 row:row - 1];
            BOOL topRight    = (column < NumColumns) && (row < NumRows) && [self.level tileAtColumn:column     row:row];
            BOOL bottomRight = (column < NumColumns) && (row > 0)       && [self.level tileAtColumn:column     row:row - 1];
            
            // The tiles are named from 0 to 15, according to the bitmask that is
            // made by combining these four values.
            NSUInteger value = topLeft | topRight << 1 | bottomLeft << 2 | bottomRight << 3;
            
            // Values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn.
            if (value != 0 && value != 6 && value != 9) {
                NSString *name = [NSString stringWithFormat:@"Tile_%lu", (long)value];
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:name];
                CGPoint point = [self pointForColumn:column row:row];
                point.x -= TileWidth/2;
                point.y -= TileHeight/2;
                tileNode.position = point;

                //Escurece o grid
                tileNode.color = [UIColor blackColor];
                tileNode.colorBlendFactor = 0.9;
                
                [self.tilesLayer addChild:tileNode];
            }
        }
    }
}

- (void)addSpritesForFruits:(NSSet *)fruits {
    for (JIMCFruit *fruit in fruits) {
        
        // Create a new sprite for the fruit and add it to the fruitsLayer.
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[fruit spriteName]];
        sprite.position = [self pointForColumn:fruit.column row:fruit.row];
        
        [self.fruitsLayer addChild:sprite];
        fruit.sprite = sprite;
        
        // Give each fruit sprite a small, random delay. Then fade them in.
        fruit.sprite.alpha = 0;
        fruit.sprite.xScale = fruit.sprite.yScale = 0.5;
        [fruit.sprite runAction:[SKAction sequence:@[
                                                      [SKAction waitForDuration:0.25 withRange:0.5],
                                                      [SKAction group:@[
                                                                        [SKAction fadeInWithDuration:0.25],
                                                                        [SKAction scaleTo:1.0 duration:0.25]
                                                                        ]]]]];
    }
}

- (void)addSpritesForFruit:(JIMCFruit *)fruit {
    SKSpriteNode *sprite;
     NSString *namePU = nil;
//    NSLog(@"power UP = %d",(int)fruit.fruitPowerUp);
    if (fruit.fruitPowerUp == 1){
        sprite = [SKSpriteNode spriteNodeWithImageNamed:[fruit spriteName]];
    }else if (fruit.fruitPowerUp == 2) {
        switch (fruit.fruitType) {
            case 1:
                namePU = @"laranja_pu_v";
                break;
            case 2:
                namePU = @"morango_pu_v";
                break;
            case 3:
                namePU = @"limao_pu_v";
                break;
            case 4:
                namePU = @"uva_pu_v";
                break;
            case 5:
                namePU = @"banana_pu_v";
                break;

        }
        sprite = [SKSpriteNode spriteNodeWithImageNamed:namePU];
    }else if (fruit.fruitPowerUp == 3) {
            switch (fruit.fruitType) {
                case 1:
                    namePU = @"laranja_pu_h";
                    break;
                case 2:
                    namePU = @"morango_pu_h";
                    break;
                case 3:
                    namePU = @"limao_pu_h";
                    break;
                case 4:
                    namePU = @"uva_pu_h";
                    break;
                case 5:
                    namePU = @"banana_pu_h";
                    break;
            }
        sprite = [SKSpriteNode spriteNodeWithImageNamed:namePU];
    }else{
        sprite = [SKSpriteNode spriteNodeWithImageNamed:[fruit spriteName]];
    }
        // Create a new sprite for the fruit and add it to the fruitsLayer.
        //SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[fruit spriteName]];
        sprite.position = [self pointForColumn:fruit.column row:fruit.row];
        [self.fruitsLayer addChild:sprite];
        fruit.sprite = sprite;
        
        // Give each fruit sprite a small, random delay. Then fade them in.
        fruit.sprite.alpha = 0;
        fruit.sprite.xScale = fruit.sprite.yScale = 0.5;
        
        [fruit.sprite runAction:[SKAction sequence:@[
                                                     [SKAction waitForDuration:0.25 withRange:0.5],
                                                     [SKAction group:@[
                                                                       [SKAction fadeInWithDuration:0.25],
                                                                       [SKAction scaleTo:1.0 duration:0.25]
                                                                       ]]]]];
}


- (void)removeAllFruitSprites {
    [self.fruitsLayer removeAllChildren];
}

#pragma mark - Detecting Swipes

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // Convert the touch location to a point relative to the fruitsLayer.
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.fruitsLayer];
    
    CGPoint locationGameOverScreen = [touch locationInNode:self.gameOverScreen];
    SKNode *no = [self.gameOverScreen nodeAtPoint:locationGameOverScreen];
    
    if ([no.name isEqualToString:@"retry"]) {
        
        SKAction *acaoDescer = [SKAction moveToX:500 duration:0.5];
        
        _shouldPlay = YES;
        [self.gameOverScreen runAction:acaoDescer];
        [self removeAllFruitSprites];
        NSSet *newFruits = [self.level shuffle];
        [self addSpritesForFruits:newFruits];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"zerarRetryNotification" object:nil];
        
    }else if ([no.name isEqualToString:@"next"]){
        //Obtem o nível atual
//        NSArray *a = [self.viewController.levelString componentsSeparatedByString:@"Level_"];
//        NSInteger i = [[a objectAtIndex:1] integerValue];
        
    }else if ([no.name isEqualToString:@"menu"]){
        NSLog(@"Menu Button Clicked");
        [self.viewController back];
        
    }
    
    
    // If the touch is inside a square, then this might be the start of a
    // swipe motion.
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        
        // The touch must be on a fruit, not on an empty tile.
        JIMCFruit *fruit = [self.level fruitAtColumn:column row:row];
        if (fruit != nil) {
            
            // Remember in which column and row the swipe started, so we can compare
            // them later to find the direction of the swipe. This is also the first
            // fruit that will be swapped.
            self.swipeFromColumn = column;
            self.swipeFromRow = row;
            
            [self showSelectionIndicatorForFruit:fruit];
        }
    }
}

- (void)touchAtColumRowCGPoint:(CGPoint)point{
    // Convert the touch location to a point relative to the fruitsLayer.
    
    // If the touch is inside a square, then this might be the start of a
    // swipe motion.
    NSInteger column = point.x , row = point.y;
    // The touch must be on a fruit, not on an empty tile.
    JIMCFruit *fruit = [self.level fruitAtColumn:point.x row:point.y];
    if (fruit != nil) {
        
        // Remember in which column and row the swipe started, so we can compare
        // them later to find the direction of the swipe. This is also the first
        // fruit that will be swapped.
        self.swipeFromColumn = column;
        self.swipeFromRow = row;
        
        [self showSelectionIndicatorForFruit:fruit];
    }
    if (self.swipeFromColumn == NSNotFound) return;
    
   
    //[self.power setPosition:location];
   
        
        // Figure out in which direction the player swiped. Diagonal swipes
        // are not allowed.
        NSInteger horzDelta = 0, vertDelta = 0;
        if (column < self.swipeFromColumn) {          // swipe left
            horzDelta = -1;
        } else if (column > self.swipeFromColumn) {   // swipe right
            horzDelta = 1;
        } else if (row < self.swipeFromRow) {         // swipe down
            vertDelta = -1;
        } else if (row > self.swipeFromRow) {         // swipe up
            vertDelta = 1;
        }
        
        // Only try swapping when the user swiped into a new square.
        if (horzDelta != 0 || vertDelta != 0) {
            
            [self trySwapHorizontal:horzDelta vertical:vertDelta];
            [self hideSelectionIndicator];
            
            // Ignore the rest of this swipe motion from now on. Just setting
            // swipeFromColumn is enough; no need to set swipeFromRow as well.
            self.swipeFromColumn = NSNotFound;
            self.playerLastTouch = (CGPoint){column,row};
        }

    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // If swipeFromColumn is NSNotFound then either the swipe began outside
    // the valid area or the game has already swapped the fruits and we need
    // to ignore the rest of the motion.
    
    if (self.swipeFromColumn == NSNotFound) return;
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.fruitsLayer];
    //[self.power setPosition:location];
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        
        // Figure out in which direction the player swiped. Diagonal swipes
        // are not allowed.
        NSInteger horzDelta = 0, vertDelta = 0;
        if (column < self.swipeFromColumn) {          // swipe left
            horzDelta = -1;
        } else if (column > self.swipeFromColumn) {   // swipe right
            horzDelta = 1;
        } else if (row < self.swipeFromRow) {         // swipe down
            vertDelta = -1;
        } else if (row > self.swipeFromRow) {         // swipe up
            vertDelta = 1;
        }
        
        // Only try swapping when the user swiped into a new square.
        if (horzDelta != 0 || vertDelta != 0) {
            
            [self trySwapHorizontal:horzDelta vertical:vertDelta];
            [self hideSelectionIndicator];
            
            // Ignore the rest of this swipe motion from now on. Just setting
            // swipeFromColumn is enough; no need to set swipeFromRow as well.
            self.swipeFromColumn = NSNotFound;
            self.playerLastTouch = (CGPoint){column,row};
        }
    }
}

- (void)trySwapHorizontal:(NSInteger)horzDelta vertical:(NSInteger)vertDelta {
    
    // We get here after the user performs a swipe. This sets in motion a whole
    // chain of events: 1) swap the fruits, 2) remove the matching lines, 3)
    // drop new fruits into the screen, 4) check if they create new matches,
    // and so on.
    
    NSInteger toColumn = self.swipeFromColumn + horzDelta;
    NSInteger toRow = self.swipeFromRow + vertDelta;
    
    // Going outside the bounds of the array? This happens when the user swipes
    // over the edge of the grid. We should ignore such swipes.
    if (toColumn < 0 || toColumn >= NumColumns) return;
    if (toRow < 0 || toRow >= NumRows) return;
    
    // Can't swap if there is no fruit to swap with. This happens when the user
    // swipes into a gap where there is no tile.
    JIMCFruit *toFruit = [self.level fruitAtColumn:toColumn row:toRow];
    if (toFruit == nil) return;
    
    JIMCFruit *fromFruit = [self.level fruitAtColumn:self.swipeFromColumn row:self.swipeFromRow];
    
    // Communicate this swap request back to the ViewController.
    if (self.swipeHandler != nil) {
        JIMCSwap *swap = [[JIMCSwap alloc] init];
        swap.fruitA = fromFruit;
        swap.fruitB = toFruit;
        //Testando aki
        if (horzDelta!=0) {
            swap.vertical = NO;
        }else if(vertDelta!= 0){
            swap.vertical = YES;
        }
        self.swipeHandler(swap);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // Remove the selection indicator with a fade-out. We only need to do this
    // when the player didn't actually swipe.
    if (self.selectionSprite.parent != nil && self.swipeFromColumn != NSNotFound) {
        [self hideSelectionIndicator];
    }
    
    // If the gesture ended, regardless of whether if was a valid swipe or not,
    // reset the starting column and row numbers.
    self.swipeFromColumn = self.swipeFromRow = NSNotFound;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

#pragma mark - Selection Indicator

- (void)showSelectionIndicatorForFruit:(JIMCFruit *)fruit {
    
    // If the selection indicator is still visible, then first remove it.
    if (self.selectionSprite.parent != nil) {
        [self.selectionSprite removeFromParent];
    }
    
    // Add the selection indicator as a child to the fruit that the player
    // tapped on and fade it in. Note: simply setting the texture on the sprite
    // doesn't give it the correct size; using an SKAction does.
    SKTexture *texture = [SKTexture textureWithImageNamed:[fruit highlightedSpriteName]];
    self.selectionSprite.size = texture.size;
    [self.selectionSprite runAction:[SKAction setTexture:texture]];
    
    [fruit.sprite addChild:self.selectionSprite];
    self.selectionSprite.alpha = 1.0;
}

- (void)hideSelectionIndicator {
    [self.selectionSprite runAction:[SKAction sequence:@[
                                                         [SKAction fadeOutWithDuration:0.3],
                                                         [SKAction removeFromParent]]]];
}



#pragma mark - Animations

- (void)animateSwap:(JIMCSwap *)swap completion:(dispatch_block_t)completion {
    
    // Put the fruit you started with on top.
    swap.fruitA.sprite.zPosition = 100;
    swap.fruitB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.3;
    
    SKAction *moveA = [SKAction moveTo:swap.fruitB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    [swap.fruitA.sprite runAction:[SKAction sequence:@[moveA, [SKAction runBlock:completion]]]];
    
    SKAction *moveB = [SKAction moveTo:swap.fruitA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    [swap.fruitB.sprite runAction:moveB];
    
    if([SettingsSingleton sharedInstance].SFX == ON){
        [self runAction:self.swapSound];
    }
}

- (void)animateInvalidSwap:(JIMCSwap *)swap completion:(dispatch_block_t)completion {
    swap.fruitA.sprite.zPosition = 100;
    swap.fruitB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.2;
    
    SKAction *moveA = [SKAction moveTo:swap.fruitB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    
    SKAction *moveB = [SKAction moveTo:swap.fruitA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    
    [swap.fruitA.sprite runAction:[SKAction sequence:@[moveA, moveB, [SKAction runBlock:completion]]]];
    [swap.fruitB.sprite runAction:[SKAction sequence:@[moveB, moveA]]];
    
    if([SettingsSingleton sharedInstance].SFX == ON){
        [self runAction:self.invalidSwapSound];
    }
}

- (void)animateMatchedFruits:(NSSet *)chains completion:(dispatch_block_t)completion {
    
    for (JIMCChain *chain in chains) {
        [self animateScoreForChain:chain];
        for (JIMCFruit *fruit in chain.fruits) {
            if ([fruit isKindOfClass:[JIMCFruit class]]){
                if (fruit.sprite != nil) {
                    
                    // Animação das explosões das frutas
                    SKEmitterNode *emitter = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"MyParticle" ofType:@"sks"]];
                    emitter.zPosition = 600;
                    emitter.position = CGPointMake(0, 0);
                    [fruit.sprite addChild:emitter];
                    
                    SKAction *scaleAction = [SKAction scaleTo:0.1 duration:0.3];
                    SKAction *acao = [SKAction fadeAlphaTo:0 duration:0.3];

                    scaleAction.timingMode = SKActionTimingEaseOut;
                    [fruit.sprite runAction:[SKAction sequence:@[scaleAction, [SKAction removeFromParent]]]];
                    [emitter runAction:[SKAction sequence:@[acao, [SKAction removeFromParent]]]];
                    
                    // It may happen that the same JIMCFruit object is part of two chains
                    // (L-shape match). In that case, its sprite should only be removed
                    // once.
                    fruit.sprite = nil;
                }
            }
        }
    }
    
    if([SettingsSingleton sharedInstance].SFX == ON){
        [self runAction:self.matchSound];
    }
    
    
    

    // Continue with the game after the animations have completed.
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:0.3],
                                         [SKAction runBlock:completion]
                                         ]]];

}
- (void)animateMatchedFruitsType:(NSSet *)chains completion:(dispatch_block_t)completion {
    
    for (JIMCChain *chain in chains) {
        [self animateScoreForChain:chain];
        for (JIMCFruit *fruit in chain.fruits) {
            if ([fruit isKindOfClass:[JIMCFruit class]]){
                if (fruit.sprite != nil) {
                    SKAction *scaleAction = [SKAction scaleTo:0.1 duration:0.3];
                    scaleAction.timingMode = SKActionTimingEaseOut;
                    [fruit.sprite runAction:[SKAction sequence:@[scaleAction, [SKAction removeFromParent]]]];
                    
                    // It may happen that the same JIMCFruit object is part of two chains
                    // (L-shape match). In that case, its sprite should only be removed
                    // once.
                    fruit.sprite = nil;
                }
            }
        }
    }
    
    if([SettingsSingleton sharedInstance].SFX == ON){
        [self runAction:self.matchSound];
    }
    
    // Continue with the game after the animations have completed.
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:0.3],
                                         [SKAction runBlock:completion]
                                         ]]];
}


- (void)animateScoreForChain:(JIMCChain *)chain {
    // Figure out what the midpoint of the chain is.
    JIMCFruit *firstFruit = [chain.fruits firstObject];
    JIMCFruit *lastFruit = [chain.fruits lastObject];
    
    CGPoint centerPosition = CGPointMake(
                                         (firstFruit.sprite.position.x + lastFruit.sprite.position.x)/2,
                                         (firstFruit.sprite.position.y + lastFruit.sprite.position.y)/2 - 8);
    
    // Add a label for the score that slowly floats up.
    SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
    scoreLabel.fontSize = 16;
    scoreLabel.text = [NSString stringWithFormat:@"%lu", (long)chain.score];
    scoreLabel.position = centerPosition;
    scoreLabel.zPosition = 300;
    [self.fruitsLayer addChild:scoreLabel];
    
    SKAction *moveAction = [SKAction moveBy:CGVectorMake(0, 3) duration:0.7];
    moveAction.timingMode = SKActionTimingEaseOut;
    [scoreLabel runAction:[SKAction sequence:@[
                                               moveAction,
                                               [SKAction removeFromParent]
                                               ]]];
}

- (void)animateFallingFruits:(NSArray *)columns completion:(dispatch_block_t)completion {
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        
        [array enumerateObjectsUsingBlock:^(JIMCFruit *fruit, NSUInteger idx, BOOL *stop) {
            CGPoint newPosition = [self pointForColumn:fruit.column row:fruit.row];
            
            // The further away from the hole you are, the bigger the delay
            // on the animation.
            NSTimeInterval delay = 0.1 + 0.14*idx;
            
            // Calculate duration based on far fruit has to fall (0.1 seconds
            // per tile).
            NSTimeInterval duration = ((fruit.sprite.position.y - newPosition.y) / TileHeight) * 0.1;
            longestDuration = MAX(longestDuration, duration + delay);
            
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            if([SettingsSingleton sharedInstance].SFX == ON){
                [fruit.sprite runAction:[SKAction sequence:@[
                                                              [SKAction waitForDuration:delay],
                                                              [SKAction group:@[moveAction, self.fallingFruitSound]]]]];
            }else{
                [fruit.sprite runAction:[SKAction sequence:@[
                                                             [SKAction waitForDuration:delay],
                                                             [SKAction group:@[moveAction]]]]];
            }
        }];
    }
    
    // Wait until all the fruits have fallen down before we continue.
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:longestDuration],
                                         [SKAction runBlock:completion]
                                         ]]];
}

- (void)animateNewFruits:(NSArray *)columns completion:(dispatch_block_t)completion {
    
    // We don't want to continue with the game until all the animations are
    // complete, so we calculate how long the longest animation lasts, and
    // wait that amount before we trigger the completion block.
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        
        // The new sprite should start out just above the first tile in this column.
        // An easy way to find this tile is to look at the row of the first fruit
        // in the array, which is always the top-most one for this column.
        NSInteger startRow = ((JIMCFruit *)[array firstObject]).row + 1;
        
        [array enumerateObjectsUsingBlock:^(JIMCFruit *fruit, NSUInteger idx, BOOL *stop) {
            
            // Create a new sprite for the fruit.
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[fruit spriteName]];
            sprite.position = [self pointForColumn:fruit.column row:startRow];
            [self.fruitsLayer addChild:sprite];
            fruit.sprite = sprite;
            
            // Give each fruit that's higher up a longer delay, so they appear to
            // fall after one another.
            NSTimeInterval delay = 0.1 + 0.14*([array count] - idx - 1);
            
            // Calculate duration based on far the fruit has to fall.
            NSTimeInterval duration = (startRow - fruit.row) * 0.1;
            longestDuration = MAX(longestDuration, duration + delay);
            
            // Animate the sprite falling down. Also fade it in to make the sprite
            // appear less abruptly.
            CGPoint newPosition = [self pointForColumn:fruit.column row:fruit.row];
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            fruit.sprite.alpha = 0;
            if([SettingsSingleton sharedInstance].SFX == ON){
                [fruit.sprite runAction:[SKAction sequence:@[
                                                              [SKAction waitForDuration:delay],
                                                              [SKAction group:@[
                                                                                [SKAction fadeInWithDuration:0.05], moveAction, self.addFruitSound]]]]];
            }else{
                [fruit.sprite runAction:[SKAction sequence:@[
                                                             [SKAction waitForDuration:delay],
                                                             [SKAction group:@[
                                                                               [SKAction fadeInWithDuration:0.05], moveAction]]]]];
            }
        }];
    }
    
    // Wait until the animations are done before we continue.
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:longestDuration],
                                         [SKAction runBlock:completion]
                                         ]]];
}

- (void)animateGameOver {
    
    //Texto vitória/derrota
    SKLabelNode *winLose = [[SKLabelNode alloc] initWithFontNamed:@"Chewy"];
    winLose.fontSize     = 40;
    winLose.fontColor    = [SKColor whiteColor];
    winLose.zPosition    = 50;
    winLose.position     = CGPointMake(0, 110);
    
    if(_win){
        winLose.text = @"Vitória";
    }else{
        winLose.text = @"Derrota";
    }
    
    SKLabelNode *scoreLabel = [[SKLabelNode alloc] initWithFontNamed:@"Chewy"];
    scoreLabel.fontSize     = 40;
    scoreLabel.fontColor    = [SKColor whiteColor];
    scoreLabel.zPosition    = 50;
    scoreLabel.position     = CGPointMake(0, 0);
    scoreLabel.text         = [NSString stringWithFormat:@"%d",(int)self.viewController.score];
    
    // Ação dos botões
    SKAction *acaoDescer = [SKAction moveToX:CGRectGetMidX(self.frame) duration:0.5];
    
    self.gameOverScreen = [[GameOverScene alloc]init];
    self.gameOverScreen.size = CGSizeMake(self.frame.size.width, self.frame.size.height/2);
    self.gameOverScreen.color = [SKColor clearColor];
    self.gameOverScreen.position = CGPointMake(CGRectGetMidX(self.frame)-500, CGRectGetMidY(self.frame));

    //Imagem de fundo
    SKSpriteNode *background = [[SKSpriteNode alloc]initWithImageNamed:@"retangulo_generico"];
    background.name = @"background";
    background.zPosition = 49;
    [self.gameOverScreen addChild:background];
    
    //Kasco
    SKSpriteNode *kasco;
    
    // Imagem dos botões
    self.gameOverScreen.retry = [[SKSpriteNode alloc]initWithImageNamed:@"botao_jogar_novamente"];
    self.gameOverScreen.menu  = [[SKSpriteNode alloc]initWithImageNamed:@"botao_menu"];
    
    if(_win){
        kasco = [[SKSpriteNode alloc]initWithImageNamed:@"fazendeiro_feliz_pop_over"];
        self.gameOverScreen.next = [[SKSpriteNode alloc]initWithImageNamed:@"botao_proxima_fase"];
    }else{
        kasco = [[SKSpriteNode alloc]initWithImageNamed:@"fazendeiro_triste_cesta_vazia"];
    }

    // Posição dos botões
    CGFloat yPos = self.gameOverScreen.position.y - 60;
    kasco.position = CGPointMake(-90, -80);
    
    if(_win){
        self.gameOverScreen.menu.position  = CGPointMake(-10, yPos);
        self.gameOverScreen.retry.position = CGPointMake(55, yPos);
        self.gameOverScreen.next.position  = CGPointMake(120, yPos);
    }else{
        self.gameOverScreen.menu.position  = CGPointMake(20, yPos);
        self.gameOverScreen.retry.position = CGPointMake(100, yPos);
    }
    
    // Nome dos botões
    self.gameOverScreen.retry.name = @"retry";
    self.gameOverScreen.menu.name  = @"menu";
    kasco.name = @"kasco";
    
    if(_win){
        self.gameOverScreen.next.name = @"next";
    }
    
    // zPosition dos botões
    self.gameOverScreen.retry.zPosition = 50;
    self.gameOverScreen.menu.zPosition  = 50;
    kasco.zPosition = 50;
    
    if(_win){
        self.gameOverScreen.next.zPosition = 50;
    }

    // Tamanho dos botões
    CGFloat btnSize = 30;
    self.gameOverScreen.retry.size = CGSizeMake(btnSize, btnSize);
    self.gameOverScreen.menu.size  = CGSizeMake(btnSize, btnSize);
    kasco.size = CGSizeMake(118, 168);
    
    if(_win){
        self.gameOverScreen.next.size = CGSizeMake(btnSize, btnSize);
    }

    // Adiciona os botões na gameOverScreen
    [self.gameOverScreen addChild:self.gameOverScreen.retry];
    [self.gameOverScreen addChild:self.gameOverScreen.menu];
    [self.gameOverScreen addChild:kasco];
    [self.gameOverScreen addChild:winLose];
    [self.gameOverScreen addChild:scoreLabel];
    
    if(_win){
        [self.gameOverScreen addChild:self.gameOverScreen.next];
    }

    //Estrelas
    
    SKSpriteNode *onStar1 = [[SKSpriteNode alloc] initWithImageNamed:@"estrela_fill"];
    SKSpriteNode *onStar2 = [[SKSpriteNode alloc] initWithImageNamed:@"estrela_fill"];
    SKSpriteNode *onStar3 = [[SKSpriteNode alloc] initWithImageNamed:@"estrela_fill"];
    
    onStar1.name = @"onStar1";
    onStar2.name = @"onStar2";
    onStar3.name = @"onStar3";
    
    onStar1.zPosition = 50;
    onStar2.zPosition = 50;
    onStar3.zPosition = 50;
    
    SKSpriteNode *offStar1 = [[SKSpriteNode alloc] initWithImageNamed:@"estrela_outline"];
    SKSpriteNode *offStar2 = [[SKSpriteNode alloc] initWithImageNamed:@"estrela_outline"];
    SKSpriteNode *offStar3 = [[SKSpriteNode alloc] initWithImageNamed:@"estrela_outline"];
    
    offStar1.name = @"offStar1";
    offStar2.name = @"offStar2";
    offStar3.name = @"offStar3";
    
    offStar1.zPosition = 50;
    offStar2.zPosition = 50;
    offStar3.zPosition = 50;
    
    if(_win){
        //estrela_fill
        if(self.viewController.score >= self.level.targetScore * 1.5){
            onStar1.position = CGPointMake(CGRectGetMidX(self.gameOverScreen.frame) - 60, CGRectGetMidY(self.gameOverScreen.frame));
            onStar2.position = CGPointMake(self.gameOverScreen.position.x / 2, self.gameOverScreen.position.y / 2);
            onStar3.position = CGPointMake(self.gameOverScreen.position.x / 2 + 60, self.gameOverScreen.position.y / 2);
            
            [self.gameOverScreen addChild:onStar1];
            [self.gameOverScreen addChild:onStar2];
            [self.gameOverScreen addChild:onStar3];
        }else{
            if(self.viewController.score >= self.level.targetScore * 1.25){
                onStar1.position = CGPointMake(CGRectGetMidX(self.gameOverScreen.frame) - 60, CGRectGetMidY(self.gameOverScreen.frame));
                onStar2.position = CGPointMake(self.gameOverScreen.position.x / 2 + 60, self.gameOverScreen.position.y / 2);
                offStar3.position = CGPointMake(self.gameOverScreen.position.x / 2 + 60, self.gameOverScreen.position.y / 2);
                
                [self.gameOverScreen addChild:onStar1];
                [self.gameOverScreen addChild:onStar2];
                [self.gameOverScreen addChild:offStar3];
            }else{
                if (self.viewController.score >= self.level.targetScore * 1) {
                    onStar1.position = CGPointMake(CGRectGetMidX(self.gameOverScreen.frame) - 60, CGRectGetMidY(self.gameOverScreen.frame));
                    offStar2.position = CGPointMake(self.gameOverScreen.position.x / 2 + 60, self.gameOverScreen.position.y / 2);
                    offStar3.position = CGPointMake(self.gameOverScreen.position.x / 2 + 60, self.gameOverScreen.position.y / 2);

                    [self.gameOverScreen addChild:onStar1];
                    [self.gameOverScreen addChild:offStar2];
                    [self.gameOverScreen addChild:offStar3];
                }else{
                    offStar1.position = CGPointMake(CGRectGetMidX(self.gameOverScreen.frame) - 60, CGRectGetMidY(self.gameOverScreen.frame));
                    offStar2.position = CGPointMake(self.gameOverScreen.position.x / 2 + 60, self.gameOverScreen.position.y / 2);
                    offStar3.position = CGPointMake(self.gameOverScreen.position.x / 2 + 60, self.gameOverScreen.position.y / 2);
                    
                    [self.gameOverScreen addChild:offStar1];
                    [self.gameOverScreen addChild:offStar2];
                    [self.gameOverScreen addChild:offStar3];

                }
            }
        }
    }
    
    // Desce a tela da gameOverScreen
    [self.gameOverScreen runAction:acaoDescer];
    [self addChild:self.gameOverScreen];
}

- (void)animateBeginGame {
    self.gameLayer.hidden = NO;
    self.gameLayer.position = CGPointMake(0, self.size.height);
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height) duration:0.3];
    action.timingMode = SKActionTimingEaseOut;
    [self.gameLayer runAction:action];
}

-(void)winLose:(BOOL)win
{
    _win = win;
    _shouldPlay = NO;
    
    //Obtém o nível
    NSArray *a = [self.viewController.levelString componentsSeparatedByString:@"Level_"];
    NSInteger level = [[a lastObject] integerValue];
    
    //Para checar se é o último liberado
    if(level == [ClearedLevelsSingleton sharedInstance].lastLevelCleared){
        //Para enfim liberar mais um nível
        [[ClearedLevelsSingleton sharedInstance] updateLastLevel];
    }
    
    [self animateGameOver];
}

@end

