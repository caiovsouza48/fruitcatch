//
//  MultiplayerGameViewController.m
//  Fruit Catch
//
//  Created by Caio de Souza on 13/01/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import "MultiplayerGameViewController.h"
#import "MyScene.h"
#import "JIMCLevel.h"
#import "JIMCSwapFruitSingleton.h"
#import "JIMCPowerUp.h"
#import "SettingsSingleton.h"
#import "Life.h"
#import "NetworkController.h"
#import <Nextpeer/Nextpeer.h>
#import <Nextpeer/NPTournamentDelegate.h>
#import "NextpeerHelper.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "AppUtils.h"
#import "JTSlideShadowAnimation.h"
#import <AudioToolbox/AudioServices.h>
#import "EloRating.h"

#define playerIdKey @"PlayerId"
#define randomNumberKey @"randomNumber"

#define START_GAME_SYNC_EVENT_NAME @"com.sucodefrutasteam.fruitcatch.syncevent.startgame"
#define TIMEOUT 5.0

@interface MultiplayerGameViewController () <NPTournamentDelegate>

// The level contains the tiles, the fruits, and most of the gameplay logic.
@property (nonatomic) JIMCLevel *level;


// The scene draws the tiles and fruit sprites, and handles swipes.
@property (nonatomic) MyScene *scene;

@property(nonatomic) UIView *player1View;

@property(nonatomic) UIView *player2View;

@property(nonatomic) UILabel *player1Score;

@property(nonatomic) UILabel *player2Score;

@property(nonatomic) UILabel *player1EloLabel;

@property(nonatomic) UILabel *player2EloLabel;



@property (assign, nonatomic) NSUInteger movesLeft;


@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (weak, nonatomic) IBOutlet UILabel *movesLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UIButton *shuffleButton;
@property (weak, nonatomic) IBOutlet UIImageView *gameOverPanel;

@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic) AVAudioPlayer *backgroundMusic;

@property (nonatomic) NSSet *possibleMoves;

@property(nonatomic) int randomNumber;

@property(nonatomic) NSMutableArray *orderOfPlayers;

@property(nonatomic) __block NSMutableArray *arrayOfColumnArray;

@property(nonatomic) BOOL isMyMove;

@property(nonatomic) BOOL isFirstRound;

@property(nonatomic) NSMutableArray *parameter;

@property(nonatomic) NSUInteger player1Elo;

@property(nonatomic) NSUInteger player2Elo;

@property(nonatomic) NSUInteger opponentScore;

@property(nonatomic) SKAction *turnSound;

@property(nonatomic) UILabel *turnLabel;

@property(nonatomic) JTSlideShadowAnimation *shadowAnimation;
@property(nonatomic) BOOL opponentOver;

@end

@implementation MultiplayerGameViewController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    _shadowAnimation = [JTSlideShadowAnimation new];
    _opponentScore = 0;
    _opponentOver = NO;
     _turnSound = [SKAction playSoundFileNamed:@"turn_sound.mp3" waitForCompletion:NO];
    CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
    _turnLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMidX(mainScreenBounds)-60, CGRectGetMidY(mainScreenBounds)-180, 170, 30)];
    _parameter = [[NSMutableArray alloc]init];
    _orderOfPlayers = [NSMutableArray array];
    _isMyMove = NO;
    _isFirstRound = YES;
    _arrayOfColumnArray = [NSMutableArray array];
    [self registerNotifications];
    //[self.networkEngine setDelegate:self];
    // Configure the view.
    SKView *skView = [[SKView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.view = skView;
    //_multipleTouchEnabled = NO;
    
    // Create and configure the scene.
    self.scene = [MyScene sceneWithSize:skView.bounds.size];
    self.scene.scaleMode = SKSceneScaleModeAspectFill;
    
    //self.scene.viewController = self;
    self.levelString = @"Level_0";
    // Load the level.
    self.level = [[JIMCLevel alloc] initWithFile:self.levelString];
    self.scene.level = self.level;
    [self.scene addTiles];
    UIButton *surrenderButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame)-40, 0, 100, 50)];
    [surrenderButton setTitle:@"Surrender" forState:UIControlStateNormal];
    [surrenderButton addTarget:self action:@selector(didSurrender:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:surrenderButton];
    
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
            //[self handleMatches];
        }else if ([self.level isPossibleSwap:swap]) {
            [self.level performSwap:swap];
            [JIMCSwapFruitSingleton sharedInstance].swap = swap;
            //  NSLog(@"fruta singleton ==  %@",[JIMCSwapFruitSingleton sharedInstance].fruit);
            
            [self.scene animateSwap:swap completion:^{
                [self handleMatches];
            }];
            
        } else {
            [self.scene animateInvalidSwap:swap completion:^{
                self.view.userInteractionEnabled = YES;
            }];
        }
        //[self showTurnAlert:_isMyMove];
        _isFirstRound = NO;
    };
    
    
    self.scene.swipeHandler = block;
    
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
    
    //[self setGameState:kGameStateActive];
    [self.scene setUserInteractionEnabled:NO];
    [Nextpeer registerToSynchronizedEvent:START_GAME_SYNC_EVENT_NAME withTimetout:TIMEOUT];
    [self.view addSubview:_turnLabel];
    
    
    
}

