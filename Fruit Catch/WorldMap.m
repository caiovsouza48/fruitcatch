//
//  WorldMap.m
//  Fruit Catch
//
//  Created by Júlio Menezes Noronha on 03/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import "WorldMap.h"
#import "GameViewController.h"
#import "RNCryptor.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "Life.h"
#import "CustomSegueWorldMap.h"
#import "RNDecryptor.h"
#import "AppUtils.h"
#import "ClearedLevelsSingleton.h"
#import "JIMCAPHelper.h"
#import "SettingsSingleton.h"
#import <AdColony/AdColony.h>

#define USER_SECRET @"0x444F@c3b0ok"
#define IPHONE6 (self.view.frame.size.width == 375)
#define IPHONE6PLUS (self.view.frame.size.width == 414)

#define IPHONE6_XSCALE 1.171875
#define IPHONE6_YSCALE 1.174285774647887
#define IPHONE6PLUS_XSCALE 1.29375
#define IPHONE6PLUS_YSCALE 1.295774647887324

@interface WorldMap (){
    NSArray *_products;
}

@property NSInteger i;

@property (nonatomic) UIView *informFase;
@property (nonatomic) NSTimer *lifeTimer;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) IBOutlet UIButton *btn;
@property (nonatomic) IBOutlet UIButton *btnJogar;
@property (nonatomic) IBOutlet UILabel  *lblFase;
@property (nonatomic) IBOutlet UILabel  *lblTarget;
@property (nonatomic) IBOutlet UILabel  *lblMoves;
@property (nonatomic) IBOutlet UIImageView *star1;
@property (nonatomic) IBOutlet UIImageView *star2;
@property (nonatomic) IBOutlet UIImageView *star3;

@property int offset;
@property (nonatomic) UIScrollView *shopScrollView;
@property BOOL shopOpen;
@property (nonatomic) IBOutlet UIButton *shopi;
@property (nonatomic) NSString *plistPath;

@property (nonatomic) UIView *blurView;

//Menu rápido
@property (nonatomic) IBOutlet UIImageView *fundoMenuRapido;
@property (nonatomic) IBOutlet UIImageView *blockMusic;
@property (nonatomic) IBOutlet UIImageView *blockSFX;
@property (nonatomic) IBOutlet UIButton *menuRapido;
@property (nonatomic) IBOutlet UIButton *ligaMusica;
@property (nonatomic) IBOutlet UIButton *btnSair;
@property (nonatomic) IBOutlet UIButton *ligaSFX;
@property (nonatomic) IBOutlet UIButton *ajuda;
@property (nonatomic) BOOL quickMenuOpen;

@end

@implementation WorldMap


- (void)viewDidLoad {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    _plistPath = [NSString stringWithFormat:@"%@/highscore.plist",documentsDirectory];
    _shopOpen = NO;
    _quickMenuOpen = NO;
    
    if(IPHONE6){
        _offset = 80 * IPHONE6_YSCALE;
    }else if(IPHONE6PLUS){
        _offset = 80 * IPHONE6PLUS_YSCALE;
    }else{
        _offset = 80;
    }
    
    [super viewDidLoad];
    //[self getUserLives];
    [self registerLivesBackgroundNotification];
    [self registerAppEnterForegroundNotification];
    [self registerAdNotification];
    //NSNotification *notification = [NSNotificationCenter defaultCenter]

    [self adicionaFundo];
    [self adicionaInformFase];
//    [self adicionaImagemSuperior];
    [self addScrollFacebook];
    [self allocAnimationSpinning];
    if (self.flagFacebook)
        [self addPeopleOnScrollFacebook];
    [self adicionaVidas];
    [self adicionaMoedas];
//    [self adicionaAjuda];
//    [self adicionaBotaoBack];
    [self adicionaBotoesFases];
    [self adicionaBotaoSair];
    [self adicionaBotaoJogar];
    [self adicionaDetalhesDaFase];
    [self adicionaShop];
    [self allocScrollViewFacebook];
    [self adicionaMenuRapido];
    
}

- (void)registerAdNotification{
    
    [[NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(updateTimeByAd:) name:@"updateLiveByAd" object:nil];
}

- (void)updateTimeByAd:(NSNotification *)notification{
    NSDictionary *userInfo = notification.userInfo;
    int amount = [userInfo[@"amount"] intValue];
    NSTimeInterval currentInterval = [self.lifeTimer timeInterval];
    NSTimeInterval newTimeInterval = currentInterval - amount;
    NSLog(@"New time Interval = %f",newTimeInterval);
    int intervalInMinutes=0;
    if (newTimeInterval < 0){
        
        switch ([Life sharedInstance].lifeCount) {
            case 0:
                intervalInMinutes = 10;
                break;
            case 1:
                intervalInMinutes = 20;
                break;
            case 2:
                intervalInMinutes = 25;
                break;
            case 3:
                intervalInMinutes = 30;
                break;
            case 4:
                intervalInMinutes = 35;
                break;
            case 5:
            default:
                return;
        }

        newTimeInterval = intervalInMinutes - abs(newTimeInterval);
    }
    [self.lifeTimer invalidate];
    self.lifeTimer = [NSTimer scheduledTimerWithTimeInterval:newTimeInterval * 60 target:self selector:@selector(uploadLivesByTimer:) userInfo:nil repeats:NO];
    
    
    
}

//Metodos add apenas para tirar o warning
-(void)stopSpinning{};
-(void)startSpinning{};

- (void)viewWillAppear:(BOOL)animated{
    
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
    
    [super viewWillAppear:animated];
    [self getUserLives];
    
    //Move a scrollView para o fundo da imagem.
    CGRect mask = CGRectMake(0, _scrollView.contentSize.height - self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    [_scrollView scrollRectToVisible:mask animated:NO];
    
    if(_nextStage > -1){
        [self forceSelect];
    }
    
    // Começa o loading
    [self startSpinningShop];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
     [[NSNotificationCenter defaultCenter ] removeObserver:self name:@"updateLiveByAd" object:nil];
    [self.lifeTimer invalidate];
}

#pragma mark - Documents
- (NSString *)getDocsDir {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
    
}

- (NSString *)getAppDataDir {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"appData"];
    
}


#pragma mark - Lives

- (void)registerAppEnterForegroundNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doLifeUpdate) name:UIApplicationWillEnterForegroundNotification object:nil];
    
}

