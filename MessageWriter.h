//
//  MessageWriter.h
//  CatRace
//
//  Created by Ray Wenderlich on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageWriter : NSObject {
    NSMutableData * _data;
}

@property (retain, readonly) NSMutableData * data;

- (void)writeByte:(unsigned char)value;
- (void)writeInt:(int)value;
- (void)writeString:(NSString *)value;

@end
