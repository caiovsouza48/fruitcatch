//
//  NextpeerHelper.m
//  Fruit Catch
//
//  Created by Caio de Souza on 20/02/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import "NextpeerHelper.h"

@implementation NextpeerHelper

+ (void)sendMessageOfType:(NPFruitCatchMessage)messageType{
    NSDictionary *message = @{@"type" : [NSNumber numberWithInt:messageType]};
    NSData *dataPacket = [NSPropertyListSerialization dataWithPropertyList:message format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
    [Nextpeer pushDataToOtherPlayers:dataPacket];


}

+ (void)sendMessageOfType:(NPFruitCatchMessage)messageType DictionaryData:(NSDictionary *)data{
    NSMutableDictionary *tempMutableDictionary = [NSMutableDictionary dictionary];
    NSLog(@"Ditionary Data: %@",data);
    NSDictionary *message = @{@"type" : [NSNumber numberWithInt:messageType]};
    [tempMutableDictionary addEntriesFromDictionary:message];
    [tempMutableDictionary addEntriesFromDictionary:data];
    
      NSData *dataPacket = [NSPropertyListSerialization dataWithPropertyList:tempMutableDictionary format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
      [Nextpeer pushDataToOtherPlayers:dataPacket];

}




@end
