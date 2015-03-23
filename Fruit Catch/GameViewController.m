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
#import "WorldMap.h"
#import "AFDropdownNotification.h"
#import "AppDelegate.h"

#define IPHONE6 ([[UIScreen mainScreen] bounds].size.width == 375)
#define IPHONE6PLUS ([[UIScreen mainScreen] bounds].size.width == 414)

#define IPHONE6_XSCALE 1.171875*0.93
#define IPHONE6_YSCALE 1.174285774647887*0.93
#define IPHONE6PLUS_XSCALE 1.171875
#define IPHONE6PLUS_YSCALE 1.174285774647887

@interface GameViewController (){
    NSNumberFormatter * _priceFormatter;
}

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

@property (nonatomic) int firstX;
@property (nonatomic) int firstY;
@property (nonatomic) int finalX;
@property (nonatomic) int finalY;
@property (nonatomic) CGPoint initialImagePoint;

@property (nonatomic) SKEmitterNode *powerUpEmitter;
@property (nonatomic) id block;

@property (nonatomic) BOOL timerStarted;
@property (nonatomic) NSInteger segundos;
@property (nonatomic) NSTimer *cronometro;

@property BOOL next;


//Menu rápido
@property (nonatomic) IBOutlet UIImageView *fundoMenuRapido;
@property (nonatomic) IBOutlet UIImageView *blockMusic;
@property (nonatomic) IBOutlet UIImageView *blockSFX;
@property (nonatomic) IBOutlet UIButton *menuRapido;
@property (nonatomic) IBOutlet UIButton *ligaMusica;
@property (nonatomic) IBOutlet UIButton *btnSair;
@property (nonatomic) IBOutlet UIButton *ligaSFX;
@property (nonatomic) IBOutlet UIButton *ajuda;
@property (nonatomic) BOOL quickMenuOpen;
@property(nonatomic) UILabel *tip;
@property(nonatomic) UIImageView *kascoImageView;


@end

@implementation GameViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.scene setIsMyMove:YES];
    if (![SettingsSingleton sharedInstance].music) {
        //adicionar ícone de proibido
        [_ligaMusica setBackgroundImage:[UIImage imageNamed:@"no_music"] forState:UIControlStateNormal];
        _ligaMusica.frame = CGRectMake(_ligaMusica.center.x - 19.5, _ligaMusica.center.y - 21.5, 39, 43);
    }else{
        //remove ícone de proibido
        [_ligaMusica setBackgroundImage:[UIImage imageNamed:@"icon_music"] forState:UIControlStateNormal];
        _ligaMusica.frame = CGRectMake(65, 65, 24, 36);
    }
    
    if (![SettingsSingleton sharedInstance].SFX) {
        //adicionar ícone de proibido
        [_ligaSFX setBackgroundImage:[UIImage imageNamed:@"no_sfx"] forState:UIControlStateNormal];
        _ligaSFX.frame = CGRectMake(_ligaSFX.center.x - 19.5, _ligaSFX.center.y - 21.5, 39, 43);
    }else{
        //remove ícone de proibido
        [_ligaSFX setBackgroundImage:[UIImage imageNamed:@"icon_som"] forState:UIControlStateNormal];
        _ligaSFX.frame = CGRectMake(15, 40, 20, 32);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _next = NO;
    _timerStarted = NO;
    
    _showFirstTutorial  = NO;
    _show4FruitTutorial = NO;
    _show5FruitTutorial = NO;
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"FirstTutorial"]){
        _showFirstTutorial = YES;
    }
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"4FruitTutorial"]){
        _show4FruitTutorial = YES;
    }
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"5FruitTutorial"]){
        _show5FruitTutorial = YES;
    }
    
    
    [self registerRetryNotification];
    _powerUpEmitter = nil;
    // Configure the view.
    SKView *skView = (SKView *)self.view;
    skView.multipleTouchEnabled = NO;
    //skView.showsNodeCount = YES;
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
    
    
    __weak typeof(self) weakSelf = self;
    _block = ^(JIMCSwap *swap) {
        
        // While fruits are being matched and new fruits fall down to fill up
        // the holes, we don't want the player to tap on anything.
        //self.view.userInteractionEnabled = NO;
        weakSelf.view.userInteractionEnabled = NO;
        if ([weakSelf.level isPowerSwapLike:swap]){
            [weakSelf.level performSwap:swap];
            [JIMCSwapFruitSingleton sharedInstance].swap = swap;
            [weakSelf.scene animateSwap:swap completion:^{
                [weakSelf handleMatchesAll];
            }];
        }else if ([weakSelf.level isPowerSwap:swap]) {
            [weakSelf.level performSwap:swap];
            [JIMCSwapFruitSingleton sharedInstance].swap = swap;
            [weakSelf.scene animateSwap:swap completion:^{
                [weakSelf handleMatchesAllType:swap];
            }];
        }else if ([weakSelf.level isPossibleSwap:swap]) {
            [weakSelf.level performSwap:swap];
            [JIMCSwapFruitSingleton sharedInstance].swap = swap;
            [weakSelf.scene animateSwap:swap completion:^{
                [weakSelf handleMatches];
            }];
        } else {
            [weakSelf.scene animateInvalidSwap:swap completion:^{
                weakSelf.view.userInteractionEnabled = YES;
            }];
        }
    };
    
   
    self.scene.swipeHandler = _block;
    
    // Hide the game over panel from the screen.
    self.gameOverPanel.hidden = YES;
    
    // Present the scene.
    [skView presentScene:self.scene];
    
    // Load and start background music.
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"FunnyBounceMusic" withExtension:@"mp3"];
    self.backgroundMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.backgroundMusic.numberOfLoops = -1;
    
    if([SettingsSingleton sharedInstance].music == ON){
        [self.backgroundMusic play];
    }
    //[self loadPowerUpsView];
    
    _priceFormatter = [[NSNumberFormatter alloc] init];
    [_priceFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    // Let's start the game!
    [self beginGame];
    
    [self adicionaMenuRapido];
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
    
    //Trava o cronômetro
    _timerStarted = NO;
    _segundos = 0;
}

