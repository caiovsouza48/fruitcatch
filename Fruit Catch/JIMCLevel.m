
#import "JIMCLevel.h"
#import "GameViewController.h"
@interface JIMCLevel ()

// The list of swipes that result in a valid swap. Used to determine whether
// the player can make a certain swap, whether the board needs to be shuffled,
// and to generate hints.
@property (strong, nonatomic) NSSet *possibleSwaps;

// The second chain gets twice its regular score, the third chain three times,
// and so on. This multiplier is reset for every next turn.
@property (assign, nonatomic) NSUInteger comboMultiplier;
@property (strong, nonatomic) GameViewController *gameView;
@end

@implementation JIMCLevel {
    // The 2D array that contains the layout of the level.
    JIMCTile *_tiles[NumColumns][NumRows];
    
    // The 2D array that keeps track of where the JIMCFruits are.
    JIMCFruit *_fruits[NumColumns][NumRows];
}

#pragma mark - Level Loading

- (instancetype)initWithFile:(NSString *)filename {
    self = [super init];
    if (self != nil) {
        NSDictionary *dictionary = [self loadJSON:filename];
        
        // The dictionary contains an array named "tiles". This array contains one
        // element for each row of the level. Each of those row elements in turn is
        // also an array describing the columns in that row. If a column is 1, it
        // means there is a tile at that location, 0 means there is not.
        
        // Loop through the rows...
        [dictionary[@"tiles"] enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger row, BOOL *stop) {
            
            // Loop through the columns in the current row...
            [array enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger column, BOOL *stop) {
                
                // Note: In Sprite Kit (0,0) is at the bottom of the screen,
                // so we need to read this file upside down.
                NSInteger tileRow = NumRows - row - 1;
                
                // If the value is 1, create a tile object.
                if ([value integerValue] == 1) {
                    _tiles[column][tileRow] = [[JIMCTile alloc] init];
                }
            }];
        }];
        
        self.targetScore = [dictionary[@"targetScore"] unsignedIntegerValue];
        self.maximumMoves = [dictionary[@"moves"] unsignedIntegerValue];
    }
    return self;
}

- (NSDictionary *)loadJSON:(NSString *)filename {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    if (path == nil) {
        NSLog(@"Could not find level file: %@", filename);
        return nil;
    }
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if (data == nil) {
        NSLog(@"Could not load level file: %@, error: %@", filename, error);
        return nil;
    }
    
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (dictionary == nil || ![dictionary isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Level file '%@' is not valid JSON: %@", filename, error);
        return nil;
    }
    
    return dictionary;
}

#pragma mark - Game Setup

- (NSSet *)shuffle {
    NSSet *set;
    
    do {
        // Removes the old fruits and fills up the level with all new ones.
        set = [self createInitialFruits];
        
        // At the start of each turn we need to detect which fruits the player can
        // actually swap. If the player tries to swap two fruits that are not in
        // this set, then the game does not accept this as a valid move.
        // This also tells you whether no more swaps are possible and the game needs
        // to automatically reshuffle.
        [self detectPossibleSwaps];
        
        //NSLog(@"possible swaps: %@", self.possibleSwaps);
        
        // If there are no possible moves, then keep trying again until there are.
    }
    while ([self.possibleSwaps count] == 0);
   
    return set;
}

- (NSSet *)createInitialFruits {
    
    NSMutableSet *set = [NSMutableSet set];
    
    // Loop through the rows and columns of the 2D array. Note that column 0,
    // row 0 is in the bottom-left corner of the array.
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            
            // Only make a new fruit if there is a tile at this spot.
            if (_tiles[column][row] != nil) {
                
                // Pick the fruit type at random, and make sure that this never
                // creates a chain of 3 or more. We want there to be 0 matches in
                // the initial state.
                NSUInteger fruitType;
                do {
                    fruitType = arc4random_uniform(NumFruitTypes) + 1;
                }
                while ((column >= 2 &&
                        _fruits[column - 1][row].fruitType == fruitType &&
                        _fruits[column - 2][row].fruitType == fruitType)
                       ||
                       (row >= 2 &&
                        _fruits[column][row - 1].fruitType == fruitType &&
                        _fruits[column][row - 2].fruitType == fruitType));
                
                // Create a new fruit and add it to the 2D array.
                JIMCFruit *fruit = [self createFruitAtColumn:column row:row withType:fruitType];
                
                // Also add the fruit to the set so we can tell our caller about it.
                [set addObject:fruit];
            }
        }
    }
    return set;
}

- (JIMCFruit *)createFruitAtColumn:(NSInteger)column row:(NSInteger)row withType:(NSUInteger)fruitType {
    JIMCFruit *fruit = [[JIMCFruit alloc] init];
    fruit.fruitType = fruitType;
    fruit.column = column;
    fruit.row = row;
    _fruits[column][row] = fruit;

    return fruit;
}

