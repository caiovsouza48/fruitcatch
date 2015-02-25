//
//  JIMCHelper.h
//  Fruit Catch
//
//  Created by Ítalo Araujo on 24/02/15.
//  Copyright (c) 2015 Caio de Souza. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RequestProductsCompletionHandler)(BOOL success, NSArray * products);

@interface JIMCHelper : NSObject

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;

@end