- (void)registerLivesBackgroundNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveLives) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
}

- (void)doLifeUpdate{
    [self.lifeTimer invalidate];
    [self updateLivesLoadedLifeObject];
    
}

- (NSDictionary *)loadFacebookFriendsIDs{
    NSString *appDataDir = [AppUtils getAppDataDir];
    if ([[NSFileManager defaultManager] fileExistsAtPath:appDataDir]) {
        NSData *data = [NSData dataWithContentsOfFile:appDataDir];
        NSError *error;
        NSData *decryptedData = [RNDecryptor decryptData:data withPassword:USER_SECRET error:&error];
        if (!error){
            NSDictionary *obj = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            NSLog(@"File dict = %@",obj);
            return obj;
            //            NSMutableArray *arrayIds = [NSMutableArray array];
            //            for (NSDictionary* friends in [obj objectForKey:@"facebookFriends"]) {
            //                [arrayIds addObject:[friends objectForKey:@"id"]];
            //            }
            //            return [arrayIds copy];
        }
    }
    return nil;
}

- (NSDictionary *)loadFacebookUserID{
    NSString *appDataDir = [AppUtils getAppDataDir];
    if ([[NSFileManager defaultManager] fileExistsAtPath:appDataDir]) {
        NSData *data = [NSData dataWithContentsOfFile:appDataDir];
        NSError *error;
        NSData *decryptedData = [RNDecryptor decryptData:data withPassword:USER_SECRET error:&error];
        if (!error){
            NSDictionary *obj = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            NSLog(@"File dict = %@",obj);
            
            return obj;
        }
    }
    return nil;
}

- (void)getUserLives{
    //Carregando as Vidas do Arquivo, primeiro se desencripta e logo após seta na memória
    NSString *appDataDir = [self getAppDataDir];
    NSLog(@"appDataDir = %@",appDataDir);
    if ([[NSFileManager defaultManager] fileExistsAtPath:appDataDir]) {
        [[Life sharedInstance] loadFromFile];
    }
    else{
        [Life sharedInstance];
    }
    [self updateLivesLoadedLifeObject];
    
}


- (void) updateLivesLoadedLifeObject{
    NSDate *actualDate = [NSDate date];
    //Quanto tempo se passou desde o ultimo tempo registrado no appData
    NSTimeInterval interval = [actualDate timeIntervalSinceDate:[Life sharedInstance].lifeTime];
    //Segundos para Minutos
    int minutesInterval = interval / 60;
    //Setando na Memoria a quantidade de vidas dependendo de quantos minutos se passou e quantas vidas estava registrada no arquivo
    switch ([Life sharedInstance].lifeCount) {
        case 0:
            if (minutesInterval >= 35){
                [Life sharedInstance].lifeCount = 5;
            }
            else if (minutesInterval >= 30){
                [Life sharedInstance].lifeCount = 4;
            }
            else if (minutesInterval >= 25){
                [Life sharedInstance].lifeCount = 3;
            }
            else if (minutesInterval >= 20){
                [Life sharedInstance].lifeCount = 2;
            }
            else if (minutesInterval >= 10){
                [Life sharedInstance].lifeCount = 1;
            }
            break;
        case 1:
            if (minutesInterval >= 35){
                [Life sharedInstance].lifeCount = 5;
            }
            else if (minutesInterval >= 30){
                [Life sharedInstance].lifeCount = 4;
            }
            else if (minutesInterval >= 25){
                [Life sharedInstance].lifeCount = 3;
            }
            else if (minutesInterval >= 1){
                [Life sharedInstance].lifeCount = 2;
            }
            break;
        case 2:
            if (minutesInterval >= 35){
                [Life sharedInstance].lifeCount = 5;
            }
            else if (minutesInterval >= 30){
                [Life sharedInstance].lifeCount = 4;
            }
            else if (minutesInterval >= 25){
                [Life sharedInstance].lifeCount = 3;
            }
            break;
        case 3:
            if (minutesInterval >= 35){
                [Life sharedInstance].lifeCount = 5;
            }
            else if (minutesInterval >= 30){
                [Life sharedInstance].lifeCount = 4;
            }
            break;
        case 4:
            if (minutesInterval >= 35){
                [Life sharedInstance].lifeCount = 5;
            }
            break;
        case 5:
            [Life sharedInstance].lifeCount = 5;
        default:
            break;
    }
    [self updateLivesView];
    [self startLivesTimer];
}

- (void)saveLives{
    [[Life sharedInstance] saveToFile];
}

