//
//  MainMenuViewController.m
//  Fruit Catch
//
//  Created by Júlio Menezes Noronha on 28/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import "MainMenuViewController.h"
#import "SettingsSingleton.h"

#define ON 1
#define OFF 0

@interface MainMenuViewController ()

@property (nonatomic) IBOutlet UIButton *musicBtn;
@property (nonatomic) IBOutlet UIButton *soundBtn;
@property (nonatomic) IBOutlet UIButton *singlePlayerBtn;
@property (nonatomic) IBOutlet UIButton *multiplayerBtn;
@property (nonatomic) IBOutlet UIButton *settingsBtn;
@property (nonatomic) IBOutlet UIImageView *nome;
@property (nonatomic) BOOL option;

@end

@implementation MainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView *fundo = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Agrupar-1.png"]];
    fundo.center = self.view.center;
    [self.view insertSubview:fundo atIndex:0];
    self.nome = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"logo"]];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"Launch"] == YES){
        self.nome.center = CGPointMake(self.view.center.x, self.view.center.y-400);
        [UIView animateWithDuration:2
                              delay:0.75
             usingSpringWithDamping:0.35
              initialSpringVelocity:0
                            options:0
                         animations:^{
                            self.nome.center = CGPointMake(self.view.center.x, self.view.center.y-200);
                         }
                         completion:nil];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Launch"];
    }else{
        self.nome.center = CGPointMake(self.view.center.x, self.view.center.y-200);
    }
    
    [self.view insertSubview:self.nome atIndex:1];
}

-(void)viewWillAppear:(BOOL)animated
{
    //Some com os botões de musica e sons
    self.soundBtn.enabled = NO;
    self.soundBtn.alpha   = 0;
    
    self.musicBtn.enabled = NO;
    self.musicBtn.alpha   = 0;
    
    self.option = NO;
    //Anima os botões single, multiplayer e options
    [UIView animateWithDuration:1
                          delay:0
                        options:UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut | UIViewKeyframeAnimationOptionAllowUserInteraction
                     animations:^{
                         NSLog(@"animate");
                         //Single
                         self.singlePlayerBtn.transform = CGAffineTransformMakeScale(1.02, 1.02);
                         //Multi
                         self.multiplayerBtn.transform  = CGAffineTransformMakeScale(1.02, 1.02);
                         //Options
                         self.settingsBtn.transform     = CGAffineTransformMakeRotation(M_PI_4 / 4);
                     }completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)options:(id)sender
{
    if(!self.option){
        self.musicBtn.enabled = YES;
        self.musicBtn.alpha   = 1;
        
        self.soundBtn.enabled = YES;
        self.soundBtn.alpha   = 1;
        
        //Fazer a animacao dos botoes surgindo
        
        self.option = YES;
    }else{
        self.musicBtn.enabled = NO;
        self.musicBtn.alpha   = 0;
        
        self.soundBtn.enabled = NO;
        self.soundBtn.alpha   = 0;
        
        self.option = NO;
    }
}

-(IBAction)singlePlayer:(id)sender
{
    _singlePlayerButton.enabled = NO;
    [self performSegueWithIdentifier:@"Single" sender:self];
}

-(IBAction)multiplayer:(id)sender
{
    NSLog(@"Multiplayer");
}

-(IBAction)musicON_OFF:(id)sender
{
    [[SettingsSingleton sharedInstance] musicON_OFF];
    [self.view setNeedsDisplay];
}

-(IBAction)soundON_OFF:(id)sender
{
    [[SettingsSingleton sharedInstance] soundON_OFF];

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
