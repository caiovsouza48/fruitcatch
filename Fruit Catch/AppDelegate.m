//
//  AppDelegate.m
//  Fruit Catch
//
//  Created by Caio de Souza on 24/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import "AppDelegate.h"
#import "NetworkController.h"
#import "EloRating.h"
#import "MultiplayerGameViewController.h"
#import "ClearedLevelsSingleton.h"
#import "JIMCAPHelper.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "AppUtils.h"
#import "SettingsSingleton.h"
#import "GameViewController.h"

#define NEXTPEER_KEY @"08d8f6a9b74c70e157add51c12c7d272"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)nextpeerDidTournamentEnd{
    
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [JIMCAPHelper sharedInstance];
    
    NSInteger numberOfLevels = 30;

    if (![[NSFileManager defaultManager] fileExistsAtPath:[AppUtils getAppMultiplayer]]){
        [self setUserElo];
    }

    [AppDelegate sendFiletoWebService];
    
    //Checa se é o primeiro uso, caso seja, libera apenas o primeiro nível
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"hasPlayed"])
    {
        [SettingsSingleton sharedInstance].music = 1;
        [SettingsSingleton sharedInstance].SFX = 1;
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasPlayed"];
        [[NSUserDefaults standardUserDefaults] setInteger:(-1) forKey:@"lastCleared"];
        [[ClearedLevelsSingleton sharedInstance] updateLastLevel];
        
        NSMutableArray *array = [[NSMutableArray alloc]init];
        for(int i=0; i<numberOfLevels; i++){
            NSDictionary *dic = [[NSDictionary alloc] initWithObjects:@[@0,@0,@0] forKeys:@[@"time",@"highScore",@"stars"]];
            
            [array addObject:dic];
        }
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *plistPath = [NSString stringWithFormat:@"%@/highscore.plist",documentsDirectory];
        
        [array writeToFile:plistPath atomically:YES];
//        if ([self loadFromWebService]) {
//            NSLog(@"Dados carregados com sucesso !");
//        }
    }
    
    // Override point for customization after application launch.
    [FBLoginView class];
    [[UIApplication sharedApplication]setStatusBarHidden:YES ];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Launch"];
    [Nextpeer initializeWithProductKey:NEXTPEER_KEY andDelegates:[NPDelegatesContainer containerWithNextpeerDelegate:self]];
    UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    
    UIUserNotificationSettings *mySettings =
    [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    return YES;
}

- (BOOL)loadFromWebService{
    NSString *appDataDir = [AppUtils getAppDataDir];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:appDataDir] && [[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory]) {
        NSData *data = [NSData dataWithContentsOfFile:appDataDir];
        NSError *error;
        NSData *decryptedData = [RNDecryptor decryptData:data withPassword:USER_SECRET error:&error];
        if (!error){
            NSDictionary *obj = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            NSLog(@"File dict = %@",obj[@"facebookID"]);
            [self loadPerformanceFromWebService:obj];
        }
        return YES;
    }
    return NO;
}

- (void)setUserElo{
    NSString *userEloPath = [AppUtils getAppMultiplayer];
    NSDictionary *userEloData = @{@"elo" : @1200};
    NSData *dataToSave = [NSKeyedArchiver archivedDataWithRootObject:userEloData];
    NSError *error;
    NSData *encryptedData = [RNEncryptor encryptData:dataToSave
                                        withSettings:kRNCryptorAES256Settings
                                            password:MULTIPLAYER_SECRET
                                               error:&error];
    
    BOOL sucess = [encryptedData writeToFile:userEloPath atomically:YES];
    if (!sucess){
        NSLog(@"Erro ao Salvar arquivo de Vidas");
    }
    
    
}

+ (void)sendFiletoWebService{
    NSString *appDataDir = [AppUtils getAppDataDir];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    if ([[NSFileManager defaultManager] fileExistsAtPath:appDataDir] && [[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory]) {
        NSData *data = [NSData dataWithContentsOfFile:appDataDir];
        NSError *error;
        NSData *decryptedData = [RNDecryptor decryptData:data withPassword:USER_SECRET error:&error];
        if (!error){
            NSDictionary *obj = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            NSLog(@"File dict = %@",obj[@"facebookID"]);

            if ([self sendDataToWebService:obj]) {
                NSLog(@"Envio Data com sucesso !");
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"flagFacebook"];
            }
            if ([self sendPerformanceToWebService:obj]) {
                NSLog(@"Envio Performance com sucesso !");
            }
        }
    }
    else{
    }
}


+ (BOOL)sendDataToWebService:(NSDictionary*)object {

    NSError * erro = nil;

    NSString* name = [object[@"alias"] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];

    NSString* strUrl = [[NSString alloc]initWithFormat:@"http://fruitcatch-bepidproject.rhcloud.com/web/addUsuario/%@/%@/0/0/5/0/%@", object[@"facebookID"], name, object[@"facebookID"]];
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
    }else{
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"flagFacebook"];
    }

    return NO;
}

