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

@property(nonatomic) NSTimer *lifeTimer;

@end

@implementation WorldMap


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self getUserLives];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self getUserLives];
    [self registerLivesBackgroundNotification];
    [self registerAppEnterForegroundNotification];
    //NSNotification *notification = [NSNotificationCenter defaultCenter]
    // Do any additional setup after loading the view.
    
    //Carrega a imagem de fundo
    UIImageView *fundo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mapa"]];
    [self.view addSubview:fundo];
    
    NSArray *mapButtons = [[NSArray alloc]initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MapButtons" ofType:@"plist"]];
    
    _i = -1;
    
    // Define o posicionamento dos Scrolls
    CGRect tamanhoScroll1 = CGRectMake(0, self.view.frame.size.height-100, self.view.frame.size.width, self.view.frame.size.height/2);

    // Aloca o Scroll baseado no posicionamento criado
    _scroll1 = [[UIScrollView alloc]initWithFrame:tamanhoScroll1];

    // Redimensiona o tamanho do Scroll
    // Alterar para a quantidad de amigos que a pessoa possui no facebook
    // ==================================================================================================
    _scroll1.contentSize = CGSizeMake(self.view.frame.size.width*6, self.view.frame.size.height/2);

    // Define a cor de fundo do Scroll
    _scroll1.backgroundColor = [UIColor colorWithRed:(119.0/255) green:(185.0/255) blue:(195.0/255) alpha:1];

    _scroll1.delegate = self;
    
    // Mostra imagens
    UIImageView *imagem;
    int i = 0;
    for (NSDictionary* friends in [self loadFacebookFriendsIDs]) {
        
        // Define a cor do botão
        [imagem setBackgroundColor:[UIColor clearColor]];
        // Adiciona o botão no Scroll
        [_scroll1 addSubview:imagem];
        
        // Adiciona o usuário do facebook
        if (i == 0) {
            // Aloca um botão do tamanho da metade da tela em que está
            imagem = [[UIImageView alloc]initWithFrame:CGRectMake(((self.view.frame.size.width*i)+60)/3, 20, 60, 60)];

            NSString* userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [self loadFacebookUserID]];
            
            NSData* imageData = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:userImageURL]];
            imagem.image = [UIImage imageWithData:imageData];
            // Adiciona o botão no Scroll
            [_scroll1 addSubview:imagem];
        }

        // Daqui em diante, adiciona os amigos do facebook
        i++;
        // Aloca um botão do tamanho da metade da tela em que está
        imagem = [[UIImageView alloc]initWithFrame:CGRectMake(((self.view.frame.size.width*i)+60)/3, 20, 60, 60)];
        
        NSString* friendsImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", friends];
        
        
        NSData* imageData = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:friendsImageURL]];
        imagem.image = [UIImage imageWithData:imageData];
        
        // Define a cor do botão
        [imagem setBackgroundColor:[UIColor clearColor]];
        // Adiciona o botão no Scroll
        [_scroll1 addSubview:imagem];
    }

    //Cria o botao back
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    button.tag = _i;
    
    [button addTarget:self
               action:@selector(selectLevel:)
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
        [self.view addSubview:button];
        
        break; //Remover depois
    }
    
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

- (NSArray *)loadFacebookFriendsIDs{
    NSString *appDataDir = [AppUtils getAppDataDir];
    if ([[NSFileManager defaultManager] fileExistsAtPath:appDataDir]) {
        NSData *data = [NSData dataWithContentsOfFile:appDataDir];
        NSError *error;
        NSData *decryptedData = [RNDecryptor decryptData:data withPassword:USER_SECRET error:&error];
        if (!error){
            NSDictionary *obj = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            NSLog(@"File dict = %@",obj);
            NSMutableArray *arrayIds = [NSMutableArray array];
            //NSDictionary *fbFriendsDict = [obj objectForKey:@"facebookFriends"];
            for (NSDictionary* friends in [obj objectForKey:@"facebookFriends"]) {
                [arrayIds addObject:[friends objectForKey:@"id"]];
            }
            return [arrayIds copy];
        }
    }
    return nil;
}

- (NSString *)loadFacebookUserID{
    NSString *appDataDir = [AppUtils getAppDataDir];
    if ([[NSFileManager defaultManager] fileExistsAtPath:appDataDir]) {
        NSData *data = [NSData dataWithContentsOfFile:appDataDir];
        NSError *error;
        NSData *decryptedData = [RNDecryptor decryptData:data withPassword:USER_SECRET error:&error];
        if (!error){
            NSDictionary *obj = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            NSLog(@"File dict = %@",obj);
            return [obj objectForKey:@"facebookID"];
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

-(IBAction)selectLevel:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    btn.enabled = NO;
    NSLog(@"Positionx = %f, y = %f",btn.frame.origin.x, btn.frame.origin.y);
    
    _i = btn.tag;
    
    if(_i > -1){
        if ([self shouldPerformSegueWithIdentifier:@"Level" sender:self]){
            [self performSegueWithIdentifier:@"Level" sender:self];
        }
        else{
            btn.enabled = YES;
        }
        
        
    }else{
        [self performSegueWithIdentifier:@"Menu" sender:self];
    }
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
    NSLog(@"return YES");
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
