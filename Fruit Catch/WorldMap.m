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

#define USER_SECRET @"0x444F@c3b0ok"

@interface WorldMap ()

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
@end

@implementation WorldMap


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self getUserLives];
    
    //Move a scrollView para o fundo da imagem.
    CGRect mask = CGRectMake(0, _scrollView.contentSize.height - self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    [_scrollView scrollRectToVisible:mask animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self getUserLives];
    [self registerLivesBackgroundNotification];
    [self registerAppEnterForegroundNotification];
    //NSNotification *notification = [NSNotificationCenter defaultCenter]
    
    //ScrollView
    
    //Carrega a imagem de fundo
    UIImageView *fundo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mapa"]];
    
    CGRect frame = fundo.frame;
    _scrollView = [[UIScrollView alloc] initWithFrame: self.view.frame];
    _scrollView.contentSize = CGSizeMake(frame.size.width, frame.size.height);
    
    _scrollView.backgroundColor = [UIColor cyanColor];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator   = NO;
    _scrollView.delegate = self;
    
    NSLog(@"Scrollview height = %f",_scrollView.frame.size.height);
    [self.view addSubview:_scrollView];
    
    [_scrollView addSubview:fundo];
    
    //Botoes do mapa
    NSArray *mapButtons = [[NSArray alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MapButtons" ofType:@"plist"]];
    
    _i = -1;
    
    // Define o posicionamento dos Scrolls CGRectGetMaxY(self.view.frame)-70
    CGRect tamanhoScroll1 = CGRectMake(CGRectGetMinX(self.view.frame)+self.view.frame.size.width, CGRectGetMaxY(self.view.frame)-70, self.view.frame.size.width, 70);
    
    // Aloca o Scroll baseado no posicionamento criado
    _scroll1 = [[UIScrollView alloc]initWithFrame:tamanhoScroll1];
    
    // Redimensiona o tamanho do Scroll
    // Alterar para a quantidad de amigos que a pessoa possui no facebook
    // ==================================================================================================
    _scroll1.contentSize = CGSizeMake(self.view.frame.size.width / 3 * ([self loadFacebookFriendsIDs].count+1), 70);
    
    // Define a cor de fundo do Scroll
    _scroll1.backgroundColor = [UIColor colorWithRed:(119.0/255) green:(185.0/255) blue:(195.0/255) alpha:1];
    
    _scroll1.delegate = self;
    
    // Mostra imagens
    UIImageView *imagem;
    
    // Mostra os nomes das pessoas
    UILabel* nome;
    
    int i = 0;
    
    NSMutableArray *arrayIds = [NSMutableArray array];
    NSMutableArray *arrayNames = [NSMutableArray array];
    
    NSArray* tempArrayName;
    
    for (NSDictionary* friends in [[self loadFacebookFriendsIDs] objectForKey:@"facebookFriends"]) {
        
        [arrayIds addObject:[friends objectForKey:@"id"]];
        [arrayNames addObject:[friends objectForKey:@"name"]];
        
        // Define a cor do botão
        [imagem setBackgroundColor:[UIColor clearColor]];
        // Adiciona o botão no Scroll
        [_scroll1 addSubview:imagem];
        [_scroll1 addSubview:nome];
        
        // Adiciona o usuário do facebook
        if (i == 0) {
            NSString* userId;
            NSString* userName;
            
            userId = [[self loadFacebookUserID] objectForKey:@"facebookID"];
            userName = [[self loadFacebookUserID] objectForKey:@"alias"];
            tempArrayName = [userName componentsSeparatedByString:@" "];
            
            // Aloca um botão do tamanho da metade da tela em que está
            imagem = [[UIImageView alloc]initWithFrame:CGRectMake(((self.view.frame.size.width*i)+120)/3, 5, 40, 40)];
            nome = [[UILabel alloc]initWithFrame:CGRectMake(((self.view.frame.size.width*i)+120)/3, 35, 60, 40)];
            
            nome.text = tempArrayName[0];
            [nome setFont:[UIFont fontWithName:@"Chewy" size:14.0]];
            nome.textColor = [UIColor whiteColor];
            
            NSString* userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", userId];
            
            NSData* imageData = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:userImageURL]];
            imagem.image = [UIImage imageWithData:imageData];
            imagem.contentMode = UIViewContentModeScaleToFill;
            
            // Adiciona a imagem no Scroll
            [_scroll1 addSubview:imagem];
            [_scroll1 addSubview:nome];
        }
        
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
        [_scroll1 addSubview:imagem];
        
        [_scroll1 addSubview:nome];
        
        // Daqui em diante, adiciona os amigos do facebook
        i++;
    }
    
    //Cria o botao back
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    button.tag = _i;
    
    [button addTarget:self
               action:@selector(back:)
     forControlEvents:UIControlEventTouchUpInside];
    
    [button setTitle:[NSString stringWithFormat:@"Back"] forState:UIControlStateNormal];
    button.frame = CGRectMake(50, 50, 60, 32);
    button.tintColor = [UIColor whiteColor];
    button.backgroundColor = [UIColor redColor];
    [self.view addSubview:button];
    
    //Cria os botões das fases
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
        
        button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.tintColor = [UIColor whiteColor];
        button.titleLabel.font = [UIFont fontWithName:@"Arial" size:24];
        button.frame = CGRectMake(x.integerValue, y.integerValue, 54, 34);
        [button setTitle:[NSString stringWithFormat:@"%d\n",(int)_i + 1] forState:UIControlStateNormal];
        //Necessário fazer um if para comparar se a fase está aberta ou fechada
        [button setBackgroundImage:[UIImage imageNamed:@"fase_aberta"] forState:UIControlStateNormal];
        //        [self.view addSubview:button];
        [_scrollView addSubview:button];
        
    }
    self.informFase = [[UIView alloc]initWithFrame:(CGRectMake(CGRectGetMinX((self.view.frame))-400, CGRectGetMidY(self.view.frame) - self.view.frame.size.height/4, 315, 334))];
    [self.informFase setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.informFase];
    
    //Retangulo
    self.informFase.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"retangulo_generico"]];
    
    //botao sair
    _btn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 45, 15, 25,25)];
    [_btn setBackgroundImage:[UIImage imageNamed:@"botao_fechar"] forState:UIControlStateNormal];
    [_btn addTarget:self action:@selector(fexarTela:)forControlEvents:UIControlEventTouchUpInside];
    
    //botao jogar
    _btnJogar = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.informFase.frame), CGRectGetMaxY(self.informFase.frame) / 2 + 30, 150,55)];
    [_btnJogar setTitle:@"Jogar" forState:UIControlStateNormal];
    [_btnJogar setFont:[UIFont fontWithName:@"Chewy" size:40]];
    [_btnJogar addTarget:self action:@selector(jogar:)forControlEvents:UIControlEventTouchUpInside];
    _btnJogar.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    _btnJogar.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    
    //Fase
    _lblFase = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMidX(self.informFase.frame), CGRectGetMinY(self.informFase.frame) / 2 - 40, 300, 55)];
    _lblFase.textColor = [UIColor whiteColor];
    _lblFase.font = [UIFont fontWithName:@"Chewy" size:40];
    _lblFase.textAlignment = UITextAlignmentCenter;
    
    //Target
    _lblTarget = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMidX(self.informFase.frame), CGRectGetMaxY(self.informFase.frame) / 2 - 60, 300, 55)];
    _lblTarget.textColor = [UIColor whiteColor];
    _lblTarget.font = [UIFont fontWithName:@"Chewy" size:30];
    _lblTarget.textAlignment = UITextAlignmentCenter;

    //Moves
    _lblMoves = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMidX(self.informFase.frame), CGRectGetMaxY(self.informFase.frame) / 2 - 30, 300, 55)];
    _lblMoves.textColor = [UIColor whiteColor];
    _lblMoves.font = [UIFont fontWithName:@"Chewy" size:20];
    _lblMoves.textAlignment = UITextAlignmentCenter;
    
    //Estrelas
    _star1 = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"estrela_outline"]];
    _star2 = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"estrela_outline"]];
    _star3 = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"estrela_outline"]];
    
    _star1.center = CGPointMake(CGRectGetMidX(self.informFase.frame) - 60, CGRectGetMidY(self.informFase.frame)/2-20);
    _star2.center = CGPointMake(CGRectGetMidX(self.informFase.frame), CGRectGetMidY(self.informFase.frame)/2-40);
    _star3.center = CGPointMake(CGRectGetMidX(self.informFase.frame) + 60, CGRectGetMidY(self.informFase.frame)/2-20);
    
    [self.informFase addSubview:_btn];
    [self.informFase addSubview:_btnJogar];
    [self.informFase addSubview:_lblTarget];
    [self.informFase addSubview:_lblMoves];
    [self.informFase addSubview:_lblFase];
    [self.informFase addSubview:_star1];
    [self.informFase addSubview:_star2];
    [self.informFase addSubview:_star3];
    
    // Aloca o Scroll na view
    [self.view addSubview:_scroll1];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
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
            intervalInMinutes = 1;
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
    
    //Obtem o target score
    JIMCLevel *lvl = [[JIMCLevel alloc]initWithFile:[NSString stringWithFormat:@"Level_%d",(int)_i]];
    NSLog(@"Target = %d",(int)lvl.targetScore);
    
    _lblFase.text   = [NSString stringWithFormat:@"Fase %d",(int)_i+1];
    _lblTarget.text = [NSString stringWithFormat:@"Objetivo = %d pts",(int)lvl.targetScore];
    _lblMoves.text  = [NSString stringWithFormat:@"%d jogadas",(int)lvl.maximumMoves];
    
    //Escurece o fundo
    UIView *blurView = [[UIView alloc] initWithFrame:self.view.frame];
    blurView.backgroundColor = [UIColor clearColor];
    [self.view insertSubview:blurView atIndex:4];
    
    [UIView animateWithDuration:1.5
                          delay:0
         usingSpringWithDamping:0.65
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         blurView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
                         self.informFase.center   = CGPointMake(CGRectGetMidX(self.view.frame), self.informFase.center.y);
                         self.scroll1.center      = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMaxY(self.view.frame)-35);
                         _btnJogar.center         = CGPointMake(CGRectGetMidX(self.informFase.frame), _btnJogar.center.y);
                         _lblTarget.center        = CGPointMake(CGRectGetMidX(self.informFase.frame), _lblTarget.center.y);
                         _lblMoves.center         = CGPointMake(CGRectGetMidX(self.informFase.frame), _lblMoves.center.y);
                         _lblFase.center          = CGPointMake(CGRectGetMidX(self.informFase.frame), _lblFase.center.y);
                         _star1.center = CGPointMake(CGRectGetMidX(self.informFase.frame) - 60, _star1.center.y);
                         _star2.center = CGPointMake(CGRectGetMidX(self.informFase.frame), _star2.center.y);
                         _star3.center = CGPointMake(CGRectGetMidX(self.informFase.frame) + 60, _star1.center.y);
                     }completion:nil];
}