- (void)resetComboMultiplier {
    self.comboMultiplier = 1;
}

#pragma mark - Detecting Swaps

- (NSSet *)detectPossibleSwaps {
    
    NSMutableSet *set = [NSMutableSet set];
   
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            
            JIMCFruit *fruit = _fruits[column][row];
            if (fruit != nil) {
                
                // Is it possible to swap this fruit with the one on the right?
                // Note: don't need to check the last column.
                if (column < NumColumns - 1) {
                    
                    // Have a fruit in this spot? If there is no tile, there is no fruit.
                    JIMCFruit *other = _fruits[column + 1][row];
                    if (other != nil) {
                        // Swap them
                        _fruits[column][row] = other;
                        _fruits[column + 1][row] = fruit;
                        
                        // Is either fruit now part of a chain?
                        if ([self hasChainAtColumn:column + 1 row:row] ||
                            [self hasChainAtColumn:column row:row]) {
                            
                            JIMCSwap *swap = [[JIMCSwap alloc] init];
                            swap.fruitA = fruit;
                            swap.fruitB = other;
                            [set addObject:swap];
                        }
                        
                        // Swap them back
                        _fruits[column][row] = fruit;
                        _fruits[column + 1][row] = other;
                    }
                }
                
                // Is it possible to swap this fruit with the one above?
                // Note: don't need to check the last row.
                if (row < NumRows - 1) {
                    
                    // Have a fruit in this spot? If there is no tile, there is no fruit.
                    JIMCFruit *other = _fruits[column][row + 1];
                    if (other != nil) {
                        // Swap them
                        _fruits[column][row] = other;
                        _fruits[column][row + 1] = fruit;
                        
                        // Is either fruit now part of a chain?
                        if ([self hasChainAtColumn:column row:row + 1] ||
                            [self hasChainAtColumn:column row:row]) {
                            
                            JIMCSwap *swap = [[JIMCSwap alloc] init];
                            swap.fruitA = fruit;
                            swap.fruitB = other;
                            [set addObject:swap];
                        }
                        
                        // Swap them back
                        _fruits[column][row] = fruit;
                        _fruits[column][row + 1] = other;
                    }
                }
            }
        }
    }
    
    
    
    //[self removeFruits:set2];
 
    
    self.possibleSwaps = set;
    
    return set;
}

- (BOOL)hasChainAtColumn:(NSInteger)column row:(NSInteger)row {
    NSUInteger fruitType = _fruits[column][row].fruitType;
    
    NSUInteger horzLength = 1;
    for (NSInteger i = column - 1; i >= 0 && _fruits[i][row].fruitType == fruitType; i--, horzLength++) ;
    for (NSInteger i = column + 1; i < NumColumns && _fruits[i][row].fruitType == fruitType; i++, horzLength++) ;
    if (horzLength >= 3) return YES;
    
    NSUInteger vertLength = 1;
    for (NSInteger i = row - 1; i >= 0 && _fruits[column][i].fruitType == fruitType; i--, vertLength++) ;
    for (NSInteger i = row + 1; i < NumRows && _fruits[column][i].fruitType == fruitType; i++, vertLength++) ;
    return (vertLength >= 3);
}

#pragma mark - Swapping

- (void)performSwap:(JIMCSwap *)swap {
    // Need to make temporary copies of these because they get overwritten.
    NSInteger columnA = swap.fruitA.column;
    NSInteger rowA = swap.fruitA.row;
    NSInteger columnB = swap.fruitB.column;
    NSInteger rowB = swap.fruitB.row;
    
    // Swap the fruits. We need to update the array as well as the column
    // and row properties of the JIMCFruit objects, or they go out of sync!
    _fruits[columnA][rowA] = swap.fruitB;
    swap.fruitB.column = columnA;
    swap.fruitB.row = rowA;
    
    _fruits[columnB][rowB] = swap.fruitA;
    swap.fruitA.column = columnB;
    swap.fruitA.row = rowB;
}

#pragma mark - Detecting Matches
-(NSSet *)deletarFrutas{
     NSMutableSet *set = [NSMutableSet set];
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            JIMCFruit *fruit = _fruits [column][row];
            JIMCSwap *swap = [[JIMCSwap alloc] init];
            swap.fruitA = fruit;
            if ([swap.fruitA.spriteName isEqualToString:@"Croissant"] ) {
                JIMCChain *chain = [[JIMCChain alloc] init];
                [chain addFruit:_fruits[fruit.column][fruit.row]];
                [set addObject:chain];
            }
        }
    }
    return set;
}


