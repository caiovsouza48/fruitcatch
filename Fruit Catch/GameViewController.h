//
//  GameViewController.h
//  Fruit Catch
//

//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import "JIMCLevel.h"
@interface GameViewController : UIViewController

@property (assign, nonatomic) NSUInteger score;
//@property (strong, nonatomic) JIMCLevel *level;
- (void)beginNextTurn ;
- (void)updateLabels ;
@property (nonatomic) NSString *levelString;

@end
