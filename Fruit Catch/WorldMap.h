//
//  WorldMap.h
//  Fruit Catch
//
//  Created by Júlio Menezes Noronha on 03/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Life.h"

@interface WorldMap : UIViewController <UIScrollViewDelegate>


@property (weak, nonatomic) IBOutlet UIView *livesView;

@property(nonatomic) Life *lives;

@property (weak, nonatomic) IBOutlet UIImageView *LifeView1;
@property (weak, nonatomic) IBOutlet UIImageView *LifeView2;
@property (weak, nonatomic) IBOutlet UIImageView *LifeView3;
@property (weak, nonatomic) IBOutlet UIImageView *LifeView4;
@property (weak, nonatomic) IBOutlet UIImageView *LifeView5;

@property (nonatomic) CGFloat xPosition;
@property (nonatomic) CGFloat yPosition;

@property(nonatomic) UIScrollView *scroll1;

@end