- (IBAction)movePowerUp:(UIPanGestureRecognizer *)gesture{
    self.initialImagePoint = [[gesture view] frame].origin;
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
        //CGPoint finalPoint = {finalX,finalY};
      
        //CGPoint location = [touch locationInNode:self.level.fruitsLayer];
        //[self.power setPosition:location];
        NSInteger column, row;
       // if (CGRectContainsPoint(self.scene.fruitsLayer.frame, finalPoint)){
 
           [self convertPoint:translatedPoint toColumn:&column row:&row];
        
            NSLog(@"coluna linha %@",NSStringFromCGPoint([self pointForColumn:column row:row]));
            NSLog(@"column = %ld",(long)column);
            NSLog(@"Row = %ld",(long)row);
        
        
            if ((column != NSNotFound) && (row != NSNotFound)){
                NSLog(@"Column and row found");
                //_powerUpEmitter.position = (CGPoint){column,row};
                JIMCPowerUp *powerUp = [[JIMCPowerUp alloc]init];
                powerUp.position = (CGPoint){column,row};
                
                [self handlePowerUpObject:powerUp];
            }
            else{
                CGRect frame = [[gesture view] frame];
                frame.origin = self.initialImagePoint;
                [[gesture view] setFrame:frame];
                
                NSLog(@"SetFrame = %@",NSStringFromCGRect(frame));
                return;
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

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"zerarRetryNotification" object:nil];
    
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"zerarRetryNotification" object:nil];
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
    
    if(_showFirstTutorial){
        [self firstTutorial];
    }
    
    self.movesLeft = self.level.maximumMoves;
    self.score = 0;
    [self updateLabels];
    
    [self.level resetComboMultiplier];
    [self.scene animateBeginGame];
    [self shuffle];
    
    self.possibleMoves = [self.level detectPossibleSwaps];
    self.hintAction = [SKAction sequence:@[[SKAction waitForDuration:5 withRange:0], [SKAction performSelector:@selector(showMoves) onTarget:self]]];

    [self.scene runAction: self.hintAction withKey:@"Hint"];
    
    if(!_timerStarted){
        _timerStarted = YES;
        _cronometro = [NSTimer scheduledTimerWithTimeInterval:1
                                                       target:self
                                                     selector:@selector(cronometro:)
                                                     userInfo:nil
                                                      repeats:YES];
    }
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
                     (fruit.fruitPowerUp == 2 && chain.fruits.count == 4) || (fruit.fruitPowerUp == 3 && chain.fruits.count == 4)){
                     if ((chain.fruits.count == 5) && (_show5FruitTutorial)){
                         [self tutorial5FruitsForPowerUpObject:fruit];
                     }
                     if ((chain.fruits.count == 4) && (_show4FruitTutorial)){
                         [self tutorial4Fruits];
                     }
                    [self.scene addSpritesForFruit:fruit];
                    [JIMCSwapFruitSingleton sharedInstance].swap = nil;
                }
             }
        }
        [JIMCSwapFruitSingleton sharedInstance].swap = nil;
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
        [JIMCSwapFruitSingleton sharedInstance].swap = nil;
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
    
    //DICA RODANDO AQUI V
