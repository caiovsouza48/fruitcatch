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

#define SECRET @"0x777C4f3"

@interface WorldMap ()

@property NSInteger i;

@property(nonatomic) NSTimer *lifeTimer;

@end

@implementation WorldMap

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getUserLives];
    [self registerLivesBackgroundNotification];
    [self registerAppEnterForegroundNotification];
    //NSNotification *notification = [NSNotificationCenter defaultCenter]
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


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
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
    NSLog(@"Life Update");
    [self.lifeTimer invalidate];
    [self getUserLives];
    
}

- (void)getUserLives{
    //Carregando as Vidas do Arquivo, primeiro se desencripta e logo após seta na memória
    NSString *appDataDir = [self getAppDataDir];
    if ([[NSFileManager defaultManager] fileExistsAtPath:appDataDir]) {
        NSLog(@"App data Dir: %@",[self getAppDataDir]);
        NSData *data = [NSData dataWithContentsOfFile:[self getAppDataDir]];
        NSError *error;
        NSData *decryptedData = [RNDecryptor decryptData:data withPassword:SECRET error:&error];
        if (!error){
            Life *decryptedLive = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            self.lives = decryptedLive;
        }
        else{
            NSLog(@"Error in getUserLives: %@",error.localizedDescription);
        }
    }
    else{
        NSLog(@"File not exists");
        //NSLog(@"App data Dir: %@",[self getAppDataDir]);
        
        self.lives = [[Life alloc]initFromZero];
    }
    [self updateLivesLoadedLifeObject];
    
}


- (void) updateLivesLoadedLifeObject{
    NSDate *actualDate = [NSDate date];
    //Quanto tempo se passou desde o ultimo tempo registrado no plist
    NSTimeInterval interval = [actualDate timeIntervalSinceDate:self.lives.lifeTime];
    //Segundos para Minutos
    int minutesInterval = interval / 60;
    
    //Setando na Memoria a quantidade de vidas dependendo de quantos minutos se passou e quantas vidas estava registrada no arquivo
    switch (self.lives.lifeCount) {
        case 0:
            if (minutesInterval >= 35){
                self.lives.lifeCount = 5;
            }
            if (minutesInterval >= 30){
                self.lives.lifeCount = 4;
            }
            if (minutesInterval >= 25){
                self.lives.lifeCount = 3;
            }
            if (minutesInterval >= 20){
                self.lives.lifeCount = 2;
            }
            if (minutesInterval >= 10){
                self.lives.lifeCount = 1;
            }
            break;
        case 1:
            if (minutesInterval >= 35){
                self.lives.lifeCount = 5;
            }
            if (minutesInterval >= 30){
                self.lives.lifeCount = 4;
            }
            if (minutesInterval >= 25){
                self.lives.lifeCount = 3;
            }
            if (minutesInterval >= 20){
                self.lives.lifeCount = 2;
            }
            break;
        case 2:
            if (minutesInterval >= 35){
                self.lives.lifeCount = 5;
            }
            if (minutesInterval >= 30){
                self.lives.lifeCount = 4;
            }
            if (minutesInterval >= 25){
                self.lives.lifeCount = 3;
            }
            break;
        case 3:
            if (minutesInterval >= 35){
                self.lives.lifeCount = 5;
            }
            if (minutesInterval >= 30){
                self.lives.lifeCount = 4;
            }
            break;
        case 4:
            if (minutesInterval >= 35){
                self.lives.lifeCount = 5;
            }
            break;
        case 5:
            self.lives.lifeCount = 5;
        default:
            break;
    }
    [self updateLivesView];
    [self startLivesTimer];
}

- (void)saveLives{
    NSLog(@"Save Lives called");
    NSString *filePath = [self getAppDataDir];
    //NSLog(@"%@",self.lives);
    NSData *dataToSave = [NSKeyedArchiver archivedDataWithRootObject:self.lives];
    NSError *error;
    NSData *encryptedData = [RNEncryptor encryptData:dataToSave
                                        withSettings:kRNCryptorAES256Settings
                                            password:SECRET
                                               error:&error];
   
    BOOL sucess = [encryptedData writeToFile:filePath atomically:YES];
    //NSLog(@"saving file to %@ result is %d",filePath,sucess);
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
                if (imageView.tag-10 < self.lives.lifeCount){
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
    [self saveLives];
    [self getUserLives];
    if ([timer isValid]){
        [timer invalidate];
    }
    [self startLivesTimer];
}

//10,20,25,30,25
- (void) startLivesTimer{
    int intervalInMinutes;
    switch (self.lives.lifeCount) {
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
        case 5:
        default:
            break;
    }
     self.lifeTimer = [NSTimer scheduledTimerWithTimeInterval:intervalInMinutes * 60 target:self selector:@selector(uploadLivesByTimer:) userInfo:nil repeats:NO];
    NSLog(@"Timer Fired");
}

#pragma mark - Level

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
