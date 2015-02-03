//
//  MainMenuViewController.h
//  Fruit Catch
//
//  Created by Júlio Menezes Noronha on 28/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface MainMenuViewController : UIViewController <FBLoginViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *singlePlayerButton;
@property (weak, nonatomic) IBOutlet FBLoginView *loginView;

@property  ( strong , nonatomic )  IBOutlet  FBProfilePictureView  * profilePictureView ;
@property  ( strong , nonatomic )  IBOutlet  UILabel  * nameLabel ;
@property  ( strong , nonatomic )  IBOutlet  UILabel  * statusLabel ;

@end