//    [self.scene runAction: self.hintAction withKey:@"Hint"];
    //DICA RODANDO ALI ˆ
    
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
    
//    self.hintNode = [[SKSpriteNode alloc]initWithImageNamed:[swap.fruitA highlightedSpriteName]];
//    self.hintNode.position = CGPointMake(x, y);
//    [self.scene addChild:self.hintNode];
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
//        self.gameOverPanel.image = [UIImage imageNamed:@"LevelComplete"];
    } else if (self.movesLeft == 0) {
//        self.movesLeft = self.level.maximumMoves;
//        self.score = 0;
        [self updateLabels];
    }
    
    //Essa comparacao serve apenas para nao chamar o gameover duas vezes
    if(self.score >= self.scene.level.targetScore || self.movesLeft == 0){
        self.scene.swipeHandler = nil;
       // self.view.userInteractionEnabled = NO;
        
        [self showGameOver];
    }
    
    [self removeDica];
    
}

- (void)showGameOver {

    //Chega se o usuário ganhou ou se acabaram os movimentos
    if(self.score >= self.scene.level.targetScore || self.movesLeft == 0){

        if(self.score >= self.scene.level.targetScore){
            
            if(self.movesLeft > 0){
                if ((self.level.maximumMoves - self.movesLeft) <= 2){
                    _easterEggKasco = YES;
                }

                self.score += (self.movesLeft * 100);
                self.movesLeft = 0;
                [self updateLabels];
            }
        [self.scene winLose:YES];
        }else{
            [self.scene winLose:NO];
        }
        
        [self saveScore];
        
    }
    
}

- (void)hideGameOver {
    [self removeDica];
    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
    self.tapGestureRecognizer = nil;
    
    self.gameOverPanel.hidden = YES;
    self.scene.userInteractionEnabled = YES;
    
    [self beginGame];
    self.shuffleButton.hidden = NO;
    
}

- (IBAction)shuffleButtonPressed:(id)sender {
    // Pressing the shuffle button costs a move.
    [self decrementMoves];
    [self handlePowerUp];
    
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    
    if(_quickMenuOpen){
        if(!CGRectContainsPoint(_fundoMenuRapido.frame, location)){
            [self menuRapido:self];
        }
    }
    
    [self removeDica];
    if(self.scene.shouldPlay){
        self.scene.swipeHandler = _block;
        
        if(!_timerStarted){
            _timerStarted = YES;
            _cronometro = [NSTimer scheduledTimerWithTimeInterval:1
                                                           target:self
                                                         selector:@selector(cronometro:)
                                                         userInfo:nil
                                                          repeats:YES];
        }
    }else{
        self.scene.swipeHandler = nil;
    }
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.scene runAction: self.hintAction withKey:@"Hint"];
}

