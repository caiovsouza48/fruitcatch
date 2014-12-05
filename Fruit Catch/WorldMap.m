//
//  WorldMap.m
//  Fruit Catch
//
//  Created by Júlio Menezes Noronha on 03/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import "WorldMap.h"
#import "GameViewController.h"

@interface WorldMap ()

@property NSInteger i;

@end

@implementation WorldMap

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSArray *mapButtons = [[NSArray alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MapButtons" ofType:@"plist"]];
    
    _i = -1;
    
    //Cria o botao back
    CGRect frame = [[UIScreen mainScreen] bounds];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    button.tag = _i;
    
    [button addTarget:self
               action:@selector(selectLevel:)
     forControlEvents:UIControlEventTouchUpInside];
    
    [button setTitle:[NSString stringWithFormat:@"Back"] forState:UIControlStateNormal];
    button.frame = CGRectMake(frame.size.width / 2 - 30, 4 * frame.size.height / 5, 60, 32);
    [self.view addSubview:button];
    
    for(NSDictionary *button in mapButtons){
        
        _i++;
        //Cria o botao de nivel
        NSNumber *x = button[@"xPosition"];
        NSNumber *y = button[@"yPosition"];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        
        button.tag = _i;
        
        [button addTarget:self
                   action:@selector(selectLevel:)
         forControlEvents:UIControlEventTouchUpInside];
        
        [button setTitle:[NSString stringWithFormat:@"%d",(int)_i + 1] forState:UIControlStateNormal];
        button.frame = CGRectMake(x.integerValue, y.integerValue, 32, 32);
        [self.view addSubview:button];
    }
    
}

-(IBAction)selectLevel:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    _i = btn.tag;
    
    if(_i > -1){
        [self performSegueWithIdentifier:@"Level" sender:self];
    }else{
        [self performSegueWithIdentifier:@"Menu" sender:self];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"Level"]){
        //Preparar a classe que carrega o nível para carregar o nível _i
        GameViewController *view = [segue destinationViewController];
        view.levelString = [NSString stringWithFormat:@"Level_%d",(int)_i];
        
    }
    
}

@end
