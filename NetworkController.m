//
//  NetworkController.m
//  Fruit Catch
//
//  Created by Ray Wenderlich on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NetworkController.h"
#import "MessageWriter.h"
#import "MessageReader.h"
#import "Match.h"
#import "Player.h"
#import <FacebookSDK/FacebookSDK.h>
#import "AppUtils.h"
#import "RNDecryptor.h"
#define USER_SECRET @"0x444F@c3b0ok"
#define HOST @"localhost"

@interface NetworkController (PrivateMethods)
- (BOOL)writeChunk;
@end

typedef enum {
    MessagePlayerConnected = 0,
    MessageNotInMatch,
    MessageStartMatch,
    MessageMatchStarted,
    MessageMovedSelf,
    MessagePlayerMoved,
    MessageGameOver,
    MessageRestartMatch,   
    MessageNotifyReady,
    MessageRandomFruit,
    MessageJogada,
    MessageLookingMatch
} MessageType;

@implementation NetworkController
@synthesize facebookAvailable = _facebookAvailable;
@synthesize userAuthenticated = _userAuthenticated;
@synthesize delegate = _delegate;
@synthesize state = _state;
@synthesize inputStream = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize inputOpened = _inputOpened;
@synthesize outputOpened = _outputOpened;
@synthesize inputBuffer = _inputBuffer;
@synthesize outputBuffer = _outputBuffer;
@synthesize okToWrite = _okToWrite;
@synthesize presentingViewController = _presentingViewController;
@synthesize mmvc = _mmvc;
@synthesize pendingInvite = _pendingInvite;
@synthesize pendingPlayersToInvite = _pendingPlayersToInvite;

#pragma mark - Helpers

static NetworkController *sharedController = nil;
+ (NetworkController *) sharedInstance {
    if (!sharedController) {
        sharedController = [[NetworkController alloc] init];
    }
    return sharedController;
}

- (void)inviteReceived{}

- (BOOL)isFacebookAvailable {
    NSLog(@"Facebook Session is %@", FBSession.activeSession.isOpen ? @"Open" : @"Closed");
    // check for presence of GKLocalPlayer API
    NSDictionary *obj=nil;
    NSString *appDataDir = [AppUtils getAppDataDir];
    if ([[NSFileManager defaultManager] fileExistsAtPath:appDataDir]) {
        NSData *data = [NSData dataWithContentsOfFile:appDataDir];
        NSError *error;
        NSData *decryptedData = [RNDecryptor decryptData:data withPassword:USER_SECRET error:&error];
        
        if (!error){
            obj = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
        }
    }
    return obj != nil;
}

- (void)setState:(NetworkState)state {
    _state = state;
    if (_delegate) {
        [_delegate stateChanged:_state];
    }
}

- (void)dismissMatchmaker {
    [_presentingViewController dismissViewControllerAnimated:YES completion:nil ];
    self.mmvc = nil;
    self.presentingViewController = nil;
}

#pragma mark - Init

- (id)init {
    if ((self = [super init])) {
        [self setState:_state];
        _facebookAvailable = [self isFacebookAvailable];
        if (_facebookAvailable) {
            NSNotificationCenter *nc = 
            [NSNotificationCenter defaultCenter];
            [nc addObserver:self 
                   selector:@selector(authenticationChanged) 
                       name:GKPlayerAuthenticationDidChangeNotificationName 
                     object:nil];
        }
    }
    return self;
}

#pragma mark - Message sending / receiving

- (void)sendData:(NSData *)data {
    
    if (_outputBuffer == nil) return;
    
    int dataLength = (int)data.length;
    dataLength = htonl(dataLength);
    [_outputBuffer appendBytes:&dataLength length:sizeof(dataLength)];
    [_outputBuffer appendData:data];
    if (_okToWrite) {
        [self writeChunk];
        NSLog(@"Wrote message");
    } else {
        NSLog(@"Queued message");
    }
}

- (void)sendPlayerConnected:(BOOL)continueMatch {
    [self setState:NetworkStatePendingMatchStatus];
    
    MessageWriter * writer = [[MessageWriter alloc] init];
    [writer writeByte:MessagePlayerConnected];
    [writer writeString:[GKLocalPlayer localPlayer].playerID];
    [writer writeString:[GKLocalPlayer localPlayer].alias];
    [writer writeByte:continueMatch];
    [self sendData:writer.data];
}

- (void)sendRandomFruit{
    MessageWriter *writer = [[MessageWriter alloc] init];
    [writer writeByte:MessageRandomFruit];
    [self sendData:writer.data];
}

