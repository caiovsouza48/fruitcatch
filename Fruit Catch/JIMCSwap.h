#import <Foundation/Foundation.h>
@class JIMCFruit;

@interface JIMCSwap : NSObject

@property (strong, nonatomic) JIMCFruit *fruitA;
@property (strong, nonatomic) JIMCFruit *fruitB;
@property (nonatomic) BOOL vertical;
@end
