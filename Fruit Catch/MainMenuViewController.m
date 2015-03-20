//
//  MainMenuViewController.m
//  Fruit Catch
//
//  Created by Júlio Menezes Noronha on 28/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import "MainMenuViewController.h"
#import "SettingsSingleton.h"
#import "AppUtils.h"
#import "RNEncryptor.h"
#import "NetworkController.h"
#import <Nextpeer/Nextpeer.h>
#import "RNDecryptor.h"
#import "JIMCAPHelper.h"
#import "WorldMap.h"
#import <QuartzCore/QuartzCore.h>

#define USER_SECRET @"0x444F@c3b0ok"
#define ON 1
#define OFF 0

@interface MainMenuViewController (){
    UIView *connectingView;
    NSArray *_products;
}

@property (nonatomic) IBOutlet UIImageView *kasco;
@property (nonatomic) IBOutlet UIImageView *fundoConfig;
@property (nonatomic) IBOutlet UIButton *singlePlayerBtn;
@property (nonatomic) IBOutlet UIButton *multiplayerBtn;
@property (nonatomic) IBOutlet UIButton *settingsBtn;
@property (nonatomic) IBOutlet UIButton *fechar;
@property (nonatomic) IBOutlet UIImageView *nome;
@property (nonatomic) UIView *configuracao;
@property (nonatomic) UIView *blurView;
@property (nonatomic) BOOL option;
@property(nonatomic) NSArray *fbFriends;
@property(nonatomic) BOOL flag;

//Menu rápido
@property (nonatomic) IBOutlet UIButton *menuRapido;
@property (nonatomic) IBOutlet UIImageView *fundoMenuRapido;
@property (nonatomic) BOOL quickMenuOpen;
@property (nonatomic) IBOutlet UIImageView *blockMusic;
@property (nonatomic) IBOutlet UIImageView *blockSFX;
@property (nonatomic) IBOutlet UIButton *ligaMusica;
@property (nonatomic) IBOutlet UIButton *ligaSFX;
@property (nonatomic) IBOutlet UIButton *ajuda;

@end

@implementation MainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _flag = false;
    
    self.loginView.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    
//    [self addEngineLeft];
    
    [self adicionaMenuRapido];
    [self adicionaElementos];
    [self loadFromFile];
    [self viewConfig];
}

