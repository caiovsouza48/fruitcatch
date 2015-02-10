//
//  PowerUP.m
//  Fruit Catch
//
//  Created by max do nascimento on 06/02/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import "PowerUP.h"

@implementation PowerUP
-(instancetype)initWithPosition:(CGPoint)position{
    self = [super initWithImageNamed:@"fazendeiro"];
    if (self) {
        self.position = position;

    }
    return self;
}
@end