- (void)loadPlayersView{
    _player1View =[[UIView alloc] initWithFrame:CGRectMake(10, 10, 100, 100)];
    UILabel *player1Name = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 200, 100)];
    [player1Name setTextColor:[UIColor blackColor]];
    [_player1View setBackgroundColor:[UIColor blueColor]];
    [player1Name setText:_orderOfPlayers[0][playerIdKey]];
    [_player1View addSubview:player1Name];
    _player1Score = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 100, 50)];
    [_player1Score setText:@"0"];
    [_player1View addSubview:_player1Score];
    _player1EloLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 60, 100, 50)];
    [_player1EloLabel setText:[NSString stringWithFormat:@"%lu",(unsigned long)_player1Elo]];
    [_player1View addSubview:_player1EloLabel];
    [self.view addSubview:_player1View];
    [Nextpeer enableRankingDisplay:NO];
}

- (void)loadPlayer2View{
    CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
    _player2View =[[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(mainScreenBounds) - 110, 10, 100, 100)];
    UILabel *player2Name = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 200, 100)];
    [player2Name setTextColor:[UIColor blackColor]];
    [_player2View setBackgroundColor:[UIColor blueColor]];
    [player2Name setText:_orderOfPlayers[1][playerIdKey]];
    [_player2View addSubview:player2Name];
    _player2Score = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 100, 50)];
    [_player2Score setText:@"0"];
    [_player2Score setTextColor:[UIColor blackColor]];
    [_player2View addSubview:_player2Score];
    _player2EloLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 60, 100, 50)];
    
    [_player2EloLabel setText:[NSString stringWithFormat:@"%lu",(unsigned long)_player2Elo]];
    [_player2EloLabel setTextColor:[UIColor blackColor]];
    [_player2View addSubview:_player2EloLabel];
    [self.view addSubview:_player2View];
    [Nextpeer enableRankingDisplay:NO];
}

- (NSUInteger) getUserElo{
    NSString *userEloPath = [AppUtils getAppMultiplayer];
    if ([[NSFileManager defaultManager] fileExistsAtPath:userEloPath]) {
        NSData *data = [NSData dataWithContentsOfFile:userEloPath];
        NSError *error;
        NSData *decryptedData = [RNDecryptor decryptData:data withPassword:MULTIPLAYER_SECRET error:&error];
        if (!error){
            NSDictionary *obj = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            _player1Elo = [obj[@"elo"] unsignedIntegerValue];
        }
    }

    return 0;
}

- (NSArray *)fruitObjToFruitStringArray:(NSArray *)fruitObjArray{
    NSMutableArray *ret = [NSMutableArray array];
    NSMutableArray *auxRet = [NSMutableArray array];
    for (NSArray *array in fruitObjArray) {
        for (JIMCFruit *fruit in array) {
            [auxRet addObject:[fruit stringRepresentation]];
        }
        [ret addObject:[NSArray arrayWithArray:[NSArray arrayWithArray:auxRet]]];
        auxRet = [NSMutableArray array];
    }
//    for (JIMCFruit *fruit in fruitObjArray) {
//        [ret addObject:[fruit stringRepresentation]];
//    }
    return [ret copy];

}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void) generateRandomNumber{
    self.randomNumber = arc4random();
    
}

- (void)registerNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNextpeerDidReceiveTournamentCustomMessage:) name:@"nextpeerDidReceiveTournamentCustomMessage" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNextpeerDidReceiveSynchronizedEvent:) name:@"nextpeerDidReceiveSynchronizedEvent" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNextpeerReportForfeitForCurrentTournament:) name:@"nextpeerreportForfeitForCurrentTournament" object:nil];
}