- (NSSet *)removeMatchesHorizontal {
    NSMutableSet *horizontalChains = [[NSMutableSet alloc]initWithSet:[self detectHorizontalMatches]];
    NSSet *verticalChains = [self detectVerticalMatches];
   //NSSet *deletarFrutas = [self deletarFrutas];
    //NSSet *frutas = [self deletarFrutas];
    
    // Note: to detect more advanced patterns such as an L shape, you can see
    // whether a fruit is in both the horizontal & vertical chains sets and
    // whether it is the first or last in the array (at a corner). Then you
    // create a new JIMCChain object with the new type and remove the other two.
    //NSLog(@"valor %@",[verticalChains allObjects]);
 
//    for (JIMCChain *chain in verticalChains) {
//        
//        for (JIMCFruit *fruit in chain.fruits) {
//            
//            _fruits[fruit.column][fruit.row].fruitType = 6;
//            [_fruits[fruit.column][fruit.row] setSprite: [SKSpriteNode spriteNodeWithImageNamed:@"Banana"]];
//        }
//    }
    
    [self removeFruits:horizontalChains];
    [self removeFruits:verticalChains];
    //[self removeFruits:deletarFrutas];
    
    [self calculateScores:horizontalChains];
    [self calculateScores:verticalChains];
    
    [horizontalChains unionSet:verticalChains];
    //[horizontalChains unionSet:deletarFrutas];
    return horizontalChains ;
}
-(void)verificaDestruir:(NSSet *)chains{
    for (JIMCChain *chain in chains) {
       
        
        for (JIMCFruit *fruit in chain.fruits) {
            if (fruit != nil) {
                
            
            if (_fruits[fruit.column][fruit.row + 1].fruitType ==
                 _fruits[fruit.column][fruit.row + 2].fruitType ) {
                
                NSLog(@"vertical");
            
            }else
                NSLog(@"horizontal");
        }
        }
    }


}
- (NSSet *)removeMatchesVertical {
   // NSMutableSet *horizontalChains = [[NSMutableSet alloc]initWithSet:[self detectHorizontalMatches]];
    NSSet *verticalChains = [self detectVerticalMatches];
    //NSSet *deletarFrutas = [self deletarFrutas];
    //NSSet *frutas = [self deletarFrutas];
    
    // Note: to detect more advanced patterns such as an L shape, you can see
    // whether a fruit is in both the horizontal & vertical chains sets and
    // whether it is the first or last in the array (at a corner). Then you
    // create a new JIMCChain object with the new type and remove the other two.
    //NSLog(@"valor %@",[verticalChains allObjects]);
    
    //    for (JIMCChain *chain in verticalChains) {
    //        for (JIMCFruit *fruit in chain.fruits) {
    //
    //            _fruits[fruit.column][fruit.row].fruitType = 6;
    //            [_fruits[fruit.column][fruit.row] setSprite: [SKSpriteNode spriteNodeWithImageNamed:@"Banana"]];
    //        }
    //    }
    
    //[self removeFruits:horizontalChains];
    [self removeFruits:verticalChains];
    //[self removeFruits:deletarFrutas];
    
   // [self calculateScores:horizontalChains];
    [self calculateScores:verticalChains];
    
     //[horizontalChains unionSet:verticalChains];
    //[horizontalChains unionSet:deletarFrutas];
    return verticalChains ;
}


- (NSSet *)detectHorizontalMatches {
    
    // Contains the JIMCFruit objects that were part of a horizontal chain.
    // These fruits must be removed.
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row = 0; row < NumRows; row++) {
        
        // Don't need to look at last two columns.
        // Note: for-loop without increment.
        for (NSInteger column = 0; column < NumColumns - 2; ) {
            
            // If there is a fruit/tile at this position...
            if (_fruits[column][row] != nil) {
                NSUInteger matchType = _fruits[column][row].fruitType;
                
                // And the next two columns have the same type...
                if (_fruits[column + 1][row].fruitType == matchType
                    && _fruits[column + 2][row].fruitType == matchType) {
                    
                    // ...then add all the fruits from this chain into the set.
                    JIMCChain *chain = [[JIMCChain alloc] init];
                    chain.chainType = ChainTypeHorizontal;
                    do {
                        [chain addFruit:_fruits[column][row]];
                        column += 1;
                    }
                    while (column < NumColumns && _fruits[column][row].fruitType == matchType);
                    
                    [set addObject:chain];
                    continue;
                }
            }
            
            // Fruit did not match or empty tile, so skip over it.
            column += 1;
        }
    }
    return set;
}

// Same as the horizontal version but just steps through the array differently.
- (NSSet *)detectVerticalMatches {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        for (NSInteger row = 0; row < NumRows - 2; ) {
            if (_fruits[column][row] != nil) {
                NSUInteger matchType = _fruits[column][row].fruitType;
                
                if (_fruits[column][row + 1].fruitType == matchType
                    && _fruits[column][row + 2].fruitType == matchType) {
                    
                    JIMCChain *chain = [[JIMCChain alloc] init];
                    chain.chainType = ChainTypeVertical;
                    do {
                        [chain addFruit:_fruits[column][row]];
                        row += 1;
                    }
                    while (row < NumRows && _fruits[column][row].fruitType == matchType);
                    
                    [set addObject:chain];
                    continue;
                }
            }
            row += 1;
        }
    }
    return set;
}

