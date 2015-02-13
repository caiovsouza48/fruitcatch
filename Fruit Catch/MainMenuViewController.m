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
#import "RNDecryptor.h"

#define USER_SECRET @"0x444F@c3b0ok"
#define ON 1
#define OFF 0

@interface MainMenuViewController (){
    UIView *connectingView;
}

@property (nonatomic) IBOutlet UIButton *musicBtn;
@property (nonatomic) IBOutlet UIButton *soundBtn;
@property (nonatomic) IBOutlet UIButton *singlePlayerBtn;
@property (nonatomic) IBOutlet UIButton *multiplayerBtn;
@property (nonatomic) IBOutlet UIButton *settingsBtn;
@property (nonatomic) IBOutlet UIImageView *nome;
@property (nonatomic) IBOutlet UISwitch *ligaMusica;
@property (nonatomic) IBOutlet UISwitch *ligaSFX;
@property (nonatomic) UIView *configuracao;
@property (nonatomic) UIView *blurView;
@property (nonatomic) BOOL option;
@property(nonatomic) NSArray *fbFriends;

@end

@implementation MainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.loginView.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    _loginView.delegate = self;
    
    
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
    [self loadFromFile];
    
    [self viewConfig];
    
    [self.view addSubview:self.configuracao];
}

-(void)viewConfig
{
    self.configuracao = [[UIView alloc]initWithFrame:(CGRectMake(self.view.frame.origin.x, CGRectGetMinY(self.view.frame)-404, 315, 404))];
    
    //Texto configuracao
    UILabel *configuracao = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMidX(self.configuracao.frame)-157, 10, 315, 50)];
    configuracao.font = [UIFont fontWithName:@"Chewy" size:40];
    configuracao.text = @"Configurações";
    configuracao.textAlignment = NSTextAlignmentCenter;
    configuracao.textColor = [UIColor whiteColor];
    
    //Texto Musica
    UILabel *musica = [[UILabel alloc]initWithFrame:CGRectMake(0, configuracao.frame.origin.y+70, 130, 50)];
    musica.font = [UIFont fontWithName:@"Chewy" size:35];
    musica.text = @"Música";
    musica.textAlignment = NSTextAlignmentCenter;
    musica.textColor = [UIColor whiteColor];
    
    //Switch da musica
    _ligaMusica             = [[UISwitch alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 75, musica.frame.origin.y + 12, 100, 50)];
    _ligaMusica.onTintColor = [UIColor colorWithRed:(CGFloat)81/255 green:(CGFloat)143/255 blue:(CGFloat)195/255 alpha:1];
    _ligaMusica.tintColor   = [UIColor colorWithRed:(CGFloat)111/255 green:(CGFloat)123/255 blue:(CGFloat)148/255 alpha:1];
    
    //Texto efeitos sonoros
    UILabel *efeitosSonoros = [[UILabel alloc]initWithFrame:CGRectMake(0, musica.frame.origin.y+45, 240, 50)];
    efeitosSonoros.font = [UIFont fontWithName:@"Chewy" size:35];
    efeitosSonoros.text = @"Efeitos Sonoros";
    efeitosSonoros.textAlignment = NSTextAlignmentCenter;
    efeitosSonoros.textColor = [UIColor whiteColor];
    
    //Switch dos SFX
    _ligaSFX             = [[UISwitch alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 75, efeitosSonoros.frame.origin.y + 12, 100, 50)];
    _ligaSFX.onTintColor = [UIColor colorWithRed:(CGFloat)81/255 green:(CGFloat)143/255 blue:(CGFloat)195/255 alpha:1];
    _ligaSFX.tintColor   = [UIColor colorWithRed:(CGFloat)111/255 green:(CGFloat)123/255 blue:(CGFloat)148/255 alpha:1];
    
    //Botao fechar
    UIButton *fechar = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.configuracao.frame) - 35, 20, 19, 19)];
    [fechar setBackgroundImage:[UIImage imageNamed:@"botao_fechar"] forState:UIControlStateNormal];
    [fechar addTarget:self action:@selector(fechar:)forControlEvents:UIControlEventTouchUpInside];
    
    //Botao restore purchase
    UIButton *restore = [[UIButton alloc]initWithFrame:CGRectMake(10, efeitosSonoros.frame.origin.y + 80, 200, 50)];
    [restore setTitle:@"Restaurar compras" forState:UIControlStateNormal];
    [restore setFont:[UIFont fontWithName:@"Chewy" size:20]];
    restore.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    restore.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    [self.configuracao addSubview:restore];
    
    //Botao termos
    UIButton *termos = [[UIButton alloc]initWithFrame:CGRectMake(10, restore.frame.origin.y + 40, 200, 50)];
    [termos setTitle:@"Termos e serviços" forState:UIControlStateNormal];
    [termos setFont:[UIFont fontWithName:@"Chewy" size:20]];
    termos.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    termos.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    [self.configuracao addSubview:termos];
    
    //Botao creditos
    UIButton *creditos = [[UIButton alloc]initWithFrame:CGRectMake(10, termos.frame.origin.y + 40, 200, 50)];
    [creditos setTitle:@"Créditos" forState:UIControlStateNormal];
    [creditos setFont:[UIFont fontWithName:@"Chewy" size:20]];
    creditos.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    creditos.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    [self.configuracao addSubview:creditos];
    
    //Botao facebook
    UIButton *fbLogin = [[UIButton alloc]initWithFrame:CGRectMake(10, creditos.frame.origin.y + 40, 200, 50)];
    [fbLogin setTitle:@"Logar com facebook" forState:UIControlStateNormal];
    [fbLogin setFont:[UIFont fontWithName:@"Chewy" size:20]];
    fbLogin.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    fbLogin.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    [self.configuracao addSubview:fbLogin];
    
    [self.configuracao addSubview:configuracao];
    [self.configuracao addSubview:musica];
    [self.configuracao addSubview:_ligaMusica];
    [self.configuracao addSubview:efeitosSonoros];
    [self.configuracao addSubview:_ligaSFX];
    [self.configuracao addSubview:fechar];
    [self.configuracao setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"retangulo_configuracoes"]]];
    
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
-(IBAction)fechar:(id)sender
{
    [UIView animateWithDuration:1.5
                          delay:0
         usingSpringWithDamping:0.65
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         [self.blurView removeFromSuperview];
                         self.configuracao.center = CGPointMake(self.configuracao.center.x, CGRectGetMinY(self.view.frame)-300);
                     }completion:^(BOOL fisished){
                         self.option = NO;
                     }];
}
-(IBAction)options:(id)sender
{
    
    if(!self.option){
        self.blurView = [[UIView alloc] initWithFrame:self.view.frame];
        self.blurView.backgroundColor = [UIColor clearColor];
        [self.view insertSubview:self.blurView atIndex:7];
        
        [UIView animateWithDuration:1.5
                              delay:0
             usingSpringWithDamping:0.65
              initialSpringVelocity:0
                            options:0
                         animations:^{
                             self.blurView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.875];
                             self.configuracao.center = CGPointMake(self.view.center.x, self.view.center.y);
                         }completion:^(BOOL fisished){
                             self.option = YES;
                         }];
        
        /*
         self.musicBtn.enabled = YES;
         self.musicBtn.alpha   = 1;
         
         self.soundBtn.enabled = YES;
         self.soundBtn.alpha   = 1;
         */
        //Fazer a animacao dos botoes surgindo
    }else{
        
        
        /*
         
         self.musicBtn.enabled = NO;
         self.musicBtn.alpha   = 0;
         
         self.soundBtn.enabled = NO;
         self.soundBtn.alpha   = 0;
         */
        
    }
    
    
}