- (void)processNextpeerDidReceiveSynchronizedEvent:(NSNotification *)notification{
    NSString *eventName = [notification.userInfo objectForKey:@"eventName"];
   // NPSynchronizedEventFireReason eventFireReason = [[notification.userInfo objectForKey:@"fireReason"] intValue];
    NSLog(@"Event Firing");
    if ([START_GAME_SYNC_EVENT_NAME isEqualToString:eventName]) {
        [self generateRandomNumber];
        [self getUserElo];
        ;
        [NextpeerHelper sendMessageOfType:NPFruitCatchMessageSendRandomNumber DictionaryData:@{@"randomNumber" : [NSNumber numberWithInteger:_randomNumber],
                             @"userElo" : [NSNumber numberWithUnsignedInteger:_player1Elo],
                            }];
    }
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
    //self.hintAction = [SKAction sequence:@[[SKAction waitForDuration:5 withRange:0], [SKAction performSelector:@selector(showMoves) onTarget:self]]];
    
    //[self.scene runAction: self.hintAction withKey:@"Hint"];
}

- (void)beginGameForPlayer2 {
    self.movesLeft = self.level.maximumMoves;
    self.score = 0;
    [self updateLabels];
    [self.level resetComboMultiplier];
    [self.scene animateBeginGame];
    //[self shuffle];
    // Delete the old fruit sprites, but not the tiles.
    [self.scene removeAllFruitSprites];
    _isFirstRound = NO;
    
    // Fill up the level with new fruits, and create sprites for them.
   // NSSet *newFruits = [self.level shuffle];
    
    
    //self.possibleMoves = [self.level detectPossibleSwaps];
    //self.hintAction = [SKAction sequence:@[[SKAction waitForDuration:5 withRange:0], [SKAction performSelector:@selector(showMoves) onTarget:self]]];
    
    //[self.scene runAction: self.hintAction withKey:@"Hint"];
}

- (void)shuffle {
    
    // Delete the old fruit sprites, but not the tiles.
    [self.scene removeAllFruitSprites];
    
    // Fill up the level with new fruits, and create sprites for them.
    NSSet *newFruits = [self.level shuffle];
    [self.scene addSpritesForFruits:newFruits];
}