-(IBAction)back:(id)sender
{
    _backButton.enabled = NO;
    
    self.scene.swapSound = nil;
    self.scene.invalidSwapSound = nil;
    self.scene.matchSound = nil;
    self.scene.fallingFruitSound = nil;
    self.scene.addFruitSound = nil;
    if ([self shouldPerformSegueWithIdentifier:@"Back" sender:sender]){
        [self performSegueWithIdentifier:@"Back" sender:self];
    }
}

-(void)back{
    if ([self shouldPerformSegueWithIdentifier:@"Back" sender:nil]){
        [self performSegueWithIdentifier:@"Back" sender:self];
    }
}

-(void)nextStage{
    _next = YES;
    if ([self shouldPerformSegueWithIdentifier:@"Back" sender:nil]){
        [self performSegueWithIdentifier:@"Back" sender:self];
    }
}

- (void)registerRetryNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zerarRetryNotification:) name:@"zerarRetryNotification" object:nil];
}

- (void)zerarRetryNotification:(NSNotification *)notification{
    self.movesLeft = self.level.maximumMoves;
    self.score = 0;
    [Life sharedInstance].lifeCount--;
    NSDate *oldDate =  [Life sharedInstance].lifeTime;
    NSTimeInterval interval = [oldDate timeIntervalSinceNow];
    NSDate *plusDate = [NSDate dateWithTimeIntervalSinceNow:interval];
    [Life sharedInstance].lifeTime = plusDate;
    [[Life sharedInstance] saveToFile];
    [self updateLabels];
}


- (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"Prepare For Segue");
    if ([self shouldPerformSegueWithIdentifier:segue.identifier sender:sender]){
        if([segue.identifier isEqualToString:@"Back"]){
            if(self.scene != nil)
            {
                WorldMap *viewWP = [segue destinationViewController];
                Life *life = [Life sharedInstance];
                if (life.lifeCount > 0){
                    if (!_next){
                        life.lifeCount--;
                    }
                    
                    NSLog(@"Life=%@",life);
                }
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
                
                if(_next){
                    NSArray *a = [self.levelString componentsSeparatedByString:@"Level_"];
                    NSInteger i = [[a objectAtIndex:1] integerValue];
                    if(i <= numberOfLevels){
                        viewWP.nextStage = i+1;
                    }else{
                        viewWP.nextStage = -1;
                    }
                }else{
                    viewWP.nextStage = -1;
                }
            }
        }
    }
}

-(void)saveScore
{
    
    [self removeDica];
    _timerStarted = NO;
    //Carrega o score do plist
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [NSString stringWithFormat:@"%@/highscore.plist",documentsDirectory];
    
    NSMutableArray *array  = [NSMutableArray arrayWithContentsOfFile:plistPath];
    
    NSArray *a = [self.levelString componentsSeparatedByString:@"Level_"];
    NSInteger level = [[a lastObject] integerValue];
    
    NSMutableDictionary *levelHighScore = [[NSMutableDictionary alloc] initWithDictionary:[array objectAtIndex:level]];
    NSNumber *highScore = [NSNumber numberWithInteger:self.score];
    NSNumber *tempo = [NSNumber numberWithInteger:_segundos];
    
    //Mesmo score, tempo menor
    if(([levelHighScore[@"highScore"] integerValue] == highScore.integerValue) && ((int)levelHighScore[@"time"] > tempo.integerValue)){
        [levelHighScore setObject:tempo forKey:@"time"];
    }
    
    //Se não tem score gravado ou se o score é maior
    if([levelHighScore[@"highScore"] integerValue] == 0 || [levelHighScore[@"highScore"]integerValue] < highScore.integerValue){
        [levelHighScore setObject:highScore forKey:@"highScore"];
        [levelHighScore setObject:tempo forKey:@"time"];
    }
    
    [array replaceObjectAtIndex:level withObject:levelHighScore];
    [array writeToFile:plistPath atomically:YES];
//    [AppDelegate sendFiletoWebService];
}

-(void)removeDica
{
    [self.scene removeActionForKey:@"Hint"];
    if(self.hintNode){
        [self.scene runAction:[SKAction runBlock:^{
            [self.hintNode removeFromParent];
        }]];
    }
}

