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
#import "AppUtils.h"

#define NEXTPEER_KEY @"08d8f6a9b74c70e157add51c12c7d272"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)nextpeerDidTournamentEnd{

}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [JIMCAPHelper sharedInstance];
    
    NSInteger numberOfLevels = 10;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[AppUtils getAppMultiplayer]]){
        [self setUserElo];
    }
    //Checa se é o primeiro uso, caso seja, libera apenas o primeiro nível
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"hasPlayed"])
    {
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasPlayed"];
        [[NSUserDefaults standardUserDefaults] setInteger:(-1) forKey:@"lastCleared"];
        [[ClearedLevelsSingleton sharedInstance] updateLastLevel];
        
        NSMutableArray *array = [[NSMutableArray alloc]init];
        for(int i=0; i<numberOfLevels; i++){
            NSDictionary *dic = [[NSDictionary alloc] initWithObjects:@[@0,@0] forKeys:@[@"Time",@"HighScore"]];
            
            [array addObject:dic];
        }
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *plistPath = [NSString stringWithFormat:@"%@/highscore.plist",documentsDirectory];
        
        [array writeToFile:plistPath atomically:YES];
        
    }
    
    //[[NetworkController sharedInstance] authenticateLocalUser];
    // Override point for customization after application launch.
    [FBLoginView class];
    //EloRating *eloRating = [[EloRating alloc]init];
//    int userRating = 1600;
//    int opponentRating = 1650;
//    int newUserRating = [eloRating getNewRating:userRating OpponentRating:opponentRating GameResult:WIN];
//    int newOpponent = [eloRating getNewRating:opponentRating OpponentRating:userRating GameResult:LOSS];
//    NSLog(@"New User Rating = %d",newUserRating);
//    NSLog(@"New Opponent Rating = %d",newOpponent);
    [[UIApplication sharedApplication]setStatusBarHidden:YES ];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"Launch"];
    [Nextpeer initializeWithProductKey:NEXTPEER_KEY andDelegates:[NPDelegatesContainer containerWithNextpeerDelegate:self]];
    return YES;
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

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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
    
    // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
    BOOL wasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    
    // You can add your app-specific url handling code here if needed
    
    return wasHandled;
}
-(void)nextpeerDidTournamentStartWithDetails:(NPTournamentStartDataContainer *)tournamentContainer{
    MultiplayerGameViewController *multiGVC = [[MultiplayerGameViewController alloc]init];
    [self.window.rootViewController presentViewController:multiGVC animated:YES completion:nil];
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
            NSLog(@"Player Saiu");
            [Nextpeer reportForfeitForCurrentTournament];
        }
    }
}

@end
