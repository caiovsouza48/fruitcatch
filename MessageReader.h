//
//  MessageReader.h
//  CatRace
//
//  Created by Ray Wenderlich on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageReader : NSObject {
    NSData * _data;
    int _offset;
}

- (id)initWithData:(NSData *)data;

- (unsigned char)readByte;
- (int)readInt;
- (NSString *)readString;

@end