- (NSArray *)shuffledStringArrayOfFruits{
     [self.scene removeAllFruitSprites];
    NSSet * newFruits = [self.level shuffle];
    NSMutableArray *fruitStringArray = [NSMutableArray array];
    for (JIMCFruit *fruit in [newFruits allObjects]) {
        [fruitStringArray addObject:[fruit stringRepresentation]];
    }
    [self.scene addSpritesForFruits:newFruits];
    return fruitStringArray;
    
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
        if ((_isMyMove) && (!_isFirstRound)){
//            NSMutableArray *sendingArray = [NSMutableArray array];
//            for (NSArray *array in _arrayOfColumnArray) {
//                [sendingArray addObject:[self fruitObjToFruitStringArray:array]];
//            }
            
            [NextpeerHelper sendMessageOfType:NPFruitCatchMessageMove DictionaryData:@{@"moveColumn" : [NSNumber numberWithInt:self.scene.playerLastTouch.x],              @"moveRow" : [NSNumber numberWithInt:self.scene.playerLastTouch.y ],                 @"topUpFruits" : _parameter,
                                                                                       @"swipeColumn" : [NSNumber numberWithInt:self.scene.swipeFromLastPoint.x],
                                                                                       @"swipeRow" : [NSNumber numberWithInt:self.scene.swipeFromLastPoint.y]}];
            //_isMyMove = NO;
            _parameter = [NSMutableArray array];
            self.scene.playerLastTouch = (CGPoint){-1,-1};
            self.scene.lastTouchAssigned = NO;
            _isMyMove = NO;
            [self.view setUserInteractionEnabled:NO];
            [self showTurnAlert:NO];
        }
        else{
            if (!_isFirstRound){
                _isMyMove = YES;
                [self showTurnAlert:_isMyMove];
                [self.scene setUserInteractionEnabled:_isMyMove];
                //_arrayOfColumnArray = [NSMutableArray array];
            }
        }
        
        //_isMyMove = _isExecutingOpponentMove;
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
            NSArray *columns;
            if (_isMyMove){
                [_player1Score setText:[NSString stringWithFormat:@"%lu",(unsigned long)self.score]];
                columns = [self.level multiplayerTopUpFruits];
                [_arrayOfColumnArray addObject:columns];
                [_parameter addObjectsFromArray:self.level.parameter];
                [self.scene animateNewFruits:columns completion:^{
                    
                    // Keep repeating this cycle until there are no more matches.
                    [self handleMatches];
                }];
            }
            else{
                //columns = [_arrayOfColumnArray objectAtIndex:_fruitCounter];
                columns = [self.level topUpFruitsFor:_parameter];
                _parameter = self.level.fruitTypeArray;
                //columns = [self.level newTopUpFruitsFor:[_arrayOfColumnArray objectAtIndex:_fruitCounter]];
                [_player2Score setText:[NSString stringWithFormat:@"%lu",(unsigned long)self.score]];
                [self.scene animateNewFruits:columns completion:^{
                    
                    // Keep repeating this cycle until there are no more matches.
                    [self handleMatches];
                }];
            }
        }];
    }];
}
- (void)handleMatchesAll{
    // This is the main loop that removes any matching fruits and fills up the
    // holes with new fruits. While this happens, the user cannot interact with
    // the app.
    
    [self.scene removeActionForKey:@"Hint"];
    
    // Detect if there are any matches left.
    NSSet *chains = [self.level removeMatchesAll];
    // If there are no more matches, then the player gets to move again.
    
    if ([chains count] == 0) {
        if ((_isMyMove) && (!_isFirstRound)){
            [NextpeerHelper sendMessageOfType:NPFruitCatchMessageMove DictionaryData:@{@"moveColumn" : [NSNumber numberWithInt:self.scene.playerLastTouch.x],              @"moveRow" : [NSNumber numberWithInt:self.scene.playerLastTouch.y ],                 @"topUpFruits" : _parameter,
                                                                                       @"swipeColumn" : [NSNumber numberWithInt:self.scene.swipeFromLastPoint.x],
                                                                                       @"swipeRow" : [NSNumber numberWithInt:self.scene.swipeFromLastPoint.y]}];
            //_isMyMove = NO;
            self.scene.playerLastTouch = (CGPoint){-1,-1};
            self.scene.lastTouchAssigned = NO;
            _isMyMove = NO;
            [self.view setUserInteractionEnabled:NO];
            [self showTurnAlert:NO];
        }
        else{
            if (!_isFirstRound){
                _isMyMove = YES;
                [self showTurnAlert:_isMyMove];
                [self.scene setUserInteractionEnabled:_isMyMove];
                //_arrayOfColumnArray = [NSMutableArray array];
            }
        }
        
        //_isMyMove = _isExecutingOpponentMove;
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
            NSArray *columns;
            if (_isMyMove){
                [_player1Score setText:[NSString stringWithFormat:@"%lu",(unsigned long)self.score]];
                columns = [self.level multiplayerTopUpFruits];
                [_parameter addObjectsFromArray:self.level.parameter];
                [self.scene animateNewFruits:columns completion:^{
                    
                    // Keep repeating this cycle until there are no more matches.
                    [self handleMatches];
                }];
            }
            else{
                //columns = [_arrayOfColumnArray objectAtIndex:_fruitCounter];
                columns = [self.level topUpFruitsFor:_parameter];
                 _parameter = self.level.fruitTypeArray;
                [self.scene animateNewFruits:columns completion:^{
                    
                    // Keep repeating this cycle until there are no more matches.
                    [self handleMatches];
                }];
            }
        }];
    }];
}

- (NSArray *)reversedFruits:(NSMutableArray *)fruits{
    NSMutableArray *mutableArray = fruits;
    NSInteger i=0;
    NSInteger j=[fruits count]-1;
    while (i<j) {
        [mutableArray exchangeObjectAtIndex:i withObjectAtIndex:j];
        i++;
        j--;
    }
    return [mutableArray copy];
    
}