-(void)adicionaElementos
{
    UIImageView *fundo = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"fundo_main_menu.png"]];
    fundo.contentMode = UIViewContentModeScaleAspectFill;
    fundo.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    fundo.center = self.view.center;
    
    CGFloat buttonSize = 0.45 * self.view.frame.size.width;
    _singlePlayerBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.center.x, CGRectGetMaxY(self.view.frame) - 180, buttonSize, buttonSize/3.5)];
    _singlePlayerBtn.backgroundColor = [UIColor colorWithRed:80.0/255 green:141.0/255 blue:194.0/255 alpha:1];
    _singlePlayerBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    _singlePlayerBtn.layer.borderWidth = 2.0;
    _singlePlayerBtn.layer.cornerRadius = 12.0;
    _singlePlayerBtn.titleLabel.textColor = [UIColor whiteColor];
    _singlePlayerBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    _singlePlayerBtn.reversesTitleShadowWhenHighlighted = YES;
    [_singlePlayerBtn setTitle:@"Single Player" forState:UIControlStateNormal];
    [_singlePlayerBtn.titleLabel setFont:[UIFont fontWithName:@"Chewy" size:23]];
    [_singlePlayerBtn addTarget:self action:@selector(singlePlayer:) forControlEvents:UIControlEventTouchUpInside];
    
    _multiplayerBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.center.x, CGRectGetMaxY(self.view.frame) - 120, buttonSize, buttonSize/3.5)];
    _multiplayerBtn.backgroundColor = [UIColor colorWithRed:80.0/255 green:141.0/255 blue:194.0/255 alpha:1];
    _multiplayerBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    _multiplayerBtn.layer.borderWidth = 2.0;
    _multiplayerBtn.layer.cornerRadius = 12.0;
    _multiplayerBtn.titleLabel.textColor = [UIColor whiteColor];
    _multiplayerBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    _multiplayerBtn.reversesTitleShadowWhenHighlighted = YES;
    [_multiplayerBtn setTitle:@"Multiplayer" forState:UIControlStateNormal];
    [_multiplayerBtn.titleLabel setFont:[UIFont fontWithName:@"Chewy" size:23]];
    [_multiplayerBtn addTarget:self action:@selector(multiplayer:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view insertSubview:_singlePlayerBtn atIndex:1];
    [self.view insertSubview:_multiplayerBtn atIndex:2];
    
    [self.view insertSubview:fundo atIndex:0];
    
    self.nome = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"logo"]];
    _nome.contentMode = UIViewContentModeScaleAspectFill;
    _nome.frame = CGRectMake(0, 0, self.view.frame.size.width / 2.5, self.view.frame.size.width / 2.5);
    
    _kasco = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Fazendeiro_Severino"]];
    _kasco.contentMode = UIViewContentModeScaleAspectFill;
    _kasco.frame = CGRectMake(-5, CGRectGetMaxY(self.view.frame) / 2, CGRectGetMidX(self.view.frame) * 1.5, CGRectGetMidX(self.view.frame) * 1.5);
    [self.view insertSubview:_kasco atIndex:1];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"Launch"] == YES){
        self.nome.center = CGPointMake(self.view.center.x, -100);
        [UIView animateWithDuration:2
                              delay:0.75
             usingSpringWithDamping:0.35
              initialSpringVelocity:0
                            options:0
                         animations:^{
                             self.nome.center = CGPointMake(self.view.center.x, self.view.center.y / 3);
                         }
                         completion:nil];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"Launch"];
    }else{
        self.nome.center = CGPointMake(self.view.center.x, self.view.center.y-200);
    }
    
    [self.view addSubview:self.nome];
}

//-(void)addEngineLeft{
//    // Botão de configuração do mini menu
//    self.engineButtonLeft = [[UIButton alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height, 50, -50)];
//    [self.engineButtonLeft setImage:[UIImage imageNamed:@"configuracoes"] forState:UIControlStateNormal];
//    CGAffineTransform rotate = CGAffineTransformMakeRotation(0);
//    self.engineButtonLeft.transform = rotate;
//    [self.engineButtonLeft addTarget:self action:@selector(openMenu:) forControlEvents:UIControlEventTouchUpInside];
//    
//    // View animada do botão
//    self.engineViewLeft = [[UIView alloc]initWithFrame:CGRectMake(-50, self.view.frame.size.height - 50, 100, 100)];
//    [self.engineViewLeft setBackgroundColor:[UIColor redColor]];
//    self.engineViewLeft.layer.anchorPoint = CGPointMake(1, 1);
//    self.engineViewLeft.transform = rotate;
//    
//    // Adiciona na view o botão e a view animada
//    [self.view addSubview:self.engineViewLeft];
//    [self.view addSubview:self.engineButtonLeft];
//    
//    // Adiciona os botões dentro da view animada
//    [self addButton1OnEngineView];
//}

-(void)addButton1OnEngineView{
    UIButton *button1 = [[UIButton alloc]initWithFrame:CGRectMake(10, 10, 40, 40)];
    [button1 setImage:[UIImage imageNamed:@"configuracoes"] forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(options:) forControlEvents:UIControlEventTouchUpInside];
    [self.engineViewLeft addSubview:button1];
}

