//
//  GameViewController.m
//  Fruit Catch
//
//  Created by Caio de Souza on 24/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//
\
@import AVFoundation;

#import "GameViewController.h"
#import "MyScene.h"
#import "JIMCLevel.h"
#import "JIMCPowerUp.h"
#import "JIMCSwapFruitSingleton.h"
#import "SettingsSingleton.h"
#import "Life.h"
#import "GameOverScene.h"

@interface GameViewController ()

// The level contains the tiles, the fruits, and most of the gameplay logic.
@property (nonatomic) JIMCLevel *level;


// The scene draws the tiles and fruit sprites, and handles swipes.
@property (nonatomic) MyScene *scene;

@property (assign, nonatomic) NSUInteger movesLeft;


@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (weak, nonatomic) IBOutlet UILabel *movesLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UIButton *shuffleButton;
@property (weak, nonatomic) IBOutlet UIImageView *gameOverPanel;

@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic) AVAudioPlayer *backgroundMusic;

@property (nonatomic) NSSet *possibleMoves;

@property SKSpriteNode *hintNode;
@property SKAction *hintAction;

@property(nonatomic) int firstX;

@property(nonatomic) int firstY;

@property(nonatomic) int finalX;

@property(nonatomic) int finalY;

@property(nonatomic) SKEmitterNode *powerUpEmitter;

@end

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerRetryNotification];
    _powerUpEmitter = nil;
    // Configure the view.
    SKView *skView = (SKView *)self.view;
    skView.multipleTouchEnabled = NO;
   
    // Create and configure the scene.
    self.scene = [MyScene sceneWithSize:skView.bounds.size];
    self.scene.scaleMode = SKSceneScaleModeAspectFill;
    
    self.scene.viewController = self;
    
    // Load the level.
    self.level = [[JIMCLevel alloc] initWithFile:self.levelString];
    self.scene.level = self.level;
    [self.scene addTiles];
    
    // This is the swipe handler. MyScene invokes this block whenever it
    // detects that the player performs a swipe.
    
    
   
    id block = ^(JIMCSwap *swap) {
        
        // While fruits are being matched and new fruits fall down to fill up
        // the holes, we don't want the player to tap on anything.
        self.view.userInteractionEnabled = NO;
        
        if ([self.level isPowerSwapLike:swap]){
            [self.level performSwap:swap];
            [JIMCSwapFruitSingleton sharedInstance].swap = swap;
            [self.scene animateSwap:swap completion:^{
                [self handleMatchesAll];
            }];
        }else if ([self.level isPowerSwap:swap]) {
            [self.level performSwap:swap];
            [JIMCSwapFruitSingleton sharedInstance].swap = swap;
            [self.scene animateSwap:swap completion:^{
                [self handleMatchesAllType:swap];
            }];
        }else if ([self.level isPossibleSwap:swap]) {
            [self.level performSwap:swap];
            [JIMCSwapFruitSingleton sharedInstance].swap = swap;
            [self.scene animateSwap:swap completion:^{
                [self handleMatches];
            }];
        } else {
            [self.scene animateInvalidSwap:swap completion:^{
                self.view.userInteractionEnabled = YES;
            }];
        }
    };
    
   
    self.scene.swipeHandler = block;
    
    // Hide the game over panel from the screen.
    self.gameOverPanel.hidden = YES;
    
    // Present the scene.
    [skView presentScene:self.scene];
    
    // Load and start background music.
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Mining by Moonlight" withExtension:@"mp3"];
    self.backgroundMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.backgroundMusic.numberOfLoops = -1;
    
    if([SettingsSingleton sharedInstance].music == ON){
        [self.backgroundMusic play];
    }
    [self loadPowerUpsView];
    // Let's start the game!
    [self beginGame];
}

- (void) loadPowerUpsView{
    UIView *newView = [[UIView alloc]initWithFrame:CGRectMake(10, 430, 100, 100)];
    [newView setBackgroundColor:[UIColor redColor]];
    UIImageView *powerUpImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"iconTest.jpeg"]];

    [powerUpImageView setBounds:CGRectMake(10, 10, 36 , 36)];
    [powerUpImageView setFrame:CGRectMake(10, 10, 36 , 36)];
    self.powerUpImage1 = powerUpImageView;
    [newView addSubview:powerUpImageView];
    [self.view addSubview:newView];
    self.powerUpView = newView;
    
    //self.powerUpImage1.image = [UIImage imageNamed:@"morango"];
    [self.view addSubview:self.powerUpView];
    UIPanGestureRecognizer *powerUpPanGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(movePowerUp:)];
    [powerUpPanGesture setMinimumNumberOfTouches:1];
    [powerUpPanGesture setMaximumNumberOfTouches:1];
    [powerUpImageView setUserInteractionEnabled:YES];
    NSLog(@"self.powerUpImage1.image = %@",self.powerUpImage1.image);
    //[self.powerUpImage1 addGestureRecognizer:powerUpPanGesture];
    [powerUpImageView addGestureRecognizer:powerUpPanGesture];
    
    
}