- (void) updateLivesView{
    for (id obj in self.livesView.subviews) {
        if ([obj isKindOfClass:[UIImageView class]]){
            UIImageView *imageView = (UIImageView *)obj;
            /* as Tags das Vidas começam de 10 até 15,então se for maior que 10 significa que é
             uma UIImageView que está mostrando as vidas
             */
            if (imageView.tag >= 10){
                /*Verificando a Tag(lembrando que ela começa de 10) então subtrai-se 10 para verificar se é menor ou igual a quantidade de vidas do usuário, caso positivo esta imageView é mostrado, caso contrário ela fica escondida.
                 */
                if (imageView.tag-10 < [Life sharedInstance].lifeCount){
                    [imageView setHidden:NO];
                }
                else{
                    [imageView setHidden:YES];
                }
            }
            else{
                continue;
            }
        }
    }
    
}

- (void) uploadLivesByTimer:(NSTimer *)timer{
    /* O Timer disparou este método após o tempo calculado, salva as vidas e recupera novamente */
    NSLog(@"Life obj = %@",[Life sharedInstance]);
    [Life sharedInstance].lifeCount++;
   
    [Life sharedInstance].lifeTime = [NSDate date];
    [self updateLivesView];
    [self saveLives];
    //[self getUserLives];
    if ([timer isValid]){
        [timer invalidate];
    }
    [self startLivesTimer];
}

//10,20,25,30,25
- (void) startLivesTimer{
    int intervalInMinutes;
    switch ([Life sharedInstance].lifeCount) {
        case 0:
            intervalInMinutes = 10;
            break;
        case 1:
            intervalInMinutes = 20;
            break;
        case 2:
            intervalInMinutes = 25;
            break;
        case 3:
            intervalInMinutes = 30;
            break;
        case 4:
            intervalInMinutes = 35;
            break;
        case 5:
        default:
            return;
    }
    
    
    if ([Life sharedInstance].lifeCount == 0){
        UILocalNotification *localLifeNotification = [[UILocalNotification alloc] init];
        NSDate *now = [NSDate date];
        [localLifeNotification setFireDate:[now dateByAddingTimeInterval:intervalInMinutes * 60]];
        localLifeNotification.alertBody = @"You can play more levels now!";
        // Set the action button
        localLifeNotification.alertAction = @"Play";
        localLifeNotification.alertTitle = @"Life Recharged";
        localLifeNotification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] scheduleLocalNotification:localLifeNotification];
    }
    
    self.lifeTimer = [NSTimer scheduledTimerWithTimeInterval:intervalInMinutes * 60 target:self selector:@selector(uploadLivesByTimer:) userInfo:nil repeats:NO];
    NSLog(@"Timer Fired");
}

#pragma mark - Level
-(IBAction)back:(id)sender
{
    [self fexarTela:self];
    [self performSegueWithIdentifier:@"Menu" sender:self];
    
    
}
-(IBAction)selectLevel:(id)sender
{
    
    UIButton *level = (UIButton *)sender;
    _i = level.tag;
    
    //Tira o shop
    if(!_shopOpen){
        self.shopScrollView.center = CGPointMake(-400, self.shopScrollView.center.y);
        _shopi.enabled = NO;
    }
    
    if(_i <= [ClearedLevelsSingleton sharedInstance].lastLevelCleared){
        //Obtem o target score
        JIMCLevel *lvl = [[JIMCLevel alloc]initWithFile:[NSString stringWithFormat:@"Level_%d",(int)_i]];
        
        _lblFase.text   = [NSString stringWithFormat:@"Stage %d",(int)_i+1];
        _lblTarget.text = [NSString stringWithFormat:@"Goal = %d pts",(int)lvl.targetScore];
        _lblMoves.text  = [NSString stringWithFormat:@"%d moves",(int)lvl.maximumMoves];
        
        //Escurece o fundo
        _blurView = [[UIView alloc] initWithFrame:self.view.frame];
        _blurView.backgroundColor = [UIColor clearColor];
        [self.view insertSubview:_blurView belowSubview:_informFase];
        
        NSArray *array = [[NSArray alloc]initWithContentsOfFile:_plistPath];
        NSDictionary *dic = [[NSDictionary alloc] initWithDictionary:[array objectAtIndex:_i]];
        
        NSInteger score = [dic[@"HighScore"] integerValue];
        
        if(score >= lvl.targetScore * 1.5){
            _star1.image = [UIImage imageNamed:@"estrela_fill"];
            _star2.image = [UIImage imageNamed:@"estrela_fill"];
            _star3.image = [UIImage imageNamed:@"estrela_fill"];
        }else{
            if(score >= lvl.targetScore * 1.25){
                _star1.image = [UIImage imageNamed:@"estrela_fill"];
                _star2.image = [UIImage imageNamed:@"estrela_fill"];
                _star3.image = [UIImage imageNamed:@"estrela_outline"];
            }else{
                if(score >= lvl.targetScore * 1){
                    _star1.image = [UIImage imageNamed:@"estrela_fill"];
                    _star2.image = [UIImage imageNamed:@"estrela_outline"];
                    _star3.image = [UIImage imageNamed:@"estrela_outline"];
                }else{
                    _star1.image = [UIImage imageNamed:@"estrela_outline"];
                    _star2.image = [UIImage imageNamed:@"estrela_outline"];
                    _star3.image = [UIImage imageNamed:@"estrela_outline"];
                }
            }
        }
        
        [UIView animateWithDuration:1.5
                              delay:0
             usingSpringWithDamping:0.65
              initialSpringVelocity:0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             _blurView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
                             self.informFase.center   = CGPointMake(CGRectGetMidX(self.view.frame), self.informFase.center.y);
                             self.scroll1.center      = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMaxY(self.view.frame)-35);
                             _btn.center              = CGPointMake(_informFase.frame.origin.x + 295, _informFase.frame.origin.y - 25);
                             _lblFase.center          = CGPointMake(315/2.0, 35);
                             _star2.center            = CGPointMake(315/2.0, _lblFase.center.y + 70);
                             _star1.center            = CGPointMake(_star2.center.x - 60, _star2.center.y + 30);
                             _star3.center            = CGPointMake(_star2.center.x + 60, _star2.center.y + 30);
                             _lblTarget.center        = CGPointMake(315/2.0, _star2.center.y + 100);
                             _lblMoves.center         = CGPointMake(315/2.0, _lblTarget.center.y + 30);
                             _btnJogar.center         = CGPointMake(315/2.0, _lblMoves.center.y + 60);
                         }completion:nil];
    }
}