-(void)viewConfig
{
    self.configuracao = [[UIView alloc]initWithFrame:(CGRectMake(self.view.center.x - 150, -410, 300, 404))];
    
    //Fundo
    _fundoConfig = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"retangulo_configuracoes"]];
    _fundoConfig.contentMode = UIViewContentModeScaleAspectFill;
    
    [self.configuracao addSubview:_fundoConfig];
    
    //Texto configuracao
    UILabel *configuracao = [[UILabel alloc]initWithFrame:CGRectMake(10, 10, 290, 50)];
    configuracao.font = [UIFont fontWithName:@"Chewy" size:40];
    configuracao.text = @"Settings";
    configuracao.textAlignment = NSTextAlignmentCenter;
    configuracao.textColor = [UIColor whiteColor];

    
    //Botao fechar
    _fechar = [[UIButton alloc]initWithFrame:CGRectMake(self.configuracao.frame.origin.x + 282, self.configuracao.frame.origin.y - 30, 35, 35)];
    [_fechar setBackgroundImage:[UIImage imageNamed:@"fechar"] forState:UIControlStateNormal];
    [_fechar addTarget:self action:@selector(fechar:)forControlEvents:UIControlEventTouchUpInside];
    
    //Botao restore purchase
    UIButton *restore = [[UIButton alloc] initWithFrame:CGRectMake(30, 80, 250, 50)];
//    restore.backgroundColor = [UIColor colorWithRed:69.0/255.0 green:88.0/255.0 blue:151.0/255.0 alpha:1.0];
    restore.backgroundColor = [UIColor grayColor]; // REMOVER
    restore.enabled = NO; //REMOVER
    restore.layer.borderColor = [UIColor whiteColor].CGColor;
    restore.layer.borderWidth = 2.0;
    restore.layer.cornerRadius = 12.0;
    restore.titleLabel.textColor = [UIColor whiteColor];
    restore.titleLabel.textAlignment = NSTextAlignmentCenter;
    restore.reversesTitleShadowWhenHighlighted = YES;
    [restore setTitle:@"Restore purchases" forState:UIControlStateNormal];
    [restore.titleLabel setFont:[UIFont fontWithName:@"Chewy" size:20]];
    [self.configuracao addSubview:restore];
    
    //Botao termos
    UIButton *termos = [[UIButton alloc]initWithFrame:CGRectMake(30, restore.frame.origin.y + 80, 250, 50)];