- (void)handleMatches {
    // This is the main loop that removes any matching fruits and fills up the
    // holes with new fruits. While this happens, the user cannot interact with
    // the app.
    dispatch_queue_t messageQueue;
    messageQueue = dispatch_queue_create("com.valheru.messageQueue", NULL);
    
    [self.scene removeActionForKey:@"Hint"];
    // Detect if there are any matches left.
    NSSet *chains = [self.level removeMatches];
    
    // If there are no more matches, then the player gets to move again.
    if ([chains count] == 0) {
            if ((_isMyMove) && (!_isFirstRound)){
                
            [NextpeerHelper sendMessageOfType:NPFruitCatchMessageMove DictionaryData:@{@"moveColumn" : [NSNumber numberWithInt:self.scene.playerLastTouch.x],              @"moveRow" : [NSNumber numberWithInt:self.scene.playerLastTouch.y ],                 @"topUpFruits" : _parameter,
                                                                                       @"swipeColumn" : [NSNumber numberWithInt:self.scene.swipeFromLastPoint.x],
                                                                                       @"swipeRow" : [NSNumber numberWithInt:self.scene.swipeFromLastPoint.y]}];
            //_isMyMove = NO;
                self.scene.playerLastTouch = (CGPoint){-1,-1};
                self.scene.lastTouchAssigned = NO;
                _isMyMove = NO;
                [self.view setUserInteractionEnabled:NO];
                [self showTurnAlert:NO];
        }
        else{
            if (!_isFirstRound){
                _isMyMove = YES;
                [self showTurnAlert:_isMyMove];
                [self.scene setUserInteractionEnabled:_isMyMove];
                //_arrayOfColumnArray = [NSMutableArray array];
            }
        }
        
        //_isMyMove = _isExecutingOpponentMove;
        [self beginNextTurn];
        return;
    }
    
    // First, remove any matches...
    dispatch_sync(messageQueue, ^{
    [self.scene animateMatchedFruits:chains completion:^{
        // Add the new scores to the total.
        for (JIMCChain *chain in chains) {
            for (JIMCFruit *fruit in chain.fruits) {
                if ((fruit.fruitPowerUp == 1 && chain.fruits.count == 5) ||
                    (fruit.fruitPowerUp == 2 && chain.fruits.count == 4) || (fruit.fruitPowerUp == 3 && chain.fruits.count == 4)) {
                    
                    [self.scene addSpritesForFruit:fruit];
                    [JIMCSwapFruitSingleton sharedInstance].swap = nil;
                    //break;
                }
            }
        }
        
        
        for (JIMCChain *chain in chains) {
            if (_isMyMove){
                self.score += chain.score;
            }
            else{
                self.opponentScore += chain.score;
            }
            
            
        }
        [self updateLabels];
        
        // ...then shift down any fruits that have a hole below them...
        NSArray *columns = [self.level fillHoles];
        [self.scene animateFallingFruits:columns completion:^{
            NSArray *columns;
            if (_isMyMove){
                [_player1Score setText:[NSString stringWithFormat:@"%lu",(unsigned long)self.score]];
                columns = [self.level multiplayerTopUpFruits];
                [_parameter addObjectsFromArray:self.level.parameter];
                [self.scene animateNewFruits:columns completion:^{
                    // Keep repeating this cycle until there are no more matches.
                    [self handleMatches];
                }];
            }
            else{
                columns = [self.level topUpFruitsFor:_parameter];
                _parameter = self.level.fruitTypeArray;
                
                [self.scene animateNewFruits:columns completion:^{
                    // Keep repeating this cycle until there are no more matches.
                    [self handleMatches];
                    //_auxiliaryArray = [NSMutableArray array];
                }];
            }
        }];
    }];
    
    });
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
        if ((_isMyMove) && (!_isFirstRound)){
            //            NSMutableArray *sendingArray = [NSMutableArray array];
            //            for (NSArray *array in _arrayOfColumnArray) {
            //                [sendingArray addObject:[self fruitObjToFruitStringArray:array]];
            //            }
            
            [NextpeerHelper sendMessageOfType:NPFruitCatchMessageMove DictionaryData:@{@"moveColumn" : [NSNumber numberWithInt:self.scene.playerLastTouch.x],              @"moveRow" : [NSNumber numberWithInt:self.scene.playerLastTouch.y ],                 @"topUpFruits" : _parameter,
                                                                                       @"swipeColumn" : [NSNumber numberWithInt:self.scene.swipeFromLastPoint.x],
                                                                                       @"swipeRow" : [NSNumber numberWithInt:self.scene.swipeFromLastPoint.y]}];
            //_isMyMove = NO;
            _parameter = [NSMutableArray array];
            self.scene.playerLastTouch = (CGPoint){-1,-1};
            self.scene.lastTouchAssigned = NO;
            _isMyMove = NO;
            [self.view setUserInteractionEnabled:NO];
            [self showTurnAlert:NO];
        }
        else{
            if (!_isFirstRound){
                _isMyMove = YES;
                [self showTurnAlert:_isMyMove];
                [self.scene setUserInteractionEnabled:_isMyMove];
                //_arrayOfColumnArray = [NSMutableArray array];
            }
        }
        
        //_isMyMove = _isExecutingOpponentMove;
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
            
            NSArray *columns;
            if (_isMyMove){
                [_player1Score setText:[NSString stringWithFormat:@"%lu",(unsigned long)self.score]];
                columns = [self.level multiplayerTopUpFruits];
                [_parameter addObjectsFromArray:self.level.parameter];
                [self.scene animateNewFruits:columns completion:^{
                    // Keep repeating this cycle until there are no more matches.
                    [self handleMatches];
                }];
            }
            else{
                columns = [self.level topUpFruitsFor:_parameter];
                 _parameter = self.level.fruitTypeArray;
                //columns = [self.level createTopUpFruitsFor:_arrayOfColumnArray];
                [self.scene animateNewFruits:columns completion:^{
                    // Keep repeating this cycle until there are no more matches.
                    [self handleMatches];
                    
                }];
            }
            
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
    
    //[self.scene runAction: self.hintAction withKey:@"Hint"];
    //SKAction *showMove = [SKAction repeatActionForever:[SKAction sequence:@[[SKAction waitForDuration:5 withRange:0], [SKAction performSelector:@selector(showMoves) onTarget:self]]]];
    
    //self.view.userInteractionEnabled = YES;
    [self decrementMoves];
    
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
    self.player2Score.text = [NSString stringWithFormat:@"%lu",(unsigned long)self.opponentScore];
    
}