-(IBAction)shop:(id)sender
{
    
    
    //Tira as infos da fase
    self.scroll1.center      = CGPointMake(500, CGRectGetMaxY(self.view.frame)-35);
    _btnJogar.center         = CGPointMake(-400, _btnJogar.center.y);
    _lblTarget.center        = CGPointMake(-400, _lblTarget.center.y);
    _lblMoves.center         = CGPointMake(-400, _lblMoves.center.y);
    _lblFase.center          = CGPointMake(-400, _lblFase.center.y);
    _star1.center = CGPointMake(-400, _star1.center.y);
    _star2.center = CGPointMake(-400, _star2.center.y);
    _star3.center = CGPointMake(-400, _star1.center.y);
    
    if(!_shopOpen){
        //Escurece o fundo
        _blurView = [[UIView alloc] initWithFrame:self.view.frame];
        _blurView.backgroundColor = [UIColor clearColor];
        [self.view insertSubview:_blurView belowSubview:_informFase];
        
        [UIView animateWithDuration:1.5
                              delay:0
             usingSpringWithDamping:0.65
              initialSpringVelocity:0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             _blurView.backgroundColor   = [UIColor colorWithWhite:0 alpha:0.5];
                             self.informFase.center     = CGPointMake(CGRectGetMidX(self.view.frame), self.informFase.center.y);
                             self.shopScrollView.center = CGPointMake(CGRectGetMidX(self.view.frame), self.shopScrollView.center.y);
                             self.activityIndicatorViewShop.center = CGPointMake(CGRectGetMidX(self.view.frame), 50);
                         }completion:nil];
        _shopOpen = YES;
    }
    

}

-(IBAction)jogar:(id)sender
{
    if ([self shouldPerformSegueWithIdentifier:@"Level" sender:sender]){
        [self performSegueWithIdentifier:@"Level" sender:self];
    }
}
-(IBAction)fexarTela:(id)sender
{
    _shopOpen = NO;
    _shopi.enabled = YES;

    [UIView animateWithDuration:1.5
                          delay:0
         usingSpringWithDamping:0.65
          initialSpringVelocity:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         _blurView.backgroundColor = [UIColor clearColor];
                         self.informFase.center = CGPointMake(CGRectGetMinX(self.view.frame)-300,self.informFase.center.y);
                         self.scroll1.center    = CGPointMake(CGRectGetMaxX(self.view.frame)+500, self.scroll1.center.y);
                         _btn.center            = CGPointMake(-300, _btn.center.y);
                         
                     }completion:^(BOOL finished){
                         [_blurView removeFromSuperview];
                     }];
}

-(IBAction)ajuda:(id)sender
{
   [AdColony playVideoAdForZone:@"vz260b8083dbf24e3fa1" withDelegate:nil withV4VCPrePopup:YES andV4VCPostPopup:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    NSLog(@"World Map Life: %@",[Life sharedInstance]);
    if ([identifier isEqualToString:@"Level"]){
        if ([Life sharedInstance].lifeCount >= 1){
            return YES;
        }
        else{
            [self showAlertWithTitle:@"Warning" andMessage:@"Insufficient lives"];
            return NO;
        }
    };
    
    return YES;
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([self shouldPerformSegueWithIdentifier:segue.identifier sender:sender]){
        if ([segue.identifier isEqualToString:@"Level"]){
            GameViewController *view = [segue destinationViewController];
            //Preparar a classe que carrega o nível para carregar o nível _i
            view.levelString = [NSString stringWithFormat:@"Level_%d",(int)_i];
        }
    }
}

-(void)adicionaFundo
{
    //ScrollView
    UIImageView *fundo;
    //Carrega a imagem de fundo
    if(IPHONE6){
         fundo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mapa_2.0Iphone6"]];
    }else if(IPHONE6PLUS) {
        fundo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mapa_2.0Iphone6Plus"]];
    }else{
        fundo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mapa_2.0"]];
    }
    CGRect frame = fundo.frame;
    
    frame.origin = CGPointMake(0, _offset);
    fundo.contentMode = UIViewContentModeScaleToFill;
    
    _scrollView = [[UIScrollView alloc] initWithFrame: self.view.frame];
    _scrollView.contentSize = CGSizeMake(frame.size.width, frame.size.height);
    _scrollView.backgroundColor = [UIColor colorWithRed:138/255.0 green:136/255.0 blue:70/255.0 alpha:1];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator   = NO;
    _scrollView.delegate = self;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
    [_scrollView addGestureRecognizer:singleTap];
    
    [self.view addSubview:_scrollView];
    
    [_scrollView addSubview:fundo];
}

//-(void)adicionaImagemSuperior
//{
//    //Carrega a imagem de cima
//    UIImageView *fundoSuperior = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui_pontos_movimentos"]];
//    fundoSuperior.frame = CGRectMake(0, 0, self.view.frame.size.width, 80);
//    
//    [self.view insertSubview:fundoSuperior belowSubview:_informFase];
//}

-(void)adicionaVidas
{
    //Vidas
    UILabel *vidas = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.view.frame) - 30, 5, 60, 60)];
    vidas.text = [NSString stringWithFormat:@"Lifes\n%ld",(long)[Life sharedInstance].lifeCount];
    vidas.backgroundColor = [UIColor redColor];
    vidas.numberOfLines = 3;
    vidas.lineBreakMode = NSLineBreakByWordWrapping;
    vidas.font = [UIFont fontWithName:@"Chewy" size:20];
    vidas.textColor = [UIColor whiteColor];
    vidas.textAlignment = NSTextAlignmentCenter;
    [self.view insertSubview:vidas belowSubview:_informFase];
}

