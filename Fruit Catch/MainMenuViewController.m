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

@end

@implementation MainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView *fundo = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Agrupar-1.png"]];
    fundo.center = self.view.center;
    [self.view insertSubview:fundo atIndex:0];
    UIImageView *nome = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"logo"]];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"Launch"] == YES){
        nome.center = CGPointMake(self.view.center.x, self.view.center.y-400);
        [UIView animateWithDuration:2
                              delay:0.75
             usingSpringWithDamping:0.35
              initialSpringVelocity:0
                            options:0
                         animations:^{
                            nome.center = CGPointMake(self.view.center.x, self.view.center.y-200);
                         }
                         completion:nil];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Launch"];
    }else{
        nome.center = CGPointMake(self.view.center.x, self.view.center.y-200);
    }
    [self.view insertSubview:nome atIndex:1];
    
//    UIImageView *fundo1 = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"fundo1"]];
//    fundo1.center = self.view.center;
//    [self.view insertSubview:fundo1 atIndex:0];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)singlePlayer:(id)sender
{
    
    _singlePlayerButton.enabled = NO;
    [self performSegueWithIdentifier:@"Single" sender:self];
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