- (void)sendStartMatch:(NSArray *)players {
    [self setState:NetworkStatePendingMatchStart];
    
    MessageWriter * writer = [[MessageWriter alloc] init];
    [writer writeByte:MessageStartMatch];
    [writer writeByte:players.count];
    for(NSString *playerId in players) {
        [writer writeString:playerId];
    }
    [self sendData:writer.data];    
}

- (void)sendMovedSelf:(int)posX {
    
    MessageWriter * writer = [[MessageWriter alloc] init];
    [writer writeByte:MessageMovedSelf];
    [writer writeInt:posX];
    [self sendData:writer.data];
    
}

- (void)sendRestartMatch {
    MessageWriter * writer = [[MessageWriter alloc] init];
    [writer writeByte:MessageRestartMatch];
    [self sendData:writer.data];
}

- (void)sendNotifyReady:(NSString *)inviter {
    MessageWriter * writer = [[MessageWriter alloc] init];
    [writer writeByte:MessageNotifyReady];
    [writer writeString:inviter];
    [self sendData:writer.data];
}

- (void)processMessage:(NSData *)data {
    MessageReader * reader = [[MessageReader alloc] initWithData:data];
    
    unsigned char msgType = [reader readByte];
    if (msgType == MessageNotInMatch) {
        [self setState:NetworkStateReceivedMatchStatus];
        [_delegate setNotInMatch];
    } else if (msgType == MessageMatchStarted) {
        [self setState:NetworkStateMatchActive];
        [self dismissMatchmaker]; 
        unsigned char matchState = [reader readByte];
        NSMutableArray * players = [NSMutableArray array];
        unsigned char numPlayers = [reader readByte];
        for(unsigned char i = 0; i < numPlayers; ++i) {
            NSString *playerId = [reader readString];
            NSString *alias = [reader readString];
//            int posX = [reader readInt];
            Player *player = [[Player alloc] initWithPlayerId:playerId alias:alias];
            [players addObject:player];
        }
        Match * match = [[Match alloc] initWithState:matchState players:players];
       [_delegate matchStarted:match];
    } else if (msgType == MessageJogada &&  _state == NetworkStateMatchActive){
        //unsigned char playerIndex = [reader readByte];
        //JIMCCoord coords = JIMCCoordMake([reader readInt], [reader readInt]);
        
//    } else if (msgType == MessagePlayerMoved && _state == NetworkStateMatchActive) {
//        unsigned char playerIndex = [reader readByte];
//        int posX = [reader readInt];
//        [_delegate player:playerIndex movedToPosX:posX];
    } else if (msgType == MessageGameOver && _state == NetworkStateMatchActive) {
        unsigned char winnerIndex = [reader readByte];
        [_delegate gameOver:winnerIndex];
    } else if (msgType == MessageNotifyReady) {
        NSString *playerId = [reader readString];
        NSLog(@"Player %@ ready", playerId);
        if (_mmvc != nil) {
            
//            [GKPlayer loadPlayersForIdentifiers:@[playerId] withCompletionHandler:^(NSArray *players,NSError *error){
//                for (GKPlayer *player in players) {
//                    [_mmvc setHostedPlayer:player didConnect:YES];
//                }
//            }];
            //[_mmvc setHostedPlayer:[GKPlayer all] didConnect:<#(BOOL)#>]
           // [_mmvc setHostedPlayerReady:playerId];
        }
    }
}

#pragma mark - Server communication

- (void)connect {    
    
    self.inputBuffer = [NSMutableData data];
    self.outputBuffer = [NSMutableData data];
    
    [self setState:NetworkStateConnectingToServer];
       
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStringRef hst = CFSTR("localhost");
    CFStreamCreatePairWithSocketToHost(NULL, hst, 1955, &readStream, &writeStream);
    _inputStream = (__bridge NSInputStream *)readStream;
    _outputStream = (__bridge NSOutputStream *)writeStream;
   
    [_inputStream setDelegate:self];
    [_outputStream setDelegate:self];
    [_inputStream setProperty:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];
    [_outputStream setProperty:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_inputStream open];
    [_outputStream open];
    NSError *writeError = [_inputStream streamError];
    NSLog(@"error = %@",writeError.localizedDescription);
    //NSLog(@"error = %@",writeError.localizedDescription);
}

- (void)disconnect {
    
    [self setState:NetworkStateConnectingToServer];
    
    if (_inputStream != nil) {
        self.inputStream.delegate = nil;
        [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_inputStream close];
        self.inputStream = nil;
        self.inputBuffer = nil;
    } 
    if (_outputStream != nil) {
        self.outputStream.delegate = nil;
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream close];
        self.outputStream = nil;
        self.outputBuffer = nil;
    }
}

- (void)reconnect {
    [self disconnect];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self connect];
    });
}

