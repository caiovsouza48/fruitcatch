//
//  UILabel+JDFTooltips.h
//  JoeTooltips
//
//  Created by Joe Fryer on 13/11/2014.
//  Copyright (c) 2014 Joe Fryer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (JDFTooltips)

- (void)jdftt_resizeHeightToFitTextContents;
- (void)jdftt_resizeWidthToFitTextContents;
- (CGFloat)jdftt_requiredHeightToFitContents;
- (CGFloat)jdftt_requiredWidthToFitContents;

@end
// Copyright belongs to original author
// http://code4app.net (en) http://code4app.com (cn)
// From the most professional code share website: Code4App.net