- (IBAction)movePowerUp:(UIPanGestureRecognizer *)gesture{
    NSLog(@"Method Fired");
    CGPoint translatedPoint = [gesture translationInView:self.view];
    if (gesture.state == UIGestureRecognizerStateBegan){
        _firstX = [[gesture view] center].x;
        _firstY = [[gesture view] center].y;
        
//        _firstX = self.powerUpImage1.frame.origin.x;
//        _firstY = self.powerUpImage1.frame.origin.y;
//        if (_firstX < 0){
//            _firstX *= -1;
//        }
//        if (_firstY < 0){
//            _firstY *= -1;
//        }
        NSLog(@"FirstX = %d/nFirstY = %d",_firstX,_firstY);
//        if (!_powerUpEmitter){
//            NSString *powerUpPath =
//            [[NSBundle mainBundle] pathForResource:@"powerUpEffect" ofType:@"sks"];
//            _powerUpEmitter =
//            [NSKeyedUnarchiver unarchiveObjectWithFile:powerUpPath];
//            _powerUpEmitter.position = self.powerUpImage1.frame.origin;
//            _powerUpEmitter.targetNode = self.scene;
//            [self.scene addChild:_powerUpEmitter];
//            return;
//        }

    }
   
    translatedPoint = CGPointMake(_firstX+translatedPoint.x, _firstY+translatedPoint.y);
    //_powerUpEmitter.position = translatedPoint;
    //[self.powerUpImage1 setCenter:translatedPoint];
    [[gesture view] setCenter:translatedPoint];
    if ([gesture state] == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = (0.2*[gesture velocityInView:self.view].x);
        CGFloat velocityY = (0.35*[gesture velocityInView:self.view].y);
        
        CGFloat finalX = translatedPoint.x + velocityX;
        CGFloat finalY = translatedPoint.y + velocityY;// translatedPoint.y + (.35*[(UIPanGestureRecognizer*)sender velocityInView:self.view].y);
        
        if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
            if (finalX < 0) {
                finalX = 0;
            } else if (finalX > 768) {
                finalX = 768;
            }
            
            if (finalY < 0) {
                finalY *= -1;
            } else if (finalY > 1024) {
                finalY = 1024;
            }
        } else {
            if (finalX < 0) {
                finalX = 0;
            } else if (finalX > 1024) {
                finalX = 768;
            }
            
            if (finalY < 0) {
                finalY *= -1;
            } else if (finalY > 768) {
                finalY = 1024;
            }
        }
        
        
        CGFloat animationDuration = (ABS(velocityX)*.0002)+.2;
    
        NSLog(@"the duration is: %f", animationDuration);
        CGPoint finalPoint = {finalX,finalY};
      
        //CGPoint location = [touch locationInNode:self.level.fruitsLayer];
        //[self.power setPosition:location];
        NSInteger column, row;
       // if (CGRectContainsPoint(self.scene.fruitsLayer.frame, finalPoint)){
            [self convertPoint:finalPoint toColumn:&column row:&row];
            if ((column != NSNotFound) && (row != NSNotFound)){
                //_powerUpEmitter.position = (CGPoint){column,row};
                JIMCPowerUp *powerUp = [[JIMCPowerUp alloc]init];
                powerUp.position = (CGPoint){column,row};
                [self handlePowerUpObject:powerUp];
            }
            else{
                //[[gesture view] center].x;
                //[gesture view] setCenter:<#(CGPoint)#>
                    
            }
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:animationDuration];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            //[UIView setAnimationDelegate:self];
            //[UIView setAnimationDidStopSelector:@selector(animationDidFinish)];
           
            [UIView commitAnimations];

            
    //    }
         [[gesture view] setCenter:CGPointMake(finalX, finalY)];
    }
    
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


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)beginGame {
    self.movesLeft = self.level.maximumMoves;
    self.score = 0;
    [self updateLabels];
    
    [self.level resetComboMultiplier];
    [self.scene animateBeginGame];
    [self shuffle];
    
    self.possibleMoves = [self.level detectPossibleSwaps];
    self.hintAction = [SKAction sequence:@[[SKAction waitForDuration:5 withRange:0], [SKAction performSelector:@selector(showMoves) onTarget:self]]];

    [self.scene runAction: self.hintAction withKey:@"Hint"];
}

