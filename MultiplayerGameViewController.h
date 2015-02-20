//
//  MultiplayerGameViewController.h
//  Fruit Catch
//
//  Created by Caio de Souza on 13/01/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <SpriteKit/SpriteKit.h>

typedef enum {
    kEndReasonWin,
    kEndReasonLose
} EndReason;

typedef enum {
    kGameStateActive,
    kGameStateDone
} GameState;



@interface MultiplayerGameViewController : UIViewController

@property (assign, nonatomic) NSUInteger score;
@property (nonatomic) NSString *levelString;
@property (weak, nonatomic) IBOutlet UIButton *backButton;


//@property (strong, nonatomic) JIMCLevel *level;
- (void)beginNextTurn ;
- (void)updateLabels ;

- (void)shuffle;
- (void)beginGame;

- (void)back;



@end