- (void)loadPerformanceFromWebService:(NSDictionary*)object{
    NSString *appDataDir = [AppUtils getAppDataDir];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSError *erro = nil;
    NSDictionary *dadosWebService = nil;
    int i = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:appDataDir] && [[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory]) {
        NSString* strUrl = [[NSString alloc]initWithFormat:@"http://fruitcatch-bepidproject.rhcloud.com/web/desempenho/%@",object[@"facebookID"]];
        NSLog(@"%@", strUrl);
        
        NSURL *url = [NSURL URLWithString:strUrl];
        NSData *dados = [[NSData alloc]initWithContentsOfURL:url];
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"lastCleared"];
        if (dados != nil) {
            dadosWebService = [NSJSONSerialization JSONObjectWithData:dados options:NSJSONReadingMutableContainers error:&erro];
        
            if (erro == nil && dadosWebService != nil) {
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *plistPath = [NSString stringWithFormat:@"%@/highscore.plist",documentsDirectory];
                NSMutableArray *array = [[NSMutableArray alloc]initWithContentsOfFile:plistPath];
                
                for (NSDictionary* dic in dadosWebService[@"desempenho"]) {
                    NSLog(@"%@",dic);

//                    [array addObject:dic];
                    if([dic[@"highScore"] integerValue] == 0){
                        break;
                    }
                    
                    [array replaceObjectAtIndex:i withObject:dic];
                    i++;
                    [[ClearedLevelsSingleton sharedInstance] updateLastLevel];
                }
                [array writeToFile:plistPath atomically:YES];
//                [[NSUserDefaults standardUserDefaults] setInteger:array.count-1 forKey:@"lastCleared"];

    //            [self saveScore];
            }
        }
       
    }
}

//-(void)saveScore
//{
//    //Carrega o score do plist
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *plistPath = [NSString stringWithFormat:@"%@/highscore.plist",documentsDirectory];
//    
//    NSMutableArray *array  = [NSMutableArray arrayWithContentsOfFile:plistPath];
//    
//    NSInteger level = [ClearedLevelsSingleton sharedInstance].lastLevelCleared;
//
//  //  NSMutableDictionary *levelHighScore = [[NSMutableDictionary alloc] initWithDictionary:[array objectAtIndex:level]];
//   // NSNumber *highScore = levelHighScore[@"HighScore"];
//    //NSNumber *tempo = levelHighScore[@"Time"];
//}

+ (BOOL)sendPerformanceToWebService:(NSDictionary*)object{
    NSError * erro = nil;

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *plistPath = [NSString stringWithFormat:@"%@/highscore.plist",documentsDirectory];
    long i = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastCleared"];
    NSDictionary *dic = nil;

    for (int aux = 0; aux < i; aux++) {
        plistPath = [NSString stringWithFormat:@"%@/highscore.plist",documentsDirectory];

        NSArray *array = [[NSArray alloc]initWithContentsOfFile:plistPath];
        
        dic = [[NSDictionary alloc] initWithDictionary:[array objectAtIndex:aux]];

        NSInteger score = [dic[@"highScore"] integerValue];
        NSInteger time = [dic[@"time"] integerValue];
        NSInteger stars = [dic[@"stars"] integerValue];
        
        NSString* strUrl = [[NSString alloc]initWithFormat:@"http://fruitcatch-bepidproject.rhcloud.com/web/addDesempenho/%@/%d/%ld/%d/%ld",object[@"facebookID"], aux, (long)time, stars, (long)score];
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
            if (aux == i)
                return YES;
        }
    }
    return  NO;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [self loadFromWebService];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([Nextpeer handleOpenURL:url]) {
        return YES;
    }
    
    // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
    BOOL wasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    
    // You can add your app-specific url handling code here if needed
    
    return wasHandled;
}


-(void)nextpeerDidTournamentStartWithDetails:(NPTournamentStartDataContainer *)tournamentContainer{
    
    MultiplayerGameViewController *multiGVC = [[MultiplayerGameViewController alloc]initWithNibName:nil bundle:nil];
    self.window.rootViewController = multiGVC;
    //[self.window.rootViewController dismissViewControllerAnimated:NO completion:nil];
    [[self.window.rootViewController presentingViewController] presentViewController:multiGVC animated:YES completion:nil];
     //[self.window makeKeyAndVisible];
}

- (void)nextpeerDidReceiveSynchronizedEvent:(NSString *)eventName withReason:(NPSynchronizedEventFireReason)fireReason{
    NSDictionary *parameters = @{@"eventName" : eventName,
                                 @"fireReason" : [NSNumber numberWithInt:fireReason]
                                 };
    [[NSNotificationCenter defaultCenter] postNotificationName:@"nextpeerDidReceiveSynchronizedEvent" object:nil userInfo:parameters];
}

-(void)nextpeerDidReceiveTournamentCustomMessage:(NPTournamentCustomMessageContainer*)message{
    NSLog(@"NextPeer Receive Custom Message");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"nextpeerDidReceiveTournamentCustomMessage" object:nil userInfo:@{@"userMessage" : message}];
}

-(void)nextpeerDidReceiveTournamentStatus:(NPTournamentStatusInfo*)tournamentStatus {
    NSArray *playersInfo = [tournamentStatus sortedResults];
    for (NPTournamentPlayerResults *playerResult in playersInfo) {
        if ((![playerResult isStillPlaying]) || ([playerResult didForfeit])){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"nextpeerreportForfeitForCurrentTournament" object:nil userInfo:@{@"userMessage" : tournamentStatus}];
        }
    }
}

@end