- (void)shuffle {
    
    // Delete the old fruit sprites, but not the tiles.
    [self.scene removeAllFruitSprites];
    // Fill up the level with new fruits, and create sprites for them.
    NSSet *newFruits = [self.level shuffle];
    [self.scene addSpritesForFruits:newFruits];
}


- (void)handleMatchesAllType:(JIMCSwap *) fruit {
    // This is the main loop that removes any matching fruits and fills up the
    // holes with new fruits. While this happens, the user cannot interact with
    // the app.
    
    [self.scene removeActionForKey:@"Hint"];
    
    // Detect if there are any matches left.
    NSSet *chains = [self.level removeMatchesAllType:fruit];
    // If there are no more matches, then the player gets to move again.

    if ([chains count] == 0) {
        [self beginNextTurn];
        return;
    }
    
    // First, remove any matches...
    [self.scene animateMatchedFruits:chains completion:^{
        // Add the new scores to the total.
       
        [self updateLabels];
        
        // ...then shift down any fruits that have a hole below them...
        NSArray *columns = [self.level fillHoles];
        [self.scene animateFallingFruits:columns completion:^{
            
            // ...and finally, add new fruits at the top.
            NSArray *columns = [self.level topUpFruits];
            [self.scene animateNewFruits:columns completion:^{
            
                [self handleMatches];
            
            }];
        }];
    }];
}

- (void)handleMatchesAll{
    // This is the main loop that removes any matching fruits and fills up the
    // holes with new fruits. While this happens, the user cannot interact with
    // the app.
    
    //[self.scene removeActionForKey:@"Hint"];
    
    // Detect if there are any matches left.
    NSSet *chains = [self.level removeMatchesAll];
    // If there are no more matches, then the player gets to move again.
    
    if ([chains count] == 0) {
        [self beginNextTurn];
        return;
    }
    
    // First, remove any matches...
    [self.scene animateMatchedFruits:chains completion:^{
        // Add the new scores to the total.
        
        [self updateLabels];
        
        // ...then shift down any fruits that have a hole below them...
        NSArray *columns = [self.level fillHoles];
        [self.scene animateFallingFruits:columns completion:^{
            
            // ...and finally, add new fruits at the top.
            NSArray *columns = [self.level topUpFruits];
            [self.scene animateNewFruits:columns completion:^{
                
                [self handleMatches];
                
            }];
        }];
    }];
}
- (void)handleMatches {
    // This is the main loop that removes any matching fruits and fills up the
    // holes with new fruits. While this happens, the user cannot interact with
    // the app.
    
    [self.scene removeActionForKey:@"Hint"];
    
    // Detect if there are any matches left.
    NSSet *chains = [self.level removeMatches];

    // If there are no more matches, then the player gets to move again.
    if ([chains count] == 0) {
        [self beginNextTurn];
        return;
    }
    
    // First, remove any matches...
   
    [self.scene animateMatchedFruits:chains completion:^{
        // Add the new scores to the total.
        for (JIMCChain *chain in chains) {
             for (JIMCFruit *fruit in chain.fruits) {
                if ((fruit.fruitPowerUp == 1 && chain.fruits.count == 5) ||
                    (fruit.fruitPowerUp == 2 && chain.fruits.count == 4) ||  (fruit.fruitPowerUp == 3 && chain.fruits.count == 4)) {
                    
                    [self.scene addSpritesForFruit:fruit];
                    [JIMCSwapFruitSingleton sharedInstance].swap = nil;
                    //break;
                }
             }
        }
        
        for (JIMCChain *chain in chains) {
            self.score += chain.score;
        }
        [self updateLabels];
        
        // ...then shift down any fruits that have a hole below them...
        NSArray *columns = [self.level fillHoles];
        [self.scene animateFallingFruits:columns completion:^{
            
            // ...and finally, add new fruits at the top.
            NSArray *columns = [self.level topUpFruits];
            [self.scene animateNewFruits:columns completion:^{
                
                // Keep repeating this cycle until there are no more matches.
                [self handleMatches];
            }];
        }];
    }];
}

