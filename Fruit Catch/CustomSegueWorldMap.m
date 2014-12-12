//  Created by Phillipus on 19/09/2013.
//  Copyright (c) 2013 Dada Beatnik. All rights reserved.
//

#import "CustomSegueWorldMap.h"

@implementation CustomSegueWorldMap

- (void)perform {
    UIView *source = ((UIViewController *)self.sourceViewController).view;
    UIView *destination = ((UIViewController *)self.destinationViewController).view;
    
    destination.transform = CGAffineTransformMakeScale(0.05, 0.05);
    
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    destination.center = CGPointMake(destination.center.x, destination.center.y);
    [window insertSubview:destination aboveSubview:source];
    
    [UIView animateWithDuration:0.5
                     animations:^{
//                         destination.center = CGPointMake(source.center.x, destination.center.y);
//                         source.center = CGPointMake(0 - source.center.x, destination.center.y);
     
//                         destination.transform = CGAffineTransformMakeRotation(M_PI);
//                         destination.transform = CGAffineTransformMakeRotation(0);
                         
                         destination.transform = CGAffineTransformMakeScale(1.0, 1.0);
                     }
                     completion:^(BOOL finished){
                         destination.transform = CGAffineTransformMakeRotation(0);
                         [[self sourceViewController] presentViewController:[self destinationViewController] animated:NO completion:nil];
                     }];
}

@end