//    termos.backgroundColor = [UIColor colorWithRed:69.0/255.0 green:88.0/255.0 blue:151.0/255.0 alpha:1.0];
    termos.backgroundColor = [UIColor grayColor]; // REMOVER
    termos.enabled = NO; //REMOVER
    termos.layer.borderColor = [UIColor whiteColor].CGColor;
    termos.layer.borderWidth = 2.0;
    termos.layer.cornerRadius = 12.0;
    termos.titleLabel.textColor = [UIColor whiteColor];
    termos.titleLabel.textAlignment = NSTextAlignmentCenter;
    termos.reversesTitleShadowWhenHighlighted = YES;
    [termos setTitle:@"Terms of service" forState:UIControlStateNormal];
    [termos.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [termos.titleLabel setFont:[UIFont fontWithName:@"Chewy" size:20]];
    [self.configuracao addSubview:termos];
    
    //Botao creditos
    UIButton *creditos = [[UIButton alloc]initWithFrame:CGRectMake(30, termos.frame.origin.y + 80, 250, 50)];
    creditos.backgroundColor = [UIColor colorWithRed:69.0/255.0 green:88.0/255.0 blue:151.0/255.0 alpha:1.0];
    creditos.layer.borderColor = [UIColor whiteColor].CGColor;
    creditos.layer.borderWidth = 2.0;
    creditos.layer.cornerRadius = 12.0;
    creditos.titleLabel.textColor = [UIColor whiteColor];
    creditos.titleLabel.textAlignment = NSTextAlignmentCenter;
    creditos.reversesTitleShadowWhenHighlighted = YES;
    [creditos setTitle:@"Credits" forState:UIControlStateNormal];
    [creditos.titleLabel setFont:[UIFont fontWithName:@"Chewy" size:20]];
    [self.configuracao addSubview:creditos];
    
    //Botao facebook
    CGFloat buttonSize = 0.45 * self.view.frame.size.width;
    _loginView = [[FBLoginView alloc]initWithFrame:CGRectMake(30, creditos.frame.origin.y + 80, 250, buttonSize/4)];
    _loginView.delegate = self;
    _loginView.layer.borderColor = [UIColor whiteColor].CGColor;
    _loginView.layer.borderWidth = 2.0;
    _loginView.layer.cornerRadius = 12.0;
    
    [self.configuracao addSubview:_loginView];
    [self.configuracao addSubview:configuracao];
    [self.view insertSubview:_fechar belowSubview:_configuracao];
//    [self.configuracao addSubview:fechar];
    
    [self.view addSubview:_configuracao];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    if (![SettingsSingleton sharedInstance].music) {
        //adicionar ícone de proibido
        [_ligaMusica setBackgroundImage:[UIImage imageNamed:@"no_music"] forState:UIControlStateNormal];
        _ligaMusica.frame = CGRectMake(_ligaMusica.center.x - 19.5, _ligaMusica.center.y - 21.5, 39, 43);
    }else{
        //remove ícone de proibido
        [_ligaMusica setBackgroundImage:[UIImage imageNamed:@"icon_music"] forState:UIControlStateNormal];
        _ligaMusica.frame = CGRectMake(65, 65, 24, 36);
    }
    
    if (![SettingsSingleton sharedInstance].SFX) {
        //adicionar ícone de proibido
        [_ligaSFX setBackgroundImage:[UIImage imageNamed:@"no_sfx"] forState:UIControlStateNormal];
        _ligaSFX.frame = CGRectMake(_ligaSFX.center.x - 19.5, _ligaSFX.center.y - 21.5, 39, 43);
    }else{
        //remove ícone de proibido
        [_ligaSFX setBackgroundImage:[UIImage imageNamed:@"icon_som"] forState:UIControlStateNormal];
        _ligaSFX.frame = CGRectMake(15, 40, 20, 32);
    }
    
    self.option = NO;
    self.quickMenuOpen = NO;
    //Anima os botões single, multiplayer e options
    [UIView animateWithDuration:1
                          delay:0
                        options:UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut | UIViewKeyframeAnimationOptionAllowUserInteraction
                     animations:^{
                         
                         //Single
                         self.singlePlayerBtn.transform = CGAffineTransformMakeScale(1.02, 1.02);
                         //Multi
                         self.multiplayerBtn.transform  = CGAffineTransformMakeScale(1.02, 1.02);
                         //Options
//                         self.settingsBtn.transform     = CGAffineTransformMakeRotation(M_PI_4 / 4);
                     }completion:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:JIMCHelperProductPurchasedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:JIMCHelperProductPurchasedNotification object:nil];
}

- (void)dealloc{
     [[NSNotificationCenter defaultCenter] removeObserver:self name:JIMCHelperProductPurchasedNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)fechar:(id)sender
{
    [UIView animateWithDuration:1.5
                          delay:0
         usingSpringWithDamping:0.65
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         self.nome.alpha = 1;
                         self.blurView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
                         self.configuracao.center = CGPointMake(self.configuracao.center.x, -410);
                         _fechar.center = CGPointMake(self.configuracao.frame.origin.x + 282, self.configuracao.frame.origin.y - 30);
                     }completion:^(BOOL fisished){
                         self.option = NO;
                         [self.blurView removeFromSuperview];
                     }];
    
}
-(IBAction)options:(id)sender
{
    if(!self.option){
        self.blurView = [[UIView alloc] initWithFrame:self.view.frame];
        self.blurView.backgroundColor = [UIColor clearColor];
        [self.view insertSubview:self.blurView belowSubview:self.fechar];
        
        [UIView animateWithDuration:1.25
                              delay:0
             usingSpringWithDamping:0.65
              initialSpringVelocity:0
                            options:0
                         animations:^{
                             self.nome.alpha = 0.15;
                             self.blurView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.85];
                             self.configuracao.center = CGPointMake(self.view.center.x, self.view.center.y);
                             _fechar.center = CGPointMake(self.configuracao.frame.origin.x + 282, self.configuracao.frame.origin.y - 30);
                         }completion:^(BOOL fisished){
                             self.option = YES;
                         }];
    }
    
}