- (void)decrementMoves{
    self.movesLeft--;
    [self updateLabels];
    if (self.movesLeft <= 0) {
        [NextpeerHelper sendMessageOfType:NPFruitCatchMessageGameOver];
         [self tryGameOver];
        //[Nextpeer reportControlledTournamentOverWithScore:self.score];
//        [self.scene animateGameOver];
//        self.movesLeft = self.level.maximumMoves;
//        self.score = 0;
//        [self updateLabels];
        
    }
    
    //[self.scene removeActionForKey:@"Hint"];
    
}

- (void)showGameOver {
    
    [self.scene removeActionForKey:@"Hint"];
//    if(self.hintNode){
//        [self.scene runAction:[SKAction runBlock:^{
//            [self.hintNode removeFromParent];
//        }]];
//    }
    
    
    
    self.gameOverPanel.hidden = NO;
    self.scene.userInteractionEnabled = NO;
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideGameOver)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    
    self.shuffleButton.hidden = YES;
    
}

- (void)hideGameOver {
    
    [self.scene removeActionForKey:@"Hint"];
    
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
    //Metodos comentado para tirar o warning
    //UITouch *touch = [touches anyObject];
   // CGPoint point = [touch locationInNode:self.scene];
    //[[NetworkController sharedInstance] sendMovedSelf:1];
    [self.scene removeActionForKey:@"Hint"];
//    if(self.hintNode){
//        [self.scene runAction:[SKAction runBlock:^{
//            [self.hintNode removeFromParent];
//        }]];
//    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //[self.scene runAction: self.hintAction withKey:@"Hint"];
}

-(IBAction)back:(id)sender
{
    _backButton.enabled = NO;
    [self performSegueWithIdentifier:@"Back" sender:self];
}