- (void)checkForMessages {
    while (true) {
        if (_inputBuffer.length < sizeof(int)) {
            return;
        }
        
        int msgLength = *((int *) _inputBuffer.bytes);
        msgLength = ntohl(msgLength);
        if (_inputBuffer.length < msgLength) {
            return;
        }
        
        NSData * message = [_inputBuffer subdataWithRange:NSMakeRange(4, msgLength)];
        [self processMessage:message];
        
        int amtRemaining = (int)_inputBuffer.length - msgLength - sizeof(int);
        if (amtRemaining == 0) {
            self.inputBuffer = [[NSMutableData alloc] init];
        } else {
            NSLog(@"Creating input buffer of length %d", amtRemaining);
            self.inputBuffer = [[NSMutableData alloc] initWithBytes:_inputBuffer.bytes+4+msgLength length:amtRemaining];
        }        
        
    }
}

- (void)inputStreamHandleEvent:(NSStreamEvent)eventCode {
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            NSLog(@"Opened input stream");
            _inputOpened = YES;
            if (_inputOpened && _outputOpened && _state == NetworkStateConnectingToServer) {
                [self setState:NetworkStateConnected];
                BOOL continueMatch = _pendingInvite == nil;
                [self sendPlayerConnected:continueMatch];
            }
        } 
        case NSStreamEventHasBytesAvailable: {                       
            if ([_inputStream hasBytesAvailable]) {                
                NSLog(@"Input stream has bytes...");
                // TODO: Read bytes   
                NSInteger       bytesRead;
                uint8_t         buffer[32768];

                bytesRead = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                if (bytesRead == -1) {
                    NSLog(@"Network read error");
                } else if (bytesRead == 0) {
                    NSLog(@"No data read, reconnecting");
                    [self reconnect];
                } else {                
                    NSLog(@"Read %ld bytes", (long)bytesRead);
                    [_inputBuffer appendData:[NSData dataWithBytes:buffer length:bytesRead]];
                    [self checkForMessages];
                }
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO); // should never happen for the input stream
        } break;
        case NSStreamEventErrorOccurred: {
            
            NSLog(@"Stream open error, reconnecting");
            [self reconnect];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }    
}

- (BOOL)writeChunk {
    int amtToWrite = (int)MIN(_outputBuffer.length, 1024);
    if (amtToWrite == 0) return FALSE;
    
    NSLog(@"Amt to write: %d/%lu", amtToWrite, (unsigned long)_outputBuffer.length);
    
    int amtWritten = (int)[self.outputStream write:_outputBuffer.bytes maxLength:amtToWrite];
    if (amtWritten < 0) {
        [self reconnect];
    }
    int amtRemaining = (int)_outputBuffer.length - amtWritten;
    if (amtRemaining == 0) {
        self.outputBuffer = [NSMutableData data];
    } else {
        NSLog(@"Creating output buffer of length %d", amtRemaining);
        self.outputBuffer = [NSMutableData dataWithBytes:_outputBuffer.bytes+amtWritten length:amtRemaining];
    }
    NSLog(@"Wrote %d bytes, %d remaining.", amtWritten, amtRemaining);
    _okToWrite = FALSE;
    return TRUE;
}

- (void)outputStreamHandleEvent:(NSStreamEvent)eventCode {            
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            NSLog(@"Opened output stream");
            _outputOpened = YES;
            if (_inputOpened && _outputOpened && _state == NetworkStateConnectingToServer) {
                [self setState:NetworkStateConnected];
                // TODO: Send message to server
                BOOL continueMatch = _pendingInvite == nil;
                [self sendPlayerConnected:continueMatch];
            }
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"Ok to send");
            // TODO: Write bytes
            BOOL wroteChunk = [self writeChunk];
            if (!wroteChunk) {
                _okToWrite = TRUE;
            }
        } break;
        case NSStreamEventErrorOccurred: {
            NSLog(@"Stream open error, reconnecting");
            [self reconnect];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode { 
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (aStream == _inputStream) {
            [self inputStreamHandleEvent:eventCode];
        } else if (aStream == _outputStream) {
            [self outputStreamHandleEvent:eventCode];
        }
    });
}

#pragma mark - Authentication
- (void)authenticationChanged {    
    
    if ([self isFacebookAvailable] && !_userAuthenticated) {
        NSLog(@"Authentication changed: player authenticated.");
        [self setState:NetworkStateAuthenticated];
        _userAuthenticated = TRUE; 
//        [GKMatchmaker sharedMatchmaker].inviteHandler = ^(GKInvite *acceptedInvite, NSArray *playersToInvite) {            
//            NSLog(@"Received invite");
//            self.pendingInvite = acceptedInvite;
//            self.pendingPlayersToInvite = playersToInvite;
//            
//            if (_state >= NetworkStateConnected) {
//                [self setState:NetworkStateReceivedMatchStatus];
//                [_delegate setNotInMatch];
//            }
//            
//        };
        
        [self connect];
    } else if ([self isFacebookAvailable] && _userAuthenticated) {
        NSLog(@"Authentication changed: player not authenticated");
        _userAuthenticated = FALSE;
        [self setState:NetworkStateNotAvailable];
        [self disconnect];
    }
    
}