-(IBAction)singlePlayer:(id)sender
{
    _singlePlayerButton.enabled = NO;
    [self performSegueWithIdentifier:@"Single" sender:self];
}

-(IBAction)multiplayer:(id)sender
{
    [Nextpeer launchDashboard];
    /*
     connectingView = [[UIView alloc]initWithFrame:self.view.frame];
     NSLog(@"Multiplayer");
    [[NetworkController sharedInstance] authenticateLocalUser];
    [[NetworkController sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 viewController:self];
     */
    
}

-(IBAction)help:(id)sender
{
    NSLog(@"ajuda");
}

-(IBAction)musicON_OFF:(id)sender
{
    [[SettingsSingleton sharedInstance] musicON_OFF];
    if (![SettingsSingleton sharedInstance].music) {
        //adicionar ícone de proibido
        [_ligaMusica setBackgroundImage:[UIImage imageNamed:@"no_music"] forState:UIControlStateNormal];
        _ligaMusica.frame = CGRectMake(_ligaMusica.center.x - 19.5, _ligaMusica.center.y - 21.5, 39, 43);
    }else{
        //remove ícone de proibido
        [_ligaMusica setBackgroundImage:[UIImage imageNamed:@"icon_music"] forState:UIControlStateNormal];
        _ligaMusica.frame = CGRectMake(65, 65, 24, 36);
    }
}

-(IBAction)soundON_OFF:(id)sender
{
    [[SettingsSingleton sharedInstance] soundON_OFF];
    if (![SettingsSingleton sharedInstance].SFX) {
        //adicionar ícone de proibido
        [_ligaSFX setBackgroundImage:[UIImage imageNamed:@"no_sfx"] forState:UIControlStateNormal];
        _ligaSFX.frame = CGRectMake(_ligaSFX.center.x - 19.5, _ligaSFX.center.y - 21.5, 39, 43);
    }else{
        //remove ícone de proibido
        [_ligaSFX setBackgroundImage:[UIImage imageNamed:@"icon_som"] forState:UIControlStateNormal];
        _ligaSFX.frame = CGRectMake(15, 40, 20, 32);
    }
}

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    
    NSLog(@"USER = %@", user);
    NSLog(@"%@",[user objectForKey:@"email"]);
    
    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *FBuser, NSError *error) {
        if (!error) {
            // Handle error
            self.userName = [FBuser name];
            self.userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [FBuser objectID]];
            
            NSData* imageData = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:self.userImageURL]];
            self.imageFacebook = [UIImage imageWithData:imageData];
            
            NSLog(@"IMAGEM = %@", self.userImageURL);
            NSLog(@"USERNAME = %@", self.userName);
        }
    }];
    //__block NSArray *friends;
    [FBRequestConnection startWithGraphPath:@"me/friends" parameters:nil HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        self.fbFriends = [result objectForKey:@"data"];
        
        //        for (NSDictionary *dicionario in self.fbFriends) {
        //            NSLog(@"name = %@",[dicionario objectForKey:@"name"]);
        //        }
        self.profilePictureView.profileID = user.objectID;
        self.nameLabel.text = user.name;
        NSLog(@"User ID = %@",user.objectID);
        NSDictionary *userDict = @{@"facebookID" : user.objectID,
                                   @"alias" : user.name,
                                   @"facebookFriends" : [result objectForKey:@"data"]
                                   };
        
        NSString *filePath = [AppUtils getAppDataDir];
        //NSLog(@"%@",self.lives);
        NSData *dataToSave = [NSKeyedArchiver archivedDataWithRootObject:userDict];
        NSError *error2;
        NSData *encryptedData = [RNEncryptor encryptData:dataToSave
                                            withSettings:kRNCryptorAES256Settings
                                                password:USER_SECRET
                                                   error:&error2];
        
        BOOL sucess = [encryptedData writeToFile:filePath atomically:YES];
        if (sucess){
            // Enviar para o servidor
//            if ([self sendDataToWebService:userDict]) {
//                NSLog(@"Envio Data com sucesso !");
//                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"flagFacebook"];
//            }
//            if ([self sendPerformanceToWebService:userDict]) {
//                NSLog(@"Envio Performance com sucesso !");
//            }
        }
        else{
            NSLog(@"Erro ao Salvar arquivo de Usuário");
        }
        [self loadFromFile];
    }];
}

