//
//  NextpeerHelper.h
//  Fruit Catch
//
//  Created by Caio de Souza on 20/02/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Nextpeer/Nextpeer.h>

typedef NS_ENUM(NSInteger, NPFruitCatchMessage){
    NPFruitCatchMessageSendLevel = 0,
    NPFruitCatchMessageSendRandomNumber,
    NPFruitCatchMessageBeginGame,
    NPFruitCatchMessageEventOver,
    NPFruitCatchMessageMove,
    NPFruitCatchMessageGameOver
    
};

@interface NextpeerHelper : NSObject

+ (void)sendMessageOfType:(NPFruitCatchMessage)message;

+ (void)sendMessageOfType:(NPFruitCatchMessage)message DictionaryData:(NSDictionary *)data;

@end