- (void)authenticateLocalUser {
    
    //GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    //BOOL authenticated = [localPlayer isAuthenticated];
    //localPlayer.authenticateHandler = ^(UIViewController *viewController,NSError *error) {
    if ([self isFacebookAvailable]) {
        NSLog(@"Already authenticated!");
    } else
        [self setState:NetworkStatePendingAuthentication];
        FBSession *session = [[FBSession alloc] initWithPermissions:@[@"public_profile",@"email"]];
        [FBSession setActiveSession:session];
        if([FBSession openActiveSessionWithAllowLoginUI:YES]) {
          NSLog(@"Already Authenticated");
        } else {
          NSLog(@"Login Fail");
        // you need to log the user
    }
    
    //problem with authentication,probably bc the user doesn't use Game Center
//    NSLog(@"Authenticating local user...");
//    if ([GKLocalPlayer localPlayer].authenticated == NO) {
//        [self setState:NetworkStatePendingAuthentication];
//        //[[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:nil];
//    } else {
//        NSLog(@"Already authenticated!");
//    }
}

- (void) sendPlayerLookingforMatch:(NSString *)playerID PlayerAlias:(NSString *)playerAlias{
    MessageWriter *writer = [[MessageWriter alloc]init];
    [writer writeByte:MessageLookingMatch];
    [writer writeString:playerID];
    [writer writeString:playerAlias];
    [self sendData:writer.data];
    
    
}


#pragma mark - Matchmaking

- (void)findMatchWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers
                 viewController:(UIViewController *)viewController {
     [self connect];
    if (!_facebookAvailable) return;
    
    [self setState:NetworkStatePendingMatch];
    
    self.presentingViewController = viewController;
    [_presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSString *appDataDir = [AppUtils getAppDataDir];
    if ([[NSFileManager defaultManager] fileExistsAtPath:appDataDir]) {
        NSData *data = [NSData dataWithContentsOfFile:appDataDir];
        NSError *error;
        NSData *decryptedData = [RNDecryptor decryptData:data withPassword:USER_SECRET error:&error];
        if (!error){
            NSDictionary *userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            NSLog(@"userInfo = %@",userInfo);
            NSString *facebookID = userInfo[@"facebookID"];
            NSString *alias = userInfo[@"alias"];
            [self sendPlayerLookingforMatch:facebookID PlayerAlias:alias];
            
        }
        else{
            NSLog(@"Fail to Get User Info");
        }
    }

    //[self sendPlayerLookingforMatch];
    
//    if (_pendingInvite != nil) {
//        
//        [self sendNotifyReady:_pendingInvite.sender.alias];
//        
//        self.mmvc = [[GKMatchmakerViewController alloc] initWithInvite:_pendingInvite];
//        _mmvc.hosted = YES;
//        _mmvc.matchmakerDelegate = self;
//        
//        [_presentingViewController presentViewController:_mmvc animated:YES completion:nil];
//        self.pendingInvite = nil;
//        self.pendingPlayersToInvite = nil;
    
//    } else {
//        GKMatchRequest *request = [[GKMatchRequest alloc] init];
//        request.minPlayers = minPlayers;     
//        request.maxPlayers = maxPlayers;
//        
//        self.mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
//        _mmvc.hosted = YES;
//        _mmvc.matchmakerDelegate = self;
    
      //  [_presentingViewController presentViewController:_mmvc animated:YES completion:nil];
}


// The user has cancelled matchmaking
- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
    NSLog(@"matchmakerViewControllerWasCancelled");
    [self dismissMatchmaker];
}

// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError: %@", error.localizedDescription);
    [self dismissMatchmaker];
}

// Players have been found for a server-hosted game, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindPlayers:(NSArray *)playerIDs {
    NSLog(@"didFindPlayers");
    for (NSString *playerID in playerIDs) {
        NSLog(@"%@", playerID);
    }        
    if (_state == NetworkStatePendingMatch) {
        [self dismissMatchmaker]; 
        // TODO: Send message to server to start match, with given player Ids
        [self sendStartMatch:playerIDs];
    }
}

// An invited player has accepted a hosted invite.  Apps should connect through the hosting server and then update the player's connected state (using setConnected:forHostedPlayer:)
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didReceiveAcceptFromHostedPlayer:(NSString *)playerID __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0) {
    NSLog(@"didReceiveAcceptFromHostedPlayer");    
}

@end