-(IBAction)cronometro:(id)sender
{
    if(_timerStarted){
        _segundos++;
    }else{
        [_cronometro invalidate];
        _segundos = 0;
    }
}

-(void)firstTutorial
{
    NSLog(@"First tutorial");
    //fazendeiro_fase@2x
   
    _tip = [[UILabel alloc] initWithFrame:CGRectMake(50,
                                                             150,
                                                             230,
                                                             140)];
    
    [_tip setFont:[UIFont fontWithName:@"Chewy" size:12]];
    [_tip setTextColor:[UIColor whiteColor]];
    [_tip setBackgroundColor:[UIColor clearColor]];
    _tip.backgroundColor = [UIColor colorWithRed:80.0/255 green:141.0/255 blue:194.0/255 alpha:1];
    _tip.layer.borderColor = [UIColor whiteColor].CGColor;
    _tip.layer.borderWidth = 2.0;
    _tip.layer.cornerRadius = 12.0;
    [_tip setNumberOfLines:5];
    UISwitch *noMoreTips = [[UISwitch alloc]initWithFrame:CGRectMake(140, 105, 36, 10)];
    [noMoreTips addTarget:self action:@selector(noMoreTips:) forControlEvents:UIControlEventValueChanged];
    UILabel *noreMoreTipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(25,115,120,10)];
    [noreMoreTipsLabel setText:@"         Dont Show me Tips:"];
    [noreMoreTipsLabel setFont:[UIFont fontWithName:@"Chewy" size:12]];
    [noreMoreTipsLabel setTextColor:[UIColor whiteColor]];
    [_tip addSubview:noreMoreTipsLabel];
    [_tip addSubview:noMoreTips];
    
    [_tip setText:@"                                Quick Tip\n\n                Its a Match-three game,no secrets.\n      Tap three or more fruits in a column or row"];
   
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTip:)];
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTip:)];
    
    [swipeGesture setDirection:(UISwipeGestureRecognizerDirectionLeft |
                               UISwipeGestureRecognizerDirectionRight |
                               UISwipeGestureRecognizerDirectionDown |
                                UISwipeGestureRecognizerDirectionUp)];
    [_tip addGestureRecognizer:swipeGesture];
    [_tip addGestureRecognizer:tap];
    //[self.scene.fruitsLayer setUserInteractionEnabled:NO];
    [_tip setUserInteractionEnabled:YES];
    [self.view addSubview:_tip];
    
    _kascoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fazendeiro_fase"]];
    [_kascoImageView setFrame:CGRectMake(50, 75, 230, 120)];
    [self.view insertSubview:_kascoImageView belowSubview:_tip];
    [_tip setAlpha:1.0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:10.0 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            
                _tip.alpha = 0.1;
                _kascoImageView.alpha = 0.1;
        } completion:^(BOOL finished){
            [_tip setUserInteractionEnabled:NO];
            [_tip removeFromSuperview];
            [_kascoImageView removeFromSuperview];
            
            if (finished)
                _tip = nil;
            
        }];
    });
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FirstTutorial"];
    _showFirstTutorial  = NO;
}

- (void)dismissTip:(UIGestureRecognizer *)recognizer{
    NSLog(@"Dismiss Tip called");
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"4FruitTutorial"];
    _show4FruitTutorial = NO;
    [self.view sendSubviewToBack:_tip];
    [_tip setUserInteractionEnabled:NO];
    [_tip removeFromSuperview];
    [_kascoImageView removeFromSuperview];
    
    
    
}