-(void)adicionaMoedas
{
    //Moedas
    UILabel *moedas = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.view.frame) - 80, 5, 60, 60)];
    moedas.text = @"Coins\n??";
    moedas.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0 alpha:1];
    moedas.numberOfLines = 3;
    moedas.lineBreakMode = NSLineBreakByWordWrapping;
    moedas.font = [UIFont fontWithName:@"Chewy" size:20];
    moedas.textColor = [UIColor whiteColor];
    moedas.textAlignment = NSTextAlignmentCenter;
    [self.view insertSubview:moedas belowSubview:_informFase];
}

-(void)adicionaAjuda
{
    //Botao ajuda
    UIButton *ajuda = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [ajuda addTarget:self
              action:@selector(ajuda:)
    forControlEvents:UIControlEventTouchUpInside];
    
    [ajuda setTitle:[NSString stringWithFormat:@"?"] forState:UIControlStateNormal];
    ajuda.frame = CGRectMake(CGRectGetMaxX(self.view.frame) - 50, CGRectGetMaxY(self.view.frame) - 50, 32, 32);
    ajuda.titleLabel.font = [UIFont fontWithName:@"Chewy" size:25];
    ajuda.tintColor = [UIColor whiteColor];
    ajuda.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"botao_ajuda"]];
    [self.view insertSubview:ajuda belowSubview:_informFase];
}

-(void)adicionaBotaoBack
{
    //Cria o botao back
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.tag = _i;
    
    [button addTarget:self
               action:@selector(back:)
     forControlEvents:UIControlEventTouchUpInside];
    
    //    [button setTitle:[NSString stringWithFormat:@"Back"] forState:UIControlStateNormal];
    button.frame = CGRectMake(20, 15, 60, 32);
    //    button.titleLabel.font = [UIFont fontWithName:@"Chewy" size:20];
    button.tintColor = [UIColor whiteColor];
    button.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"botao_back"]];
    [self.view insertSubview:button belowSubview:_informFase];
}

-(void)adicionaBotoesFases
{
    
    NSArray *mapButtons = [[NSArray alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MapButtons" ofType:@"plist"]];
    
    _i = -1;
    //Cria os botões das fases
    for(NSDictionary *button in mapButtons){
        _i++;
        //Cria o botao de nivel
        NSNumber *x = button[@"xPosition"];
        NSNumber *y = button[@"yPosition"];
        CGFloat yOffset = _scrollView.contentSize.height - self.view.frame.size.height - _offset * 2;
        if(IPHONE6){
            x = [NSNumber numberWithFloat: x.doubleValue * IPHONE6_XSCALE];
            y = [NSNumber numberWithFloat: yOffset + y.doubleValue * IPHONE6_YSCALE];
        }else if(IPHONE6PLUS){
            x = [NSNumber numberWithFloat: x.doubleValue * IPHONE6PLUS_XSCALE];
            y = [NSNumber numberWithFloat: yOffset + y.doubleValue * IPHONE6PLUS_YSCALE];;
        }else{
            y = [NSNumber numberWithFloat: yOffset + y.doubleValue];
        }
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        
        button.tag = _i;
        
        [button addTarget:self
                   action:@selector(selectLevel:)
         forControlEvents:UIControlEventTouchUpInside];
        
        button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.tintColor = [UIColor whiteColor];
        
        if(IPHONE6){
            button.titleLabel.font = [UIFont fontWithName:@"Chewy" size:28];
        }else if(IPHONE6PLUS){
            button.titleLabel.font = [UIFont fontWithName:@"Chewy" size:32];
        }else{
            button.titleLabel.font = [UIFont fontWithName:@"Chewy" size:24];
        }
        
        if(IPHONE6){
            button.frame = CGRectMake(x.doubleValue, y.doubleValue + _offset, 54 * IPHONE6_XSCALE, 34 * IPHONE6_YSCALE); //remover o + offset
        }else if(IPHONE6PLUS){
            button.frame = CGRectMake(x.doubleValue, y.doubleValue + _offset, 54 * IPHONE6PLUS_XSCALE, 34 * IPHONE6PLUS_YSCALE); //remover o + offset
        }else{
            button.frame = CGRectMake(x.doubleValue, y.doubleValue + _offset, 54, 34); //remover o + offset
        }
        [button setTitle:[NSString stringWithFormat:@"%d\n",(int)_i + 1] forState:UIControlStateNormal];
        
        if(_i <= [ClearedLevelsSingleton sharedInstance].lastLevelCleared){
            [button setBackgroundImage:[UIImage imageNamed:@"fase_aberta"] forState:UIControlStateNormal];
        }else{
            [button setBackgroundImage:[UIImage imageNamed:@"fase_fechada"] forState:UIControlStateNormal];
        }
        
        [_scrollView addSubview:button];
        
    }
}

-(void)adicionaInformFase
{
    self.informFase = [[UIView alloc]initWithFrame:(CGRectMake(CGRectGetMinX((self.view.frame))-400, CGRectGetMidY(self.view.frame) - self.view.frame.size.height/4, 315, 334))];
    [self.informFase setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.informFase];
    
    //Retangulo
    self.informFase.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"retangulo_generico"]];
}