- (BOOL)sendDataToWebService:(NSDictionary*)object {
    
    NSError * erro = nil;
    
    NSString* name = [object[@"alias"] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSString* strUrl = [[NSString alloc]initWithFormat:@"http://fruitcatch-bepidproject.rhcloud.com/web/addUsuario/%@/%@/0/5/5/5/%@", object[@"facebookID"], name, object[@"facebookID"]];
    NSLog(@"%@", strUrl);
    
    NSURL *url = [NSURL URLWithString:strUrl];
    NSData *dados = [[NSData alloc]initWithContentsOfURL:url];
    if (erro == nil && dados != nil) {
        NSDictionary *dadosWebService = [NSJSONSerialization JSONObjectWithData:dados options:NSJSONReadingMutableContainers error:&erro];
        if (erro) {
            NSLog(@"%@", erro.localizedDescription);
            return NO;
        }
        NSLog(@"%@", dadosWebService);
        return YES;
    }
    
    return NO;
}

- (BOOL)sendPerformanceToWebService:(NSDictionary*)object{
    NSError * erro = nil;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    _plistPath = [NSString stringWithFormat:@"%@/highscore.plist",documentsDirectory];
    int i = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastCleared"];;
    
    NSArray *array = [[NSArray alloc]initWithContentsOfFile:_plistPath];
    NSDictionary *dic = [[NSDictionary alloc] initWithDictionary:[array objectAtIndex:i]];
    
    NSInteger score = [dic[@"HighScore"] integerValue];
    NSInteger time = [dic[@"Time"] integerValue];
    
    NSString* strUrl = [[NSString alloc]initWithFormat:@"http://fruitcatch-bepidproject.rhcloud.com/web/addDesempenho/%@/%d/%d/0/%d",object[@"facebookID"], i, time, score];
    NSLog(@"%@", strUrl);
    
    NSURL *url = [NSURL URLWithString:strUrl];
    NSData *dados = [[NSData alloc]initWithContentsOfURL:url];
    if (erro == nil && dados != nil) {
        NSDictionary *dadosWebService = [NSJSONSerialization JSONObjectWithData:dados options:NSJSONReadingMutableContainers error:&erro];
        if (erro) {
            NSLog(@"%@", erro.localizedDescription);
            return NO;
        }
        NSLog(@"%@", dadosWebService);
        return YES;
    }
    return  NO;
}

- (void)loadFromFile{
    NSString *appDataDir = [AppUtils getAppDataDir];
    if ([[NSFileManager defaultManager] fileExistsAtPath:appDataDir]) {
        NSData *data = [NSData dataWithContentsOfFile:appDataDir];
        NSError *error;
        NSData *decryptedData = [RNDecryptor decryptData:data withPassword:USER_SECRET error:&error];
        if (!error){
            NSDictionary *obj = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            NSLog(@"File dict = %@",obj);
        }
    }
    else{
    }
}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    self.statusLabel.text = @"You're logged in as";
}

- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    self.profilePictureView.profileID = nil;
    self.nameLabel.text = @"";
    self.statusLabel.text= @"You're not logged in!";
    //self.imageFaceBook.image = nil;
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    NSString *alertMessage, *alertTitle;
    
    // If the user should perform an action outside of you app to recover,
    // the SDK will provide a message for the user, you just need to surface it.
    // This conveniently handles cases like Facebook password change or unverified Facebook accounts.
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        alertTitle = @"Facebook error";
        alertMessage = [FBErrorUtility userMessageForError:error];
        
        // This code will handle session closures that happen outside of the app
        // You can take a look at our error handling guide to know more about it
        // https://developers.facebook.com/docs/ios/errors
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
        
        // If the user has cancelled a login, we will do nothing.
        // You can also choose to show the user a message if cancelling login will result in
        // the user not being able to complete a task they had initiated in your app
        // (like accessing FB-stored information or posting to Facebook)
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
        NSLog(@"user cancelled login");
        
        // For simplicity, this sample handles other errors with a generic message
        // You can checkout our error handling guide for more detailed information
        // https://developers.facebook.com/docs/ios/errors
    } else {
        alertTitle  = @"Something went wrong";
        alertMessage = @"Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}


 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     if([segue.identifier isEqualToString:@"Single"]){
         WorldMap *view = [segue destinationViewController];
         view.flagFacebook = [[NSUserDefaults standardUserDefaults] boolForKey:@"flagFacebook"];
         view.nextStage = -1;
     }
 }

-(void)adicionaMenuRapido
{
    CGFloat buttonSize = 28.0;
    _menuRapido = [[UIButton alloc] initWithFrame:CGRectMake(3, CGRectGetMaxY(self.view.frame) - buttonSize -3, buttonSize, buttonSize)];
    _menuRapido.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"icon_open"]];
    [_menuRapido addTarget:self action:@selector(menuRapido:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:_menuRapido aboveSubview:self.view];
    
    CGFloat imageSize = 62.0;
    _fundoMenuRapido = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Menu_Rapido_Pequeno"]];
    _fundoMenuRapido.frame = CGRectMake(0, CGRectGetMaxY(self.view.frame) - imageSize, imageSize, imageSize);
    [self.view insertSubview:_fundoMenuRapido belowSubview:_menuRapido];
    
    _ligaSFX = [[UIButton alloc]initWithFrame:CGRectMake(15, 40, 20, 32)];
    [_ligaSFX setBackgroundImage:[UIImage imageNamed:@"icon_som"] forState:UIControlStateNormal];
    [_ligaSFX addTarget:self action:@selector(soundON_OFF:) forControlEvents:UIControlEventTouchUpInside];
    
    _ligaMusica = [[UIButton alloc] initWithFrame:CGRectMake(65, 65, 24, 36)];
    [_ligaMusica setBackgroundImage:[UIImage imageNamed:@"icon_music"] forState:UIControlStateNormal];
    [_ligaMusica addTarget:self action:@selector(musicON_OFF:) forControlEvents:UIControlEventTouchUpInside];
    
    _ajuda = [[UIButton alloc]initWithFrame:CGRectMake(110, 105, 25, 40)];
    [_ajuda setBackgroundImage:[UIImage imageNamed:@"icon_help"] forState:UIControlStateNormal];
    [_ajuda addTarget:self action:@selector(help:) forControlEvents:UIControlEventTouchUpInside];
    
    _settingsBtn = [[UIButton alloc]initWithFrame:CGRectMake(130, 155, 30, 33)];
    [_settingsBtn setBackgroundImage:[UIImage imageNamed:@"icon_config"] forState:UIControlStateNormal];
    [_settingsBtn addTarget:self action:@selector(options:) forControlEvents:UIControlEventTouchUpInside];
    
    _ligaMusica.alpha = 0;
    _ligaSFX.alpha = 0;
    _ajuda.alpha = 0;
    _settingsBtn.alpha = 0;
    
    [self.fundoMenuRapido addSubview:_ligaMusica];
    [self.fundoMenuRapido addSubview:_ligaSFX];
    [self.fundoMenuRapido addSubview:_ajuda];
    [self.fundoMenuRapido addSubview:_settingsBtn];
    
    self.fundoMenuRapido.userInteractionEnabled = YES;
}

