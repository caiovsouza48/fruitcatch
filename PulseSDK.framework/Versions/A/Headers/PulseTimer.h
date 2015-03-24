//
//  PulseTimer.h
//  PulseSDK
//
//  Created by Robert Menke on 7/11/14.
//  Copyright (c) 2014 Pulse.IO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PulseTimer : NSObject

/*!
 * @abstract Stop and report a timer.
 *
 * @discussion This call be be used instead of [PulseSDK stopTimer:@"MyName"]
 *   if you have several timers with the same name running simultaneously.
 *
 */

- (void)stop;

@end
