//
//  main.m
//  Fruit Catch
//
//  Created by Caio de Souza on 24/11/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PulseSDK/PulseSDK.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        [PulseSDK monitor:@"r54nalwMy_nbuZqM7hUtDPnKCRkyypGr"];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