-(void)tutorial4Fruits
{
    _tip = [[UILabel alloc] initWithFrame:CGRectMake(50,
                                                     150,
                                                     230,
                                                     160)];
    
    [_tip setFont:[UIFont fontWithName:@"Chewy" size:12]];
    [_tip setTextColor:[UIColor whiteColor]];
    [_tip setBackgroundColor:[UIColor clearColor]];
    _tip.backgroundColor = [UIColor colorWithRed:80.0/255 green:141.0/255 blue:194.0/255 alpha:1];
    _tip.layer.borderColor = [UIColor whiteColor].CGColor;
    _tip.layer.borderWidth = 2.0;
    _tip.layer.cornerRadius = 12.0;
    [_tip setNumberOfLines:5];
    UISwitch *noMoreTips = [[UISwitch alloc]initWithFrame:CGRectMake(140, 125, 36, 10)];
    [noMoreTips addTarget:self action:@selector(noMoreTips:) forControlEvents:UIControlEventValueChanged];
    UILabel *noreMoreTipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(25,135,120,10)];
    [noreMoreTipsLabel setText:@"         Dont Show me Tips:"];
    [noreMoreTipsLabel setFont:[UIFont fontWithName:@"Chewy" size:12]];
    [noreMoreTipsLabel setTextColor:[UIColor whiteColor]];

    [_tip addSubview:noreMoreTipsLabel];

    [_tip addSubview:noMoreTips];
    
    
    [_tip setText:@"                                Quick Tip\n\n                You make a 4 Fruit Power Up!.\n                Swipe then to destroy all fruits\n                       in a column or Row"];
    
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTip:)];
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTip:)];
    
    [swipeGesture setDirection:(UISwipeGestureRecognizerDirectionLeft |
                                UISwipeGestureRecognizerDirectionRight |
                                UISwipeGestureRecognizerDirectionDown |
                                UISwipeGestureRecognizerDirectionUp)];
    [_tip addGestureRecognizer:swipeGesture];
    [_tip addGestureRecognizer:tap];
    //[self.scene.fruitsLayer setUserInteractionEnabled:NO];
    [_tip setUserInteractionEnabled:YES];
    [self.view addSubview:_tip];
    
    _kascoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fazendeiro_fase"]];
    [_kascoImageView setFrame:CGRectMake(50, 75, 230, 120)];
    [self.view insertSubview:_kascoImageView belowSubview:_tip];
    [_tip setAlpha:1.0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:10.0 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            
            _tip.alpha = 0.1;
            _kascoImageView.alpha = 0.1;
        } completion:^(BOOL finished){
            [_tip setUserInteractionEnabled:NO];
            [_tip removeFromSuperview];
            [_kascoImageView removeFromSuperview];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"4FruitTutorial"];
            _show4FruitTutorial = NO;
            if (finished)
                _tip = nil;
            
        }];
    });

     [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"4FruitTutorial"];
    _show4FruitTutorial = NO;
}

-(void)tutorial5FruitsForPowerUpObject:(JIMCFruit *)powerUp
{

    _tip = [[UILabel alloc] initWithFrame:CGRectMake(50,
                                                     150,
                                                     230,
                                                     160)];
    
    [_tip setFont:[UIFont fontWithName:@"Chewy" size:12]];
    [_tip setTextColor:[UIColor whiteColor]];
    [_tip setBackgroundColor:[UIColor clearColor]];
    _tip.backgroundColor = [UIColor colorWithRed:80.0/255 green:141.0/255 blue:194.0/255 alpha:1];
    _tip.layer.borderColor = [UIColor whiteColor].CGColor;
    _tip.layer.borderWidth = 2.0;
    _tip.layer.cornerRadius = 12.0;
    [_tip setNumberOfLines:5];
    UISwitch *noMoreTips = [[UISwitch alloc]initWithFrame:CGRectMake(140, 125, 36, 10)];
    [noMoreTips addTarget:self action:@selector(noMoreTips:) forControlEvents:UIControlEventValueChanged];
    UILabel *noreMoreTipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(25,135,120,10)];
    [noreMoreTipsLabel setText:@"         Dont Show me Tips:"];
    [noreMoreTipsLabel setFont:[UIFont fontWithName:@"Chewy" size:12]];
    [noreMoreTipsLabel setTextColor:[UIColor whiteColor]];
    [_tip addSubview:noreMoreTipsLabel];

    [_tip addSubview:noMoreTips];
    
    [_tip setText:@"                                Quick Tip\n\n                You make a 5 Fruit Power Up!.\n                Swipe then to destroy all fruits\n                       of the swiped type"];
    
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTip:)];
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTip:)];
    
    [swipeGesture setDirection:(UISwipeGestureRecognizerDirectionLeft |
                                UISwipeGestureRecognizerDirectionRight |
                                UISwipeGestureRecognizerDirectionDown |
                                UISwipeGestureRecognizerDirectionUp)];
    [_tip addGestureRecognizer:swipeGesture];
    [_tip addGestureRecognizer:tap];
    //[self.scene.fruitsLayer setUserInteractionEnabled:NO];
    [_tip setUserInteractionEnabled:YES];
    [self.view addSubview:_tip];
    
    _kascoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fazendeiro_fase"]];
    [_kascoImageView setFrame:CGRectMake(50, 75, 230, 120)];
    [self.view insertSubview:_kascoImageView belowSubview:_tip];
    [_tip setAlpha:1.0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:10.0 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            
            _tip.alpha = 0.1;
            _kascoImageView.alpha = 0.1;
        } completion:^(BOOL finished){
            [_tip setUserInteractionEnabled:NO];
            [_tip removeFromSuperview];
            [_kascoImageView removeFromSuperview];
            
            if (finished)
                _tip = nil;
            
        }];
    });

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"5FruitTutorial"];
    _show5FruitTutorial = NO;
}