-(void)adicionaBotaoSair
{
    //botao sair
    _btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    _btn.center = CGPointMake(_informFase.frame.origin.x + 295, _informFase.frame.origin.y - 25);
    [_btn setBackgroundImage:[UIImage imageNamed:@"fechar"] forState:UIControlStateNormal];
    [_btn addTarget:self action:@selector(fexarTela:)forControlEvents:UIControlEventTouchUpInside];
    
    [self.view insertSubview:_btn aboveSubview:_informFase];
}

-(void)adicionaBotaoJogar
{
    //botao jogar
    _btnJogar = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.informFase.frame), CGRectGetMaxY(self.informFase.frame) / 2 + 30, 200,50)];
    _btnJogar.backgroundColor = [UIColor colorWithRed:69.0/255.0 green:88.0/255.0 blue:151.0/255.0 alpha:1.0];
    _btnJogar.layer.borderColor = [UIColor whiteColor].CGColor;
    _btnJogar.layer.borderWidth = 2.0;
    _btnJogar.layer.cornerRadius = 12.0;
    _btnJogar.titleLabel.textColor = [UIColor whiteColor];
    _btnJogar.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_btnJogar setTitle:@"Play!" forState:UIControlStateNormal];
    [_btnJogar.titleLabel setFont:[UIFont fontWithName:@"Chewy" size:30]];
    [_btnJogar addTarget:self action:@selector(jogar:)forControlEvents:UIControlEventTouchUpInside];
}

-(void)adicionaDetalhesDaFase
{
    //Fase
    _lblFase = [[UILabel alloc]initWithFrame:CGRectMake(0, 35, 300, 55)];
    _lblFase.textColor = [UIColor whiteColor];
    _lblFase.font = [UIFont fontWithName:@"Chewy" size:40];
    _lblFase.textAlignment = NSTextAlignmentCenter;
    
    //Target
    _lblTarget = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMidX(self.informFase.frame), CGRectGetMaxY(self.informFase.frame) / 2 - 60, 300, 55)];
    _lblTarget.textColor = [UIColor whiteColor];
    _lblTarget.font = [UIFont fontWithName:@"Chewy" size:30];
    [_lblTarget setTextAlignment:NSTextAlignmentCenter];
    
    //Moves
    _lblMoves = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMidX(self.informFase.frame), CGRectGetMaxY(self.informFase.frame) / 2 - 30, 300, 55)];
    _lblMoves.textColor = [UIColor whiteColor];
    _lblMoves.font = [UIFont fontWithName:@"Chewy" size:20];
    _lblMoves.textAlignment = NSTextAlignmentCenter;
    
    //Estrelas
    _star1 = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"estrela_outline"]];
    _star2 = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"estrela_outline"]];
    _star3 = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"estrela_outline"]];
    
    _star1.center = CGPointMake(CGRectGetMidX(self.informFase.frame) - 60, CGRectGetMidY(self.informFase.frame)/2-15);
    _star2.center = CGPointMake(CGRectGetMidX(self.informFase.frame), CGRectGetMidY(self.informFase.frame)/2-35);
    _star3.center = CGPointMake(CGRectGetMidX(self.informFase.frame) + 60, CGRectGetMidY(self.informFase.frame)/2-15);
    
    //Ajustes de centros
    
    _lblFase.center          = CGPointMake(315/2.0, 35);
    _star2.center            = CGPointMake(315/2.0, _lblFase.center.y + 70);
    _star1.center            = CGPointMake(_star2.center.x - 60, _star2.center.y + 30);
    _star3.center            = CGPointMake(_star2.center.x + 60, _star2.center.y + 30);
    _lblTarget.center        = CGPointMake(315/2.0, _star2.center.y + 100);
    _lblMoves.center         = CGPointMake(315/2.0, _lblTarget.center.y + 30);
    _btnJogar.center         = CGPointMake(315/2.0, _lblMoves.center.y + 60);
    
    [self.informFase addSubview:_btnJogar];
    [self.informFase addSubview:_lblTarget];
    [self.informFase addSubview:_lblMoves];
    [self.informFase addSubview:_lblFase];
    [self.informFase addSubview:_star1];
    [self.informFase addSubview:_star2];
    [self.informFase addSubview:_star3];
}

