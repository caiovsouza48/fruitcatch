//
//  NetworkController.h
//  CatRace
//
//  Created by Ray Wenderlich on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

//
//typedef struct{
//    int x;
//    int y;
//}JIMCCoord;
//
//JIMCCoord JIMCCoordMake(int x,int y){
//    JIMCCoord coord;
//    coord.x = x;
//    coord.y = y;
//    return coord;
//}

typedef enum {
    NetworkStateNotAvailable,
    NetworkStatePendingAuthentication,
    NetworkStateAuthenticated,    
    NetworkStateConnectingToServer,
    NetworkStateConnected,
    NetworkStatePendingMatchStatus,
    NetworkStateReceivedMatchStatus,
    NetworkStatePendingMatch,
    NetworkStatePendingMatchStart,
    NetworkStateMatchActive,
} NetworkState;

@class Match;

@protocol NetworkControllerDelegate
- (void)stateChanged:(NetworkState)state;
- (void)setNotInMatch;
- (void)matchStarted:(Match *)match;
- (void)player:(unsigned char)playerIndex movedToPosX:(int)posX;
- (void)gameOver:(unsigned char)winnerIndex;
@end

@interface NetworkController : NSObject <NSStreamDelegate, GKMatchmakerViewControllerDelegate> {
    BOOL _gameCenterAvailable;
    BOOL _userAuthenticated;
    id <NetworkControllerDelegate> _delegate;
    NetworkState _state;
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
    BOOL _inputOpened;
    BOOL _outputOpened;
    NSMutableData *_outputBuffer;
    NSMutableData *_inputBuffer;
    BOOL _okToWrite;
    UIViewController *_presentingViewController;
    GKMatchmakerViewController *_mmvc;
    GKInvite *_pendingInvite;
    NSArray *_pendingPlayersToInvite;    
}

@property (assign, readonly) BOOL facebookAvailable;
@property (assign, readonly) BOOL userAuthenticated;
@property  id <NetworkControllerDelegate> delegate;
@property (assign, readonly) NetworkState state;
@property (retain) NSInputStream *inputStream;
@property (retain) NSOutputStream *outputStream;
@property (assign) BOOL inputOpened;
@property (assign) BOOL outputOpened;
@property (retain) NSMutableData *outputBuffer;
@property (retain) NSMutableData *inputBuffer;
@property (assign) BOOL okToWrite;
@property (retain) UIViewController *presentingViewController;
@property (retain) GKMatchmakerViewController *mmvc;
@property (retain) GKInvite *pendingInvite;
@property (retain) NSArray *pendingPlayersToInvite;

+ (NetworkController *)sharedInstance;
- (void)authenticateLocalUser;
- (void)findMatchWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers 
                 viewController:(UIViewController *)viewController;
- (void)sendMovedSelf:(int)posX;
- (void)sendRestartMatch;
- (void)inviteReceived;

@end