-(IBAction)jogar:(id)sender
{
    [self performSegueWithIdentifier:@"Level" sender:self];
}
-(IBAction)fexarTela:(id)sender
{
    UIView *blurView = [[self.view subviews] objectAtIndex:4];
    [UIView animateWithDuration:1.5
                          delay:0
         usingSpringWithDamping:0.65
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         blurView.backgroundColor = [UIColor clearColor];
                         self.informFase.center = CGPointMake(CGRectGetMinX(self.view.frame)-300,self.informFase.center.y);
                         self.scroll1.center = CGPointMake(CGRectGetMinX(self.view.frame)+500, self.scroll1.center.y);
                         
                     }completion:^(BOOL finished){
                         [blurView removeFromSuperview];
                     }];
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
    if ([identifier isEqualToString:@"Level"]){
        if ([Life sharedInstance].lifeCount >= 1){
            return YES;
        }
        else{
            [self showAlertWithTitle:@"Aviso" andMessage:@"Vidas Insuficientes"];
            return NO;
        }
    }
//    NSLog(@"return YES");
    return YES;
    
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Level"]){
        GameViewController *view = [segue destinationViewController];
        //Preparar a classe que carrega o nível para carregar o nível _i
        view.levelString = [NSString stringWithFormat:@"Level_%d",(int)_i];
    }
}

@end