-(void)adicionaShop
{
    //Shopi
    _shopi = [[UIButton alloc] initWithFrame:CGRectMake(20, 5, 60, 60)];
    [_shopi setTitle:@"Shop" forState:UIControlStateNormal];
    _shopi.backgroundColor = [UIColor blueColor];
    [_shopi addTarget:self action:@selector(shop:)forControlEvents:UIControlEventTouchUpInside];
    _shopi.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self.view insertSubview:_shopi belowSubview:_informFase];
    
    int numberOfItens = 10;
    
    _shopScrollView = [[UIScrollView alloc] initWithFrame: CGRectMake(0, 60, 290, 260)];
    _shopScrollView.contentSize = CGSizeMake(290, 60 * numberOfItens); //o 60 é pra teste, caso precise aumenta o valor
    _shopScrollView.showsHorizontalScrollIndicator = NO;
    _shopScrollView.showsVerticalScrollIndicator   = NO;
    _shopScrollView.delegate = self;
    
    _flag = false;

    [[JIMCAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success) {
            // Termina o loading
            [self stopSpinningShop];
            _products = products;
            
            int j = 0;
            for(SKProduct* prod in _products){
                UIView *item = [[UIView alloc] initWithFrame:CGRectMake(20, (60 * j), 50, 50)];
                item.backgroundColor = [UIColor colorWithHue:(CGFloat)j/10 saturation:1 brightness:1 alpha:1];
                [_shopScrollView addSubview:item];
                
                UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(80,(60 * j), 150, 50)];
                UIButton* buyButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width-150,(60 * j), 150, 50)];
                
                [buyButton setTitle:@"Buy" forState:UIControlStateNormal];
                [buyButton setTag:j];
               
                [_shopScrollView addSubview:buyButton];
                [buyButton addTarget:self action:@selector(buyButtonTapped:)forControlEvents:UIControlEventTouchUpInside];
                
                description.text = prod.localizedTitle;
                [_shopScrollView addSubview:description];
                j++;
                _flag = true;
            }
        }
    }];
    
    [self.informFase addSubview:_shopScrollView];
}

- (void)buyButtonTapped:(id)sender {
    
    if (_flag) {
        UIButton *buyButton = (UIButton *)sender;
        SKProduct *product = _products[buyButton.tag];
        
        NSLog(@"Buying %@...", product.productIdentifier);
        [[JIMCAPHelper sharedInstance] buyProduct:product];
    }
}

-(void)forceSelect
{
    UIButton *force = [[UIButton alloc]init];
    force.tag = _nextStage;
    
    [self selectLevel:force];
}

- (void)allocScrollViewFacebook {
    // Aloca o Scroll na view
    [self.view addSubview:_scroll1];
    
    self.activityIndicatorViewShop.center = CGPointMake(-400, self.shopScrollView.center.y);
    self.activityIndicatorViewShop = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(CGRectGetMidX(_shopScrollView.frame), CGRectGetMidY(_shopScrollView.frame), 60, 60)];
    
    [self.shopScrollView addSubview:self.activityIndicatorViewShop];
}

- (void)addScrollFacebook {
    // Define o posicionamento dos Scrolls CGRectGetMaxY(self.view.frame)-70
    CGRect tamanhoScroll1 = CGRectMake(self.view.frame.size.width, CGRectGetMaxY(self.view.frame)-70, self.view.frame.size.width, 70);
    _scroll1 = [[UIScrollView alloc]initWithFrame:tamanhoScroll1];
    _scroll1.contentSize = CGSizeMake(self.view.frame.size.width / 3 * ([self loadFacebookFriendsIDs].count+1), 70);
    _scroll1.backgroundColor = [UIColor colorWithRed:(119.0/255) green:(185.0/255) blue:(195.0/255) alpha:1];
    _scroll1.delegate = self;
}

- (void)addPeopleOnScrollFacebook {
    // Mostra imagens
    UIImageView *imagem;
    // Mostra os nomes das pessoas
    UILabel* nome;
    
    int i = 0;
    
    NSMutableArray *arrayIds = [NSMutableArray array];
    NSMutableArray *arrayNames = [NSMutableArray array];
    
    NSArray* tempArrayName;
    
    self.userId = [[self loadFacebookUserID] objectForKey:@"facebookID"];
    self.userName = [[self loadFacebookUserID] objectForKey:@"alias"];
    tempArrayName = [self.userName componentsSeparatedByString:@" "];
    
    // Aloca um botão do tamanho da metade da tela em que está
    imagem = [[UIImageView alloc]initWithFrame:CGRectMake(((self.view.frame.size.width*i)+120)/3, 5, 40, 40)];
    nome = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width*i)+120)/3, 35, 60, 40)];
    
    nome.text = tempArrayName[0];
    [nome setFont:[UIFont fontWithName:@"Chewy" size:14.0]];
    nome.textColor = [UIColor whiteColor];
    
    NSString* userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", self.userId];
    NSLog(@"user %@", userImageURL);
    
    NSData* imageData = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:userImageURL]];
    imagem.image = [UIImage imageWithData:imageData];
    imagem.contentMode = UIViewContentModeScaleToFill;
    [imagem clipsToBounds];
    
    // Encerra animação de loading
    if (imageData!=nil) {
        [_scroll1 addSubview:nome];
        [_scroll1 addSubview:imagem];
    }

    
    for (NSDictionary* friends in [[self loadFacebookFriendsIDs] objectForKey:@"facebookFriends"]) {
        
        [arrayIds addObject:[friends objectForKey:@"id"]];
        [arrayNames addObject:[friends objectForKey:@"name"]];
        
        // Define a cor do botão
        [imagem setBackgroundColor:[UIColor clearColor]];
        // Adiciona o botão no Scroll
        [_scroll1 addSubview:imagem];
        [_scroll1 addSubview:nome];
        
        // Aloca uma imagem do tamanho da metade da tela em que está
        imagem = [[UIImageView alloc]initWithFrame:CGRectMake(((self.view.frame.size.width*(i+1))+120)/3, 5, 40, 40)];
        nome = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width*(i+1))+120)/3, 35, 60, 40)];
        
        tempArrayName = [[arrayNames objectAtIndex:i] componentsSeparatedByString:@" "];
        NSLog(@"tempArrayName = %@", tempArrayName[0]);
        nome.text = tempArrayName[0];
        [nome setFont:[UIFont fontWithName:@"Chewy" size:14.0]];
        nome.textColor = [UIColor whiteColor];
        
        NSString* friendsImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [arrayIds objectAtIndex:i]];
        
        NSData* imageData = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:friendsImageURL]];
        imagem.image = [UIImage imageWithData:imageData];
        imagem.contentMode = UIViewContentModeScaleToFill;
        
        // Define a cor do botão
        [imagem setBackgroundColor:[UIColor clearColor]];
        // Adiciona a imagem no Scroll
        
        // Daqui em diante, adiciona os amigos do facebook
        i++;

        // Encerra animação de loading
        if (imageData!=nil) {
            [self stopSpinningFacebook];
            
            [_scroll1 addSubview:imagem];
            [_scroll1 addSubview:nome];
        }
    }
}