- (void)noMoreTips:(UISwitch *)sender{
    _show5FruitTutorial = _show4FruitTutorial = ![sender isOn];
    [[NSUserDefaults standardUserDefaults] setBool:![sender isOn] forKey:@"5FruitTutorial"];
    [[NSUserDefaults standardUserDefaults] setBool:![sender isOn] forKey:@"4FruitTutorial"];
    [self dismissTip:nil];
}



-(void)adicionaMenuRapido
{
    CGFloat buttonSize = 28.0;
    _menuRapido = [[UIButton alloc] initWithFrame:CGRectMake(3, CGRectGetMaxY(self.view.frame) - buttonSize -3, buttonSize, buttonSize)];
    _menuRapido.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"icon_open"]];
    [_menuRapido addTarget:self action:@selector(menuRapido:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_menuRapido];
    
    CGFloat imageSize = 62.0;
    _fundoMenuRapido = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Menu_Rapido_Pequeno"]];
    _fundoMenuRapido.frame = CGRectMake(0, CGRectGetMaxY(self.view.frame) - imageSize, imageSize, imageSize);
    [self.view insertSubview:_fundoMenuRapido belowSubview:_menuRapido];
    
    _ligaSFX = [[UIButton alloc]initWithFrame:CGRectMake(15, 40, 20, 32)];
    [_ligaSFX setBackgroundImage:[UIImage imageNamed:@"icon_som"] forState:UIControlStateNormal];
    [_ligaSFX addTarget:self action:@selector(soundON_OFF:) forControlEvents:UIControlEventTouchUpInside];
    
    _ligaMusica = [[UIButton alloc] initWithFrame:CGRectMake(65, 65, 24, 36)];
    [_ligaMusica setBackgroundImage:[UIImage imageNamed:@"icon_music"] forState:UIControlStateNormal];
    [_ligaMusica addTarget:self action:@selector(musicON_OFF:) forControlEvents:UIControlEventTouchUpInside];
    
    _ajuda = [[UIButton alloc]initWithFrame:CGRectMake(110, 105, 25, 40)];
    [_ajuda setBackgroundImage:[UIImage imageNamed:@"icon_help"] forState:UIControlStateNormal];
    [_ajuda addTarget:self action:@selector(ajuda:) forControlEvents:UIControlEventTouchUpInside];
    
    _btnSair = [[UIButton alloc]initWithFrame:CGRectMake(130, 155, 30, 33)];
    [_btnSair setBackgroundImage:[UIImage imageNamed:@"icon_sair"] forState:UIControlStateNormal];
    [_btnSair addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    _ligaMusica.alpha = 0;
    _ligaSFX.alpha = 0;
    _ajuda.alpha = 0;
    _btnSair.alpha = 0;
    
    [self.fundoMenuRapido addSubview:_ligaMusica];
    [self.fundoMenuRapido addSubview:_ligaSFX];
    [self.fundoMenuRapido addSubview:_ajuda];
    [self.fundoMenuRapido addSubview:_btnSair];
    
    self.fundoMenuRapido.userInteractionEnabled = YES;
}

-(IBAction)menuRapido:(id)sender
{
    if(!_quickMenuOpen){
        //Abrindo o menu
        _quickMenuOpen = YES;
        //Altera o fundo da cesta
        _fundoMenuRapido.image = [UIImage imageNamed:@"Menu_Rapido_Cesta"];
        //Altera o botão
        _menuRapido.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"icon_close"]];
        
        //Anima a porra toda
        [UIView animateWithDuration:0.5
                              delay:0
             usingSpringWithDamping:0.35
              initialSpringVelocity:0
                            options:0
                         animations:^{
                             CGFloat imageSize = 203.0;
                             CGFloat buttonSize = 27.0;
                             
                             _menuRapido.frame = CGRectMake(3, CGRectGetMaxY(self.view.frame) - buttonSize - 3, buttonSize, buttonSize);
                             _fundoMenuRapido.frame = CGRectMake(0, CGRectGetMaxY(self.view.frame) - imageSize, imageSize, imageSize);
                             _ligaMusica.alpha = 1;
                             _ligaSFX.alpha = 1;
                             _ajuda.alpha = 1;
                             _btnSair.alpha = 1;
                         }
                         completion:nil];
    }else{
        //Fechando o menu
        _quickMenuOpen = NO;
        //Altera o fundo da cesta
        _fundoMenuRapido.image = [UIImage imageNamed:@"Menu_Rapido_Pequeno"];
        //Altera o botão
        _menuRapido.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"icon_open"]];
        //Anima a porra toda
        [UIView animateWithDuration:0.5
                              delay:0
             usingSpringWithDamping:0.35
              initialSpringVelocity:0
                            options:0
                         animations:^{
                             CGFloat imageSize = 62.0;
                             CGFloat buttonSize = 28.0;
                             
                             _menuRapido.frame = CGRectMake(3, CGRectGetMaxY(self.view.frame) - buttonSize - 3, buttonSize, buttonSize);
                             _fundoMenuRapido.frame = CGRectMake(0, CGRectGetMaxY(self.view.frame) - imageSize, imageSize, imageSize);
                             _ligaMusica.alpha = 0;
                             _ligaSFX.alpha = 0;
                             _ajuda.alpha = 0;
                             _btnSair.alpha = 0;
                         }
                         completion:nil];
    }
}

