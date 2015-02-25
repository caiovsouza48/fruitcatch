//
//  MessageWriter.m
//  CatRace
//
//  Created by Ray Wenderlich on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MessageWriter.h"

@implementation MessageWriter
@synthesize data = _data;

- (id)init {
    if ((self = [super init])) {
        _data = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)writeBytes:(void *)bytes length:(int)length {
    [_data appendBytes:bytes length:length];
}

- (void)writeByte:(unsigned char)value {
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeInt:(int)intValue {
    int value = htonl(intValue);
    [self writeBytes:&value length:sizeof(value)];
}

- (void)writeString:(NSString *)value {
    const char * utf8Value = [value UTF8String];
    int length = (int)strlen(utf8Value) + 1; // for null terminator
    [self writeInt:length];
    [self writeBytes:(void *)utf8Value length:length];
}


@end
