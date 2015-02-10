//
//  kFactor.m
//  Fruit Catch
//
//  Created by Caio de Souza on 06/02/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import "kFactor.h"


@implementation kFactor


- (id) initWithStartIndex:(int)startIndex EndIndex:(int)endIndex Value:(float)value{
    self = [super init];
    
    if (self){
        self.startIndex = startIndex;
        self.endIndex = endIndex;
        self.value = value;
    }
    return self;
}

- (id)initWithDefaultString:(NSString *)defaultString{
    self = [super init];
    if (self){
        NSArray *splittedValueString = [defaultString componentsSeparatedByCharactersInSet:
                                         [NSCharacterSet characterSetWithCharactersInString:@"-="]];
        self.startIndex = [splittedValueString[0] intValue];
        self.endIndex = [splittedValueString[1] intValue];
        self.value = [splittedValueString[2] intValue];
    }
    return self;
}


+ (NSArray *)getDefaultKfactorValues{
    return @[@"0-2099=24",@"2100-2399=16",@"2490-3000=8"];
}

+ (NSArray *)getDefaults{
    
    NSMutableArray *defaults = [NSMutableArray array];
    for (NSString *defaultValueString in [kFactor getDefaultKfactorValues]) {
        kFactor *defaultKFactor = [[kFactor alloc]initWithDefaultString:defaultValueString];
        [defaults addObject:defaultKFactor];
    }
    return defaults;
}


- (NSString *)description{
    return [NSString stringWithFormat:@"kfactor: /nStartIndex:%d/nEndIndex = %d/nValue=%f",self.startIndex,self.endIndex,self.value];
}

@end