-(IBAction)musicON_OFF:(id)sender
{
    [[SettingsSingleton sharedInstance] musicON_OFF];
    if (![SettingsSingleton sharedInstance].music) {
        //adicionar ícone de proibido
        [_ligaMusica setBackgroundImage:[UIImage imageNamed:@"no_music"] forState:UIControlStateNormal];
        _ligaMusica.frame = CGRectMake(_ligaMusica.center.x - 19.5, _ligaMusica.center.y - 21.5, 39, 43);
        [self.backgroundMusic stop];
    }else{
        //remove ícone de proibido
        [_ligaMusica setBackgroundImage:[UIImage imageNamed:@"icon_music"] forState:UIControlStateNormal];
        _ligaMusica.frame = CGRectMake(65, 65, 24, 36);
        [self.backgroundMusic play];
    }
}

-(IBAction)soundON_OFF:(id)sender
{
    [[SettingsSingleton sharedInstance] soundON_OFF];
    if (![SettingsSingleton sharedInstance].SFX) {
        //adicionar ícone de proibido
        [_ligaSFX setBackgroundImage:[UIImage imageNamed:@"no_sfx"] forState:UIControlStateNormal];
        _ligaSFX.frame = CGRectMake(_ligaSFX.center.x - 19.5, _ligaSFX.center.y - 21.5, 39, 43);
    }else{
        //remove ícone de proibido
        [_ligaSFX setBackgroundImage:[UIImage imageNamed:@"icon_som"] forState:UIControlStateNormal];
        _ligaSFX.frame = CGRectMake(15, 40, 20, 32);
    }
}

-(IBAction)ajuda:(id)sender
{
    NSLog(@"ajuda");
}

@end