- (void)removeFruits:(NSSet *)chains {
    for (JIMCChain *chain in chains) {
        if (chain.fruits.count == 4) {
            NSLog(@"dasdasdasd");
        }
        for (JIMCFruit *fruit in chain.fruits) {
            _fruits[fruit.column][fruit.row] = nil;
        }
    }
}

- (void)calculateScores:(NSSet *)chains {
    // 3-chain is 60 pts, 4-chain is 120, 5-chain is 180, and so on
    for (JIMCChain *chain in chains) {
        //chain.score = 60 * ([chain.fruits count] - 2) * self.comboMultiplier;
        self.comboMultiplier++;
    }
}

#pragma mark - Detecting Holes

- (NSArray *)fillHoles {
    NSMutableArray *columns = [NSMutableArray array];
    
    // Loop through the rows, from bottom to top. It's handy that our row 0 is
    // at the bottom already. Because we're scanning from bottom to top, this
    // automatically causes an entire stack to fall down to fill up a hole.
    // We scan one column at a time.
    for (NSInteger column = 0; column < NumColumns; column++) {
        
        NSMutableArray *array;
        for (NSInteger row = 0; row < NumRows; row++) {
            
            // If there is a tile at this position but no fruit, then there's a hole.
            if (_tiles[column][row] != nil && _fruits[column][row] == nil) {
                
                // Scan upward to find a fruit.
                for (NSInteger lookup = row + 1; lookup < NumRows; lookup++) {
                    JIMCFruit *fruit = _fruits[column][lookup];
                    
                    if (fruit != nil) {
                        // Swap that fruit with the hole.
                        _fruits[column][lookup] = nil;
                        
                        _fruits[column][row] = fruit;
                        fruit.row = row;
                        
                        // For each column, we return an array with the fruits that have
                        // fallen down. Fruits that are lower on the screen are first in
                        // the array. We need an array to keep this order intact, so the
                        // animation code can apply the correct kind of delay.
                        if (array == nil) {
                            array = [NSMutableArray array];
                            [columns addObject:array];
                        }
                        [array addObject:fruit];
                        
                        // Don't need to scan up any further.
                        break;
                    }
                }
            }
        }
    }
    return columns;
}

-(NSArray *)addFruti:(NSInteger *)co{

    
    return nil;
}

- (NSArray *)topUpFruits {
    NSMutableArray *columns = [NSMutableArray array];
    NSUInteger fruitType = 0;
    
    // Detect where we have to add the new fruits. If a column has X holes,
    // then it also needs X new fruits. The holes are all on the top of the
    // column now, but the fact that there may be gaps in the tiles makes this
    // a little trickier.
    for (NSInteger column = 0; column < NumColumns; column++) {
        
        // This time scan from top to bottom. We can end when we've found the
        // first fruit.
        NSMutableArray *array;
        for (NSInteger row = NumRows - 1; row >= 0 && _fruits[column][row] == nil; row--) {
            
            // Found a hole?
            if (_tiles[column][row] != nil) {
                
                // Randomly create a new fruit type. The only restriction is that
                // it cannot be equal to the previous type. This prevents too many
                // "freebie" matches.
                NSUInteger newFruitType;
                do {
                        newFruitType = arc4random_uniform(NumFruitTypes) + 1;
                } while (newFruitType == fruitType);
                
                fruitType = newFruitType;
                
                // Create a new fruit.
                JIMCFruit *fruit = [self createFruitAtColumn:column row:row withType:fruitType];
                
                // Add the fruit to the array for this column.
                // Note that we only allocate an array if a column actually has holes.
                // This cuts down on unnecessary allocations.
                if (array == nil) {
                    array = [NSMutableArray array];
                    [columns addObject:array];
                }
                [array addObject:fruit];
            }
        }
    }

    return columns;
}



#pragma mark - Querying the Level

- (JIMCTile *)tileAtColumn:(NSInteger)column row:(NSInteger)row {
    NSAssert1(column >= 0 && column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(row >= 0 && row < NumRows, @"Invalid row: %ld", (long)row);
    
    return _tiles[column][row];
}

- (JIMCFruit *)fruitAtColumn:(NSInteger)column row:(NSInteger)row {
    NSAssert1(column >= 0 && column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(row >= 0 && row < NumRows, @"Invalid row: %ld", (long)row);
    
    return _fruits[column][row];
}

- (BOOL)isPossibleSwap:(JIMCSwap *)swap {
    return [self.possibleSwaps containsObject:swap];
}

@end