- (void)allocAnimationSpinning{
    // Inicia animação de loading
    self.activityIndicatorViewFacebook = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(((self.view.frame.size.width*1)+120)/3, 5, 40, 40)];
    [_scroll1 addSubview:self.activityIndicatorViewFacebook];
    [self.activityIndicatorViewFacebook startAnimating];
}

- (void)startSpinningShop {
    [self.activityIndicatorViewShop startAnimating];
}

- (void)stopSpinningShop {
    [self.activityIndicatorViewShop stopAnimating];
}

- (void)startSpinningFacebook {
    [self.activityIndicatorViewFacebook startAnimating];
}

- (void)stopSpinningFacebook {
    [self.activityIndicatorViewFacebook stopAnimating];
}

-(void)adicionaMenuRapido
{
    CGFloat buttonSize = 28.0;
    _menuRapido = [[UIButton alloc] initWithFrame:CGRectMake(3, CGRectGetMaxY(self.view.frame) - buttonSize -3, buttonSize, buttonSize)];
    _menuRapido.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"icon_open"]];
    [_menuRapido addTarget:self action:@selector(menuRapido:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:_menuRapido aboveSubview:_scrollView];
    
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
    [_ajuda addTarget:self action:@selector(ajuda:) forControlEvents:UIControlEventTouchUpInside];
    
    _btnSair = [[UIButton alloc]initWithFrame:CGRectMake(130, 155, 30, 33)];
    [_btnSair setBackgroundImage:[UIImage imageNamed:@"icon_sair"] forState:UIControlStateNormal];
    [_btnSair addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];    
    _ligaMusica.alpha = 0;
    _ligaSFX.alpha = 0;
    _ajuda.alpha = 0;
    _btnSair.alpha = 0;
    
    [self.fundoMenuRapido addSubview:_ligaMusica];
    [self.fundoMenuRapido addSubview:_ligaSFX];
    [self.fundoMenuRapido addSubview:_ajuda];
    [self.fundoMenuRapido addSubview:_btnSair];
    
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
                            options:0
                         animations:^{
                             CGFloat imageSize = 203.0;
                             CGFloat buttonSize = 27.0;
                             
                             _menuRapido.frame = CGRectMake(3, CGRectGetMaxY(self.view.frame) - buttonSize - 3, buttonSize, buttonSize);
                             _fundoMenuRapido.frame = CGRectMake(0, CGRectGetMaxY(self.view.frame) - imageSize, imageSize, imageSize);
                             _ligaMusica.alpha = 1;
                             _ligaSFX.alpha = 1;
                             _ajuda.alpha = 1;
                             _btnSair.alpha = 1;
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
                            options:0
                         animations:^{
                             CGFloat imageSize = 62.0;
                             CGFloat buttonSize = 28.0;
                             
                             _menuRapido.frame = CGRectMake(3, CGRectGetMaxY(self.view.frame) - buttonSize - 3, buttonSize, buttonSize);
                             _fundoMenuRapido.frame = CGRectMake(0, CGRectGetMaxY(self.view.frame) - imageSize, imageSize, imageSize);
                             _ligaMusica.alpha = 0;
                             _ligaSFX.alpha = 0;
                             _ajuda.alpha = 0;
                             _btnSair.alpha = 0;
                         }
                         completion:nil];
    }
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

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:_scrollView];
    if(_quickMenuOpen){
        if(!CGRectContainsPoint(_fundoMenuRapido.frame, location)){
            [self menuRapido:self];
        }
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
 
    if(_shopOpen){
        
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:_blurView];
        CGFloat originShop = self.view.frame.size.height/2 - _shopScrollView.frame.size.height/2;
        
        if(!CGRectContainsPoint(_shopScrollView.frame, location) || location.y < originShop){
            [self fexarTela:self];
        }
    }
}

@end