- (void)handlePowerUp {
    // This is the main loop that removes any matching fruits and fills up the
    // holes with new fruits. While this happens, the user cannot interact with
    // the app.
    
    // Detect if there are any matches left.
    JIMCPowerUp *powerUp = [[JIMCPowerUp alloc]init];
    powerUp.position = (CGPoint){5,5};
    NSSet *chains = [self.scene.level executePowerUp:powerUp];
    // If there are no more matches, then the player gets to move again.
    if ([chains count] == 0) {
        //NSLog(@"Chains count is zero");
        [self beginNextTurn];
        return;
    }
   // [self.level verificaDestruir:chains];
    // First, remove any matches...
    [self.scene animateMatchedFruits:chains completion:^{
        
        // Add the new scores to the total.
        for (JIMCChain *chain in chains) {
            self.score += chain.score;
        }
        [self updateLabels];

        // ...then shift down any fruits that have a hole below them...
        NSMutableArray *columns = [[NSMutableArray alloc]initWithArray:[self.level fillHoles]];
       
       
        
        [self.scene animateFallingFruits:columns completion:^{
            
            // ...and finally, add new fruits at the top.
            NSArray *columns = [self.level topUpFruits];
            [self.scene animateNewFruits:columns completion:^{
                
                // Keep repeating this cycle until there are no more matches.
                [self handleMatches];
            }];
        }];
    }];
}

- (void)handlePowerUpObject:(JIMCPowerUp *)powerUp {
    // This is the main loop that removes any matching fruits and fills up the
    // holes with new fruits. While this happens, the user cannot interact with
    // the app.
    
    // Detect if there are any matches left.
   // powerUp.position = CGPointMake(5, 5);
    NSSet *chains = [self.scene.level executePowerUp:powerUp];
    // If there are no more matches, then the player gets to move again.
    if ([chains count] == 0) {
        //NSLog(@"Chains count is zero");
        //[_powerUpEmitter removeFromParent];
        //_powerUpEmitter = nil;
        [self beginNextTurn];
        return;
    }
    // [self.level verificaDestruir:chains];
    // First, remove any matches...
    [self.scene animateMatchedFruits:chains completion:^{
        
        // Add the new scores to the total.
        for (JIMCChain *chain in chains) {
            self.score += chain.score;
        }
        [self updateLabels];
        
        // ...then shift down any fruits that have a hole below them...
        NSMutableArray *columns = [[NSMutableArray alloc]initWithArray:[self.level fillHoles]];
        
        
        
        [self.scene animateFallingFruits:columns completion:^{
            
            // ...and finally, add new fruits at the top.
            NSArray *columns = [self.level topUpFruits];
            [self.scene animateNewFruits:columns completion:^{
                
                // Keep repeating this cycle until there are no more matches.
                [self handleMatches];
            }];
        }];
    }];
}



- (void)beginNextTurn {
    
    [self.level resetComboMultiplier];
    
    self.possibleMoves = [self.level detectPossibleSwaps];
    
    NSInteger i = self.possibleMoves.count;
    
    if(i == 0){
        //NSLog(@"Não há movimentos restantes.\nEmbaralhando.");
        [self shuffle];
        self.possibleMoves = [self.level detectPossibleSwaps];
        i = self.possibleMoves.count;
     //   NSLog(@"Jogadas possiveis = %ld",i);
    }else{
     //   NSLog(@"Jogadas possiveis = %ld",i);
    }
    
    //NSLog(@"Jogadas possiveis = %d",(int)i);
    
    [self.scene runAction: self.hintAction withKey:@"Hint"];
    //SKAction *showMove = [SKAction repeatActionForever:[SKAction sequence:@[[SKAction waitForDuration:5 withRange:0], [SKAction performSelector:@selector(showMoves) onTarget:self]]]];
    
    self.view.userInteractionEnabled = YES;
    [self decrementMoves];
    [self cancelHints];
    
}

-(void)cancelHints
{
    //compara score
    if(self.score >= self.level.targetScore || self.movesLeft == 0)
    {
        [self.scene removeActionForKey:@"Hint"];
        if(self.hintNode){
            [self.scene runAction:[SKAction runBlock:^{
                [self.hintNode removeFromParent];
            }]];
        }
    }
}

-(void)showMoves
{
    //Obtem um movimento possivel entre todos
    JIMCSwap *swap = [self.possibleMoves anyObject];
    
    NSInteger x,y;
    
    if(swap.fruitA.column == 4){
        x = 0;
    }else{
        x = 34 * (swap.fruitA.column - 4);
    }
    if(swap.fruitA.row == 4){
        y = 0;
    }else{
        y = 36 * (swap.fruitA.row - 4);
    }
    
    self.hintNode = [[SKSpriteNode alloc]initWithImageNamed:[swap.fruitA highlightedSpriteName]];
    self.hintNode.position = CGPointMake(x, y);
    [self.scene addChild:self.hintNode];
}

