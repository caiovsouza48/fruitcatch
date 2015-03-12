//
//  GameViewController.h
//  Fruit Catch
//

//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import "JIMCLevel.h"
#import <FacebookSDK/FacebookSDK.h>
@interface GameViewController : UIViewController

@property (assign, nonatomic) NSUInteger score;
//@property (strong, nonatomic) JIMCLevel *level;
@property (weak, nonatomic) IBOutlet UIView *powerUpView;
@property (weak, nonatomic) IBOutlet UIImageView *powerUpImage1;
@property (weak, nonatomic) IBOutlet UIImageView *powerUpImage2;
@property (weak, nonatomic) IBOutlet UIImageView *powerUpUmage3;
@property (nonatomic) NSString *levelString;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

- (void)beginNextTurn ;
- (void)updateLabels ;
- (void)shuffle;
- (void)beginGame;
- (void)back;
- (void)nextStage;

@end
