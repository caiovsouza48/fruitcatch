//
//  MainMenuViewController.h
//  Fruit Catch
//
//  Created by Júlio Menezes Noronha on 28/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import <StoreKit/StoreKit.h>
@interface MainMenuViewController : UIViewController <FBLoginViewDelegate,SKProductsRequestDelegate,SKPaymentTransactionObserver>

@property (weak, nonatomic) IBOutlet UIButton *singlePlayerButton;
@property (nonatomic) IBOutlet FBLoginView *loginView;
@property (weak, nonatomic) IBOutlet UIImageView *facebookImage;

@property  ( strong , nonatomic )  IBOutlet  FBProfilePictureView  * profilePictureView ;
@property  ( strong , nonatomic )  IBOutlet  UILabel  * nameLabel ;
@property  ( strong , nonatomic )  IBOutlet  UILabel  * statusLabel ;

@property (nonatomic) NSString* userName;
@property (nonatomic) NSString* userImageURL;
@property (nonatomic) UIImage* imageFacebook;

- (void)loadFromFile;

@end