- (void)updateLabels {
    self.targetLabel.text = [NSString stringWithFormat:@"%lu", (long)self.level.targetScore];
    self.movesLabel.text = [NSString stringWithFormat:@"%lu", (long)self.movesLeft];
    self.scoreLabel.text = [NSString stringWithFormat:@"%lu", (long)self.score];
    
}

- (void)decrementMoves{
    self.movesLeft--;
    [self updateLabels];
    
    if (self.score >= self.level.targetScore) {
        [self.scene animateGameOver];
//        self.gameOverPanel.image = [UIImage imageNamed:@"LevelComplete"];
    } else if (self.movesLeft == 0) {
        [self.scene animateGameOver];
//        self.movesLeft = self.level.maximumMoves;
//        self.score = 0;
        [self updateLabels];
    }
    
    //Essa comparacao serve apenas para nao chamar o gameover duas vezes
    if(self.score >= self.scene.level.targetScore || self.movesLeft == 0){
        [self showGameOver];
    }
    
    [self.scene removeActionForKey:@"Hint"];
    if(self.hintNode){
        [self.scene runAction:[SKAction runBlock:^{
            [self.hintNode removeFromParent];
        }]];
    }
    
}

- (void)showGameOver {

    //Chega se o usuário ganhou ou se acabaram os movimentos
    if(self.score >= self.scene.level.targetScore || self.movesLeft == 0){
        if(self.score >= self.scene.level.targetScore){
            [self.scene winLose:YES];
        }else{
            [self.scene winLose:NO];
        }
    }
    
//    [self.scene removeActionForKey:@"Hint"];
//    if(self.hintNode){
//        [self.scene runAction:[SKAction runBlock:^{
//            [self.hintNode removeFromParent];
//        }]];
//    }
//    
//    self.gameOverPanel.hidden = NO;
//    self.scene.userInteractionEnabled = NO;
//    
//    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideGameOver)];
//    [self.view addGestureRecognizer:self.tapGestureRecognizer];
//    
//    self.shuffleButton.hidden = YES;
    
}

- (void)hideGameOver {
    
    [self.scene removeActionForKey:@"Hint"];
    if(self.hintNode){
        [self.scene runAction:[SKAction runBlock:^{
            [self.hintNode removeFromParent];
        }]];
    }
    
    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
    self.tapGestureRecognizer = nil;
    
    self.gameOverPanel.hidden = YES;
    self.scene.userInteractionEnabled = YES;
    
    [self beginGame];
    
    self.shuffleButton.hidden = NO;
    
}

- (IBAction)shuffleButtonPressed:(id)sender {
    //[self shuffle];
    
    
        // Pressing the shuffle button costs a move.
        [self decrementMoves];
        [self handlePowerUp];
    
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInNode:self.scene];
    
    [self.scene removeActionForKey:@"Hint"];
    if(self.hintNode){
        [self.scene runAction:[SKAction runBlock:^{
            [self.hintNode removeFromParent];
        }]];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.scene runAction: self.hintAction withKey:@"Hint"];
}

-(IBAction)back:(id)sender
{
    _backButton.enabled = NO;
    [self performSegueWithIdentifier:@"Back" sender:self];
}

-(void)back {
    [self performSegueWithIdentifier:@"Back" sender:self];
}

- (void)registerRetryNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zerarRetryNotification:) name:@"zerarRetryNotification" object:nil];
}

- (void)zerarRetryNotification:(NSNotification *)notification{
    self.movesLeft = self.level.maximumMoves;
    self.score = 0;
    [self updateLabels];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Back"]){
        if(self.scene != nil)
        {
            Life *life = [Life sharedInstance];
            life.lifeCount--;
            NSDate *oldDate = life.lifeTime;
            NSTimeInterval interval = [oldDate timeIntervalSinceNow];
            NSDate *plusDate = [NSDate dateWithTimeIntervalSinceNow:interval];
            life.lifeTime = plusDate;
            [life saveToFile];
            [self.scene setPaused:YES];
            [self.scene removeAllActions];
            [self.scene removeAllChildren];
            [self.backgroundMusic stop];
            [self.scene removeAllFruitSprites];
    
            self.scene = nil;
            self.backgroundMusic = nil;
            self.level = nil;
            
            [self.scene removeFromParent];
            
            SKView *view = (SKView *)self.view;
            [view presentScene:nil];
            
            view = nil;
        }
    }
}

@end