-(IBAction)singlePlayer:(id)sender
{
    _singlePlayerButton.enabled = NO;
    [self performSegueWithIdentifier:@"Single" sender:self];
}

-(IBAction)multiplayer:(id)sender
{
    connectingView = [[UIView alloc]initWithFrame:self.view.frame];
    /*
    NSLog(@"Multiplayer");
    [[NetworkController sharedInstance] authenticateLocalUser];
    [[NetworkController sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 viewController:self];
     */
    
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

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    
    NSLog(@"USER = %@", user);
    
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
        if (!sucess){
            NSLog(@"Erro ao Salvar arquivo de Usuário");
        }
        else{
            
            
        }
        [self loadFromFile];
        
    }];
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

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
//Abaixou dessa ponto conlocar apenas funcoes relacionadas a In App Porcharse
#pragma mark - in-App PURCHASE
-(void)purchaseNoAds{
    if([SKPaymentQueue canMakePayments]){
        NSLog(@"User can make payments!");
        //SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kRemoveAdsProductIdentifier]];
           // productsRequest.delegate = self;
          //  [productsRequest start];
            connectingView.hidden = NO;
     }else{
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops."
                                                         message:@"I don't think you are allowed to make in-app purchases."
                                                        delegate:self
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
        [alert show];
         //Essa parte só é chamada quando dá algum problema.
     }
}
-(void)restore{
        //Trata do restore
        connectingView.hidden = NO;
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
        SKProduct *validProduct = nil;
        int count = (int)[response.products count];
        if(count > 0){
                validProduct = [response.products objectAtIndex:0];
                NSLog(@"Products Available!");
                [self purchase:validProduct];
                //Se o ID está correto, voila! Funcionou!
        }else if(!validProduct){
            NSLog(@"No products available");
            connectingView.hidden = YES;
            //id inválido?
        }
}

- (void)purchase:(SKProduct *)product{
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"received restored transactions: %i",(int) queue.transactions.count);
    for (SKPaymentTransaction *transaction in queue.transactions)
    {
        if(SKPaymentTransactionStateRestored){
            NSLog(@"Transaction state -> Restored");
            //Se restaurou corretamente, chama o doRemoveAds
            [self doRemoveAds];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            break;
        }
    }
    connectingView.hidden = YES;
    
}
-(void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error{
    NSLog(@"%@",error);
    connectingView.hidden = YES;
}
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for(SKPaymentTransaction *transaction in transactions){
        switch (transaction.transactionState){
            case SKPaymentTransactionStatePurchasing: NSLog(@"Transaction state -> Purchasing");
                //Processo de compra
                break;
            case SKPaymentTransactionStatePurchased:
                //(Cha-Ching!)
                [self doRemoveAds]; //Chama o método de remover ads!
                connectingView.hidden = YES;
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                NSLog(@"Transaction state -> Purchased");
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Transaction state -> Restored");
                //Mesmo código de purchase!
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                connectingView.hidden = YES;
                break;
            case SKPaymentTransactionStateFailed:
                //Se falhou...
                if(transaction.error.code != SKErrorPaymentCancelled){
                    NSLog(@"Transaction state -> Cancelled");
                    //Deu algo de errado na compra!
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                connectingView.hidden = YES;
                break;
        }
    }
    
}
- (void) failedTransaction: (SKPaymentTransaction *)transaction{
    if (transaction.error.code != SKErrorPaymentCancelled){
        // Mostra o erro aqui.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase Unsuccessful"
                                                        message:@"Your purchase failed. Please try again."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
    }
    connectingView.hidden = YES;
    //Tira a transação do queue.
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}
-(void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"%@",error);
    connectingView.hidden = YES;
    
}
-(void)doRemoveAds{
    //[[AppUserDefaults sharedAppUserDefaults]setNoAds:YES];
    //[self hideAds];
}
@end
