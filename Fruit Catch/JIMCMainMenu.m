//
//  JIMCMainMenu.m
//  Fruit Catch
//
//  Created by max do nascimento on 16/12/14.
//  Copyright (c) 2014 Caio de Souza. All rights reserved.
//

#import "JIMCMainMenu.h"

@implementation JIMCMainMenu{

    SKSpriteNode *backgroundNode;

}
-(id)initWithSize:(CGSize)size{
    if(self = [super initWithSize:size]){
       
        [self setupBackground];
  
        
        
    }
    return self;
    
}
-(void) setupBackground {
    backgroundNode = [SKSpriteNode spriteNodeWithImageNamed:@"Agrupar-1.png"];
    [backgroundNode setSize:self.frame.size];
    backgroundNode.position = CGPointMake(CGRectGetMinX(self.frame) + backgroundNode.size.width / 2, CGRectGetMinY(self.frame) + backgroundNode.size.height / 2);
    backgroundNode.zPosition = -4;
    [self addChild:backgroundNode];
}
@end