-(IBAction)menuRapido:(id)sender
{
    if(!_quickMenuOpen){
        //Abrindo o menu
        _quickMenuOpen = YES;
        //Altera o fundo da cesta
        _fundoMenuRapido.image = [UIImage imageNamed:@"Menu_Rapido_Cesta"];
        //Altera o botão
        _menuRapido.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"icon_close"]];
        
        //Anima a porra toda
        [UIView animateWithDuration:0.5
                              delay:0
             usingSpringWithDamping:0.35
              initialSpringVelocity:0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             CGFloat imageSize = 203.0;
                             CGFloat buttonSize = 27.0;
                             
                             _menuRapido.frame = CGRectMake(3, CGRectGetMaxY(self.view.frame) - buttonSize - 3, buttonSize, buttonSize);
                             _fundoMenuRapido.frame = CGRectMake(0, CGRectGetMaxY(self.view.frame) - imageSize, imageSize, imageSize);
                             _ligaMusica.alpha = 1;
                             _ligaSFX.alpha = 1;
                             _ajuda.alpha = 1;
                             _settingsBtn.alpha = 1;
                         }
                         completion:nil];
    }else{
        //Fechando o menu
        _quickMenuOpen = NO;
        //Altera o fundo da cesta
        _fundoMenuRapido.image = [UIImage imageNamed:@"Menu_Rapido_Pequeno"];
        //Altera o botão
        _menuRapido.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"icon_open"]];
        //Anima a porra toda
        [UIView animateWithDuration:0.5
                              delay:0
             usingSpringWithDamping:0.35
              initialSpringVelocity:0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             CGFloat imageSize = 62.0;
                             CGFloat buttonSize = 28.0;
                             
                             _menuRapido.frame = CGRectMake(3, CGRectGetMaxY(self.view.frame) - buttonSize - 3, buttonSize, buttonSize);
                             _fundoMenuRapido.frame = CGRectMake(0, CGRectGetMaxY(self.view.frame) - imageSize, imageSize, imageSize);
                             _ligaMusica.alpha = 0;
                             _ligaSFX.alpha = 0;
                             _ajuda.alpha = 0;
                             _settingsBtn.alpha = 0;
                         }
                         completion:nil];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    
    if(_quickMenuOpen){
        if(!CGRectContainsPoint(_fundoMenuRapido.frame, location)){
            [self menuRapido:self];
        }
    }
}

//-(void)addEngineLeft{
//    
//    // Botão de configuração do mini menu
//    self.engineButtonLeft = [[UIButton alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height, 50, -50)];
//    [self.engineButtonLeft setImage:[UIImage imageNamed:@"configuracoes"] forState:UIControlStateNormal];
//    CGAffineTransform rotate = CGAffineTransformMakeRotation(0);
//    self.engineButtonLeft.transform = rotate;
//    [self.engineButtonLeft addTarget:self action:@selector(openMenu:) forControlEvents:UIControlEventTouchUpInside];
//    
//    // View animada do botão
//    self.engineViewLeft = [[UIView alloc]initWithFrame:CGRectMake(-50, self.view.frame.size.height - 50, 100, 100)];
//    [self.engineViewLeft setBackgroundColor:[UIColor redColor]];
//    self.engineViewLeft.layer.anchorPoint = CGPointMake(1, 1);
//    self.engineViewLeft.transform = rotate;
//    
//    // Adiciona na view o botão e a view animada
//    [self.view addSubview:self.engineViewLeft];
//    [self.view addSubview:self.engineButtonLeft];
//}
//
//- (IBAction)openMenu:(id)sender{
//    
//    if (!_flag) {
//        [UIButton animateWithDuration:1.0
//                                delay:0.0
//                              options:UIViewAnimationOptionCurveEaseInOut
//                           animations:^{
//                               self.engineButtonLeft.transform = CGAffineTransformMakeRotation(M_PI_2);
//                               self.engineViewLeft.transform = CGAffineTransformMakeRotation(M_PI_2);
//                           } completion:nil];
//        _flag = true;
//    }else{
//        [UIButton animateWithDuration:1.0
//                                delay:0.0
//                              options:UIViewAnimationOptionCurveEaseInOut
//                           animations:^{
//                               self.engineButtonLeft.transform = CGAffineTransformMakeRotation(0);
//                               self.engineViewLeft.transform = CGAffineTransformMakeRotation(0);
//                           } completion:nil];
//        _flag = false;
//    }
//}
@end