-(void)back {
    [self performSegueWithIdentifier:@"Back" sender:self];
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

- (void)showTurnAlert:(BOOL)isMyTurn{
    
    if (([SettingsSingleton sharedInstance].SFX == ON) && (_isMyMove)){
        [self.scene runAction:self.turnSound];
    }
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    [_turnLabel setTextColor:[UIColor grayColor]];
    _turnLabel.text = isMyTurn ? @"Now its your turn!" : @"Opponent Turn";
    [_turnLabel setHidden:NO];
  
    [UIView animateWithDuration:1.25 animations:^{
          _turnLabel.transform = CGAffineTransformMakeScale(1.75,1.75);
        
    } completion:^(BOOL finished){
        [UIView animateWithDuration:1.25 animations:^{
             _turnLabel.transform = CGAffineTransformMakeScale(1.0,1.0);
            
            [_shadowAnimation setAnimatedView:_turnLabel];
            [_shadowAnimation start];
        }];
       
    }];



}

-(void)processNextpeerDidReceiveTournamentCustomMessage:(NSNotification *)notification{
    
    NPTournamentCustomMessageContainer* message = (NPTournamentCustomMessageContainer*)[notification.userInfo objectForKey:@"userMessage"];
    NSLog(@"Received game message from %@", message.playerName);
    
    NSDictionary* gameMessage = [NSPropertyListSerialization propertyListWithData:message.message options:0 format:NULL error:NULL];
    int type = [[gameMessage objectForKey:@"type"] intValue];
   
    switch (type) {
            
        case NPFruitCatchMessageEventOver:
        {
            break;
        }
        case NPFruitCatchMessageSendLevel:
        {
            NSLog(@"Received Message Level");
            //NSData *fruitData = [gameMessage objectForKey:@"gameLevel"];
            NSArray *wrapperArray = [gameMessage objectForKey:@"gameLevel"];
           
            NSSet *receivedFruitSet = [self fruitObjectSetByFruitArray:wrapperArray];
            //[fruitData getBytes:&receivedFruitStruct length:pointerSize];
            
            [self beginGameForPlayer2];
            [self.scene removeAllFruitSprites];
            [self.level setFruitsBySet:receivedFruitSet];
            [self.scene addSpritesForFruits:receivedFruitSet];
            self.possibleMoves = [self.level detectPossibleSwaps];
            [NextpeerHelper sendMessageOfType:NPFruitCatchMessageBeginGame];
            [self.scene setUserInteractionEnabled:NO];
            [self showTurnAlert:NO];
            _isMyMove = NO;
            break;
            
        }
        case NPFruitCatchMessageSendRandomNumber:
        {
            NSLog(@"Received Random Number");
            //NSDictionary *dict = [NSDictionary alloc]init
            NSDictionary *parameterDict = @{playerIdKey : message.playerName,
                                            randomNumberKey : [gameMessage objectForKey:@"randomNumber"]
                                            };
            NSDictionary *myInfo = @{playerIdKey : [Nextpeer getCurrentPlayerDetails].playerName,
                                     randomNumberKey : [NSNumber numberWithInt:self.randomNumber]};
            [_orderOfPlayers addObject:myInfo];
           if (![_orderOfPlayers containsObject:parameterDict]){
               [_orderOfPlayers addObject:parameterDict];
               
               
               _player2Elo = [[gameMessage objectForKey:@"userElo"] unsignedIntegerValue];
               [self loadPlayersView];
               [self loadPlayer2View];
            }
           
            if ([[gameMessage objectForKey:@"randomNumber"] intValue] == _randomNumber) {
                //2
                
                NSLog(@"Tie");
                _randomNumber = arc4random();
                [self generateRandomNumber];
                
                [NextpeerHelper sendMessageOfType:NPFruitCatchMessageSendRandomNumber DictionaryData:@{@"randomNumber" : [NSNumber numberWithInt:self.randomNumber]}];
            } else {
                //3
                    if (self.randomNumber > [[gameMessage objectForKey:@"randomNumber"] intValue]){
                        [self beginGame];
                        [self.scene setUserInteractionEnabled:NO];
                        //NSData *dataFromSet = [NSData dataWithBytes:&shuffledFruitStruct length:sizeof(shuffledFruitStruct)];
                        NSArray *wrapperArray = [self shuffledStringArrayOfFruits];
                        //NSLog(@"Wrapper Array of Sender: %@",wrapperArray);
                        [NextpeerHelper sendMessageOfType:NPFruitCatchMessageSendLevel DictionaryData:@{@"gameLevel" : wrapperArray,
                                           }];
                    [self showTurnAlert:YES];
                    _isMyMove = YES;
                   }
                
        }
        break;
        }
        case NPFruitCatchMessageBeginGame:
        {
            [self.scene setUserInteractionEnabled:YES];
            break;
        }
        case NPFruitCatchMessageMove:
        {
            NSLog(@"Received Message Move");
            _isMyMove = NO;
             [_shadowAnimation stop];
            [self.level setIsOpponentMove:YES];
            CGPoint oponentLocation = CGPointMake([[gameMessage objectForKey:@"moveColumn"] intValue], [[gameMessage objectForKey:@"moveRow"] intValue]);
            CGPoint opponentSwipe = CGPointMake([[gameMessage objectForKey:@"swipeColumn"] intValue], [[gameMessage objectForKey:@"swipeRow"] intValue]);
            _parameter = [gameMessage objectForKey:@"topUpFruits"];
            [self.scene touchAtColumRowCGPoint:oponentLocation OpponentSwipe:opponentSwipe];
            [self.view setUserInteractionEnabled:YES];
            [self.level setIsOpponentMove:NO];
            break;
        }
        case NPFruitCatchMessageGameOver:
        {
            _opponentOver = YES;
            [self tryGameOver];
            
            
        }
        
    }
}

- (void)processNextpeerReportForfeitForCurrentTournament:(NSNotification *)notification{
    NSLog(@"Player Saiu, reportando score");
     [_turnLabel setText:@"The opponent surrendered"];
    [UIView animateWithDuration:1.25 animations:^{
        _turnLabel.transform = CGAffineTransformMakeScale(1.75,1.75);
    }];
    
    
    [Nextpeer reportControlledTournamentOverWithScore:(int)self.score];
}

- (void)tryGameOver{
    if ((_opponentOver) && (self.movesLeft == 0)){
      [Nextpeer reportControlledTournamentOverWithScore:(u_int32_t)self.score];
        EloRating *eloRatingSystem = [[EloRating alloc] init];
        JIMCGameResult result;
        NSInteger score1 = [self.player1Score.text integerValue];
        NSInteger score2 = [self.player2Score.text integerValue];
        if (score1 > score2){
            result = WIN;
        }
        else if (score1 < score2){
            result = LOSS;
        }
        else{
            result = DRAW;
        }
        [eloRatingSystem getNewRating:(int)self.player1Elo OpponentRating:(int)[self player2Elo] GameResult:result];
        [self saveElo];
        
    }
}

- (void)saveElo{
    NSDictionary *userDict = @{@"elo" : [NSNumber numberWithUnsignedInteger:self.player1Elo]
                               };
    
    NSString *filePath = [AppUtils getAppMultiplayer];
    NSData *dataToSave = [NSKeyedArchiver archivedDataWithRootObject:userDict];
    NSError *error2;
    NSData *encryptedData = [RNEncryptor encryptData:dataToSave
                                        withSettings:kRNCryptorAES256Settings
                                            password:MULTIPLAYER_SECRET
                                               error:&error2];
    
    BOOL sucess = [encryptedData writeToFile:filePath atomically:YES];
    if (sucess){
        NSLog(@"Elo Saved Sucessfuly");
    }
    else{
        NSLog(@"Falha ao Salvar Elo");
    }
}


- (void) didSurrender:(id)sender{
    
    [Nextpeer reportForfeitForCurrentTournament];
    [Nextpeer reportControlledTournamentOverWithScore:0];
}

- (NSMutableArray *)fruitStringRepresentationArrayToObjArray{
    NSMutableArray *ret = [NSMutableArray array];
    NSMutableArray *auxiliaryArray = [NSMutableArray array];
    NSMutableArray *auxiliaryArray2 = [NSMutableArray array];
    int i,j,k;
    i=j=k=0;
    for (NSArray *array in _arrayOfColumnArray) {
        for (NSArray *array2 in array) {
            for (NSString *str in array2) {
                //[[[_arrayOfColumnArray objectAtIndex:i] objectAtIndex:j] replaceObjectAtIndex:k withObject:[JIMCFruit fruitByStringRepresentation:str]];
                [auxiliaryArray addObject:[JIMCFruit fruitByStringRepresentation:str]];
                //k++;
            }
            [auxiliaryArray2 addObject:[auxiliaryArray copy]];
            auxiliaryArray = [NSMutableArray array];
            //j++;
        }
        [ret addObject:[auxiliaryArray2 copy]];
        auxiliaryArray2 = [NSMutableArray array];
        
    }
    return ret;
}

- (NSSet *)fruitObjectSetByFruitArray:(NSArray *)fruitArray{
    NSMutableSet *ret = [NSMutableSet set];
    for (NSString *stringRepresentation in fruitArray) {
        [ret addObject:[JIMCFruit fruitByStringRepresentation:stringRepresentation]];
    }
    return [ret copy];
    
}

@end