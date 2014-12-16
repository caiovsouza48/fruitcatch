#import <UIKit/UIKit.h>

@interface CustomSegueSinglePlayer : UIStoryboardSegue

@property (nonatomic) CGFloat xPosition;
@property (nonatomic) CGFloat yPosition;

-(void) setXPosition:(CGFloat)xPos yPosition:(CGFloat)yPos;

@end
