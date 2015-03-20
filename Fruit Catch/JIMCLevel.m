
#import "JIMCLevel.h"
#import "GameViewController.h"
#import "JIMCSwapFruitSingleton.h"
#import "JIMCPowerUp.h"
#import "NetworkController.h"
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

- (int)getNumOfColumns{
    return NumColumns;
}

- (int)getNumOfRows{
    return NumRows;
}

- (NSDictionary *)loadJSON:(NSString *)filename {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    if (path == nil) {
        //NSLog(@"Could not find level file: %@", filename);
        return nil;
    }
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if (data == nil) {
        //NSLog(@"Could not load level file: %@, error: %@", filename, error);
        return nil;
    }
    
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (dictionary == nil || ![dictionary isKindOfClass:[NSDictionary class]]) {
        //NSLog(@"Level file '%@' is not valid JSON: %@", filename, error);
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

- (void)fruitsBySet:(NSSet *)set{
    for (JIMCFruit *fruit in [set allObjects]) {
        _fruits[fruit.column][fruit.row] = fruit;
    }
}

- (void)fruitsByFruitStruct:(JIMCFruitStruct *)fruitStructPointer PointerSize:(int)pointerSize{
    for (int i=0; i<pointerSize; i++) {
        JIMCFruit *fruit = [[JIMCFruit alloc]init];
        fruit.column = fruitStructPointer[i].column;
        fruit.row = fruitStructPointer[i].row;
        fruit.fruitType = fruitStructPointer[i].fruitType;
        _fruits[fruit.column][fruit.row] = fruit;
    }
}

- (void)setFruitsBySet:(NSSet *)set{
    for (JIMCFruit *fruit in [set allObjects]) {
        _fruits[fruit.column][fruit.row] = fruit;
    }
}

- (NSSet *)setByFruitStruct:(JIMCFruitStruct *)fruitStructPointer PointerSize:(int)pointerSize{
    NSMutableSet *mutableFruitSet = [NSMutableSet set];
    for (int i=0; i<pointerSize; i++) {
        JIMCFruit *fruit = [[JIMCFruit alloc]init];
        fruit.column = fruitStructPointer[i].column;
        fruit.row = fruitStructPointer[i].row;
        fruit.fruitType = fruitStructPointer[i].fruitType;
        [mutableFruitSet addObject:fruit];
    }
    return [mutableFruitSet copy];
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
-(NSSet *)deletarFrutas:(JIMCSwap *)fruitDeletar{
    NSMutableSet *set = [NSMutableSet set];
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            JIMCFruit *fruit = _fruits [column][row];
            if (fruit.fruitType == fruitDeletar.fruitB.fruitType) {
                JIMCChain *chain = [[JIMCChain alloc] init];
                [chain addFruit:_fruits[fruit.column][fruit.row]];
                [set addObject:chain];
            }
        }
    }
    JIMCFruit *selectedFruit = [JIMCSwapFruitSingleton sharedInstance].swap.fruitA;
    JIMCChain *chain = [[JIMCChain alloc] init];
    [chain addFruit:_fruits[selectedFruit.column][selectedFruit.row]];
    [set addObject:chain];
    [JIMCSwapFruitSingleton sharedInstance].swap = nil;
    return set;
}
-(NSSet *)deletarFrutas{
    NSMutableSet *set = [NSMutableSet set];
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            JIMCFruit *fruit = _fruits [column][row];
            if (fruit!=nil) {
                JIMCChain *chain = [[JIMCChain alloc] init];
                [chain addFruit:_fruits[fruit.column][fruit.row]];
                [set addObject:chain];
            }
        }
    }
    JIMCFruit *selectedFruit = [JIMCSwapFruitSingleton sharedInstance].swap.fruitA;
    JIMCChain *chain = [[JIMCChain alloc] init];
    [chain addFruit:_fruits[selectedFruit.column][selectedFruit.row]];
    [set addObject:chain];
    [JIMCSwapFruitSingleton sharedInstance].swap = nil;
    return set;
}
-(NSSet *)deletarFrutasRec:(JIMCFruit *)fruitDeletar{
    NSMutableSet *set = [NSMutableSet set];
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            JIMCFruit *fruit = _fruits [column][row];
            if (fruit.fruitType == fruitDeletar.fruitType) {
                JIMCChain *chain = [[JIMCChain alloc] init];
                [chain addFruit:_fruits[fruit.column][fruit.row]];
                [set addObject:chain];
            }
        }
    }
    return set;
}
#warning recursividade do capeta
-(NSSet*)removeMatchesRecursive:(NSSet *)chains {
    NSMutableSet *chain = [[NSMutableSet alloc]init];
    [chain unionSet:chains];
    for (JIMCChain *jim in chains) {
        for (JIMCFruit *fruit in jim.fruits) {
            // Tem power UP
            // executar power up
            if (fruit.fruitPowerUp == 2){
                fruit.fruitPowerUp = 0;
                NSSet *del = [self detectFruitsInRow:fruit];
                [chain unionSet:[self removeMatchesRecursive:del]];
            }else if ( fruit.fruitPowerUp == 3){
                fruit.fruitPowerUp = 0;
                NSSet *del = [self detectFruitsInColumn:fruit];
                [chain unionSet:[self removeMatchesRecursive:del]];
            }else if ( fruit.fruitPowerUp == 1){
                JIMCFruit *fruitP = [jim.fruits objectAtIndex:0];
                NSSet *del = [self deletarFrutasRec:fruitP];
                fruit.fruitPowerUp = 0;
                [chain unionSet:[self removeMatchesRecursive:del]];
            }
            
        }
    }
    return chain;
}


- (NSSet *)removeMatches {
    NSMutableSet *horizontalChains = [[NSMutableSet alloc]initWithSet:[self detectHorizontalMatches]];
    NSSet *verticalChains = [self detectVerticalMatches];
    NSMutableSet *mut = [[NSMutableSet alloc]init];
    NSMutableSet *comboRecursivo = [[NSMutableSet alloc]init];
    //NSSet *deletarFrutas = [self deletarFrutas];
    NSSet *rowChains = nil;
    NSSet *columnChains = nil;
    
    rowChains = [self chainedRow:horizontalChains];
    columnChains = [self chainedColumn:verticalChains];
    [comboRecursivo unionSet:rowChains];
    [comboRecursivo unionSet:columnChains];
    NSSet *recursivo = [self removeMatchesRecursive:comboRecursivo];
    
    //NSSet *deletarFrutas = [self deletarFrutas];
    //NSSet *frutas = [self deletarFrutas];
    
    // Note: to detect more advanced patterns such as an L shape, you can see
    // whether a fruit is in both the horizontal & vertical chains sets and
    // whether it is the first or last in the array (at a corner). Then you
    // create a new JIMCChain object with the new type and remove the other two.
    
    if ([JIMCSwapFruitSingleton sharedInstance].swap!=nil) {
        [mut unionSet:verticalChains];
        [mut unionSet:horizontalChains];
        [self powerUpSingleton:mut];
    }else{
        [mut unionSet:horizontalChains];
        [mut unionSet:verticalChains];
        [self powerUpCombo:mut];
    }
    
    [self calculateScoresAllType:recursivo];
    [self calculateScores:columnChains];
    [self calculateScores:rowChains];
    [self calculateScores:horizontalChains];
    [self calculateScores:verticalChains];
    
    [self removeFruits:recursivo];
    [self removeFruits:horizontalChains];
    [self removeFruits:verticalChains];
    [self removeFruits:rowChains];
    [self removeFruits:columnChains];
    
    [horizontalChains unionSet:recursivo];
    [horizontalChains unionSet:verticalChains];
    [horizontalChains unionSet:rowChains];
    [horizontalChains unionSet:columnChains];
    
    return horizontalChains;
}

- (int)chainCount{
    NSSet *set = [self detectVerticalMatches];
    JIMCChain *chain = [set anyObject];
    
    //NSLog(@"Vertical Matches = %d",(int)chain.fruits.count);
    return (int) chain.fruits.count;
}

- (NSSet *)chainedRow:(NSSet *)horizontalChains{
    NSSet *rowChains;
    for (JIMCChain *chain in horizontalChains) {
        for (JIMCFruit *fruit in chain.fruits) {
            if (fruit.fruitPowerUp == 2 ) {
                //fruit.fruitPowerUp =0;
                rowChains = [self detectFruitsInRow:fruit];
            }else if ( fruit.fruitPowerUp == 3 ){
                //fruit.fruitPowerUp =0;
                rowChains = [self detectFruitsInColumn:fruit];
            }
        }
    }
    
    return rowChains;
}

- (NSSet *)chainedColumn:(NSSet *)verticalChains{
    NSSet *columnChains;
    for (JIMCChain *chain in verticalChains) {
        for (JIMCFruit *fruit in chain.fruits) {
            if (fruit.fruitPowerUp == 2 ) {
                // fruit.fruitPowerUp =0;
                columnChains = [self detectFruitsInRow:fruit];
            }else if (fruit.fruitPowerUp == 3 ){
                //fruit.fruitPowerUp =0;
                columnChains = [self detectFruitsInColumn:fruit];
            }
        }
    }
    return columnChains;
}

- (NSSet *)removeMatchesForPowerUp:(JIMCPowerUp *)powerUp {
    NSMutableSet *horizontalChains = [[NSMutableSet alloc]initWithSet:[self checkHorizontalFruitsToRemoveForPowerUp:powerUp andLimit:0]];
    
    NSSet *verticalChains = [self checkVerticalFruitsToRemoveForPowerUp:powerUp andLimit:0];
    //NSLog(@"horizontalChains = %lu",(unsigned long)horizontalChains.count);
    //NSLog(@"VerticalChains = %lu",(unsigned long)verticalChains.count);
    // Note: to detect more advanced patterns such as an L shape, you can see
    // whether a fruit is in both the horizontal & vertical chains sets and
    // whether it is the first or last in the array (at a corner). Then you
    // create a new JIMCChain object with the new type and remove the other two.
    [self removeFruits:horizontalChains];
    [self removeFruits:verticalChains];
    
    [self calculateScores:horizontalChains];
    [self calculateScores:verticalChains];
    
    [horizontalChains unionSet:verticalChains];
    //[horizontalChains unionSet:deletarFrutas];
    return horizontalChains ;
}


- (NSSet *)detectFruitsInRow:(JIMCFruit *)fruit {
    // Contains the JIMCFruit objects that were part of a horizontal chain.
    // These fruits must be removed.
    
    NSMutableSet *set = [NSMutableSet set];
    for (NSInteger row = 0; row < NumRows; row++) {
        // Don't need to look at last two columns.
        // Note: for-loop without increment.
        for (NSInteger column = 0; column < NumColumns ;column++ ) {
            // If there is a fruit/tile at this position...
            if ((_fruits[column][row] != nil) && (_fruits[column][row].column == fruit.column) ) {
                JIMCChain *chain = [[JIMCChain alloc] init];
                chain.chainType = ChainTypeHorizontal;
                //_fruits[column][row].fruitPowerUp = 0;
                [chain addFruit:_fruits[column][row]];
                [set addObject:chain];
            }
        }
    }
    return set;
}

- (NSSet *)detectFruitsInColumn:(JIMCFruit *)fruit {
    NSMutableSet *set = [NSMutableSet set];
    for (NSInteger column = 0; column < NumColumns; column++) {
        for (NSInteger row = 0; row < NumRows; row++) {
            if ((_fruits[column][row] != nil) && (_fruits[column][row].row == fruit.row)) {
                JIMCChain *chain = [[JIMCChain alloc] init];
                chain.chainType = ChainTypeVertical;
                //_fruits[column][row].fruitPowerUp = 0;
                [chain addFruit:_fruits[column][row]];
                [set addObject:chain];
            }
        }
    }
    
    return set;
}
- (NSSet *)removeMatchesAllType:(JIMCSwap *)fruit {
    
    NSSet *removeAllType = [self deletarFrutas:fruit];
    [self removeFruitsAllType:removeAllType];
    [self calculateScoresAllType:removeAllType];
    return removeAllType ;
}
- (NSSet *)removeMatchesAll{
    
    NSSet *removeAllType = [self deletarFrutas];
    [self removeFruitsAllType:removeAllType];
    [self calculateScoresAllType:removeAllType];
    
    return removeAllType ;
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
                if (matchType!=6) {
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
            }
            row += 1;
        }
    }
    return set;
}

- (NSSet *)checkVerticalFruitsToRemoveForPowerUp:(JIMCPowerUp *)powerUp andLimit:(NSInteger)limit {
    
    // Contains the JIMCFruit objects that were part of a horizontal chain.
    // These fruits must be removed.
    NSMutableSet *set = [NSMutableSet set];
    int column = (int)powerUp.position.x;
    int row = (int)powerUp.position.y;
    if (_fruits[column][row] != nil) {
        
        // ...then add all the fruits from this chain into the set.
        JIMCChain *chain = [[JIMCChain alloc] init];
        chain.chainType = ChainTypeVertical;
        [chain addFruit:_fruits[column][row]];
        do {
            if (nil != _fruits[column][row+1]){
                if (nil != _fruits[column][row-1]){
                    [chain addFruit:_fruits[column][row-1]];
                }
                [chain addFruit:_fruits[column][row+1]];
                row += 1;
            }
            else{
                continue;
            }
            
        }
        while (row < limit);
        
        [set addObject:chain];
    }
    // Fruit did not match or empty tile, so skip over it.
    row += 1;
    return set;
}


// Same as the horizontal version but just steps through the array differently.
- (NSSet *)checkVerticalFruitsToRemove:(NSInteger)limit{
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        for (NSInteger row = 0; row < NumRows - 2; ) {
            if (_fruits[column][row] != nil) {
                JIMCChain *chain = [[JIMCChain alloc] init];
                chain.chainType = ChainTypeVertical;
                do {
                    [chain addFruit:_fruits[column][row]];
                    row += 1;
                }
                while (row < limit);
                [set addObject:chain];
                continue;
            }
            row += 1;
        }
    }
    return set;
}

- (NSSet *)checkHorizontalFruitsToRemoveForPowerUp:(JIMCPowerUp *)powerUp andLimit:(NSInteger)limit {
    
    // Contains the JIMCFruit objects that were part of a horizontal chain.
    // These fruits must be removed.
    
    NSMutableSet *set = [NSMutableSet set];
    int column = (int)powerUp.position.x;
    int row = (int)powerUp.position.y;
    
    // NSLog(@"linha e coluna %d %f ",column,powerUp.position.y);
    if (_fruits[column][row] != nil) {
        // ...then add all the fruits from this chain into the set.
        JIMCChain *chain = [[JIMCChain alloc] init];
        chain.chainType = ChainTypeHorizontal;
        [chain addFruit:_fruits[column][row]];
        do {
            if ((nil != _fruits[column+1][row]) && ([_fruits[column+1][row] isKindOfClass:[JIMCFruit class]])){
                [chain addFruit:_fruits[column+1][row]];
                
                if ((nil != _fruits[column-1][row]) && ([_fruits[column-1][row] isKindOfClass:[JIMCFruit class]])){
                    [chain addFruit:_fruits[column-1][row]];
                }
                column += 1;
            }
            else{
                continue;
            }
            [set addObject:chain];
        } while (column < limit);
    }
    // Fruit did not match or empty tile, so skip over it.
    return set;
}
-(void)powerUpCombo:(NSSet *)chains{
    for (JIMCChain *chain in chains) {
        for (JIMCFruit *fruit in chain.fruits) {
            if (chain.fruits.count == 5) {
                _fruits[fruit.column][fruit.row].fruitPowerUp = 1;
                _fruits[fruit.column][fruit.row].fruitType = 6;
                break;
            }else if (chain.fruits.count == 4){
                int a =arc4random()%2;
                if(a == 1)
                    _fruits[fruit.column][fruit.row].fruitPowerUp = 2;
                else
                    _fruits[fruit.column][fruit.row].fruitPowerUp = 3;
                break;
            }
        }
    }
}
-(int)powerUpSingleton:(NSSet *)chains{
    int var = 0;
    for (JIMCChain *chain in chains) {
        for (JIMCFruit *fruit in chain.fruits) {
            if ([self isSelectedFruit:_fruits[fruit.column][fruit.row]] == YES && chain.fruits.count == 5) {
                _fruits[fruit.column][fruit.row].fruitPowerUp = 1;
                _fruits[fruit.column][fruit.row].fruitType = 6;
                break;
            }else if ([self isSelectedFruit:_fruits[fruit.column][fruit.row]] == YES && chain.fruits.count == 4){
                if ([self isSelectedVertical]) {
                    _fruits[fruit.column][fruit.row].fruitPowerUp = 2;
                }else{
                    _fruits[fruit.column][fruit.row].fruitPowerUp = 3;
                }
                break;
            }
        }
    }
    return var;
}

- (BOOL)isPerfectChain:(JIMCChain *)chain{
    NSUInteger fruitType = ((JIMCFruit *)chain.fruits[0]).fruitType;
    for (JIMCFruit *fruit in chain.fruits) {
        if (fruitType != fruit.fruitType){
            return NO;
        }
    }
    return YES;
}
-(void)removeFruitsAllType:(NSSet *)chains {
    for (JIMCChain *chain in chains) {
        for (JIMCFruit *fruit in chain.fruits) {
            _fruits[fruit.column][fruit.row] = nil;
            _fruits[fruit.column][fruit.row].fruitPowerUp=0;
        }
    }
}
- (void)removeFruits:(NSSet *)chains {
    for (JIMCChain *chain in chains) {
        for (JIMCFruit *fruit in chain.fruits) {
            if ([fruit isKindOfClass:[JIMCFruit class]]){
                if (_fruits[fruit.column][fruit.row].fruitPowerUp == 0){
                    _fruits[fruit.column][fruit.row] = nil;
                    _fruits[fruit.column][fruit.row].fruitPowerUp=0;
                }
            }
        }
    }
}
- (BOOL)isSelectedFruit:(JIMCFruit *)fruit{
    JIMCFruit *selectedFruitA = [JIMCSwapFruitSingleton sharedInstance].swap.fruitA;
    JIMCFruit *selectedFruitB = [JIMCSwapFruitSingleton sharedInstance].swap.fruitB;
    if (((fruit.column == selectedFruitA.column) && (fruit.row == selectedFruitA.row))) {
        return YES;
    }else if((fruit.column == selectedFruitB.column) && (fruit.row == selectedFruitB.row)){
        return YES;
    }
    return NO;
}
- (BOOL)isSelectedVertical{
    if ([JIMCSwapFruitSingleton sharedInstance].swap.vertical) {
        return YES;
    }else
        return NO;
}
- (void)calculateScores:(NSSet *)chains {
//    if (_isOpponentMove){
//        return;
//    }
    // 3-chain is 60 pts, 4-chain is 120, 5-chain is 180, and so on
    for (JIMCChain *chain in chains) {
        if ([chain.fruits count] == 1) {
            chain.score = 15 * ([chain.fruits count]) * self.comboMultiplier;
        }else{
            chain.score = 15 * ([chain.fruits count] - 2) * self.comboMultiplier;
        }
        self.comboMultiplier++;
    }
}


- (void)calculateScoresAllType:(NSSet *)chains {
//    if (_isOpponentMove){
//        return;
//    }
    // 3-chain is 60 pts, 4-chain is 120, 5-chain is 180, and so on
    for (JIMCChain *chain in chains) {
        chain.score = 30 ;
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

- (NSArray *)multiplayerTopUpFruits{
    NSMutableArray *columns = [NSMutableArray array];
    NSUInteger fruitType = 0;
    _parameter = [NSMutableArray array];
    // Detect where we have to add the new fruits. If a column has X holes,
    // then it also needs X new fruits. The holes are all on the top of the
    // column now, but the fact that therre may be gaps in the tiles makes this
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
                    // [[NetworkController sharedInstance] sendMovedSelf:1];
                    newFruitType = arc4random_uniform(NumFruitTypes) + 1;
                } while (newFruitType == fruitType);
                
                fruitType = newFruitType;
                
                // Create a new fruit.
                JIMCFruit *fruit = [self createFruitAtColumn:column row:row withType:fruitType];
                [_parameter addObject:[NSNumber numberWithUnsignedInteger:newFruitType]];
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
    NSLog(@"Columns = %@",columns);
    return columns;
}



- (NSArray *)topUpFruits {
    NSMutableArray *columns = [NSMutableArray array];
    NSUInteger fruitType = 0;
    
    // Detect where we have to add the new fruits. If a column has X holes,
    // then it also needs X new fruits. The holes are all on the top of the
    // column now, but the fact that therre may be gaps in the tiles makes this
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
                    
                    // [[NetworkController sharedInstance] sendMovedSelf:1];
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

- (NSArray *)topUpFruitsFor:(NSMutableArray *)array{
    _fruitTypeArray = [array mutableCopy];
    NSMutableArray *columns = [NSMutableArray array];
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        
        // This time scan from top to bottom. We can end when we've found the
        // first fruit.
        NSMutableArray *array2;
        //for (NSInteger row = NumRows - 1; row >= 0 && _fruits[column][row] == nil; row--) {
        for (NSInteger row = NumRows - 1; row >= 0 && _fruits[column][row] == nil; row--) {
            
            // Found a hole?
            if (_tiles[column][row] != nil) {
                NSNumber *firstElement = [_fruitTypeArray objectAtIndex:0];
                [_fruitTypeArray removeObjectAtIndex:0];
                JIMCFruit *fruit = [self createFruitAtColumn:column row:row withType:[firstElement intValue]];
                // Add the fruit to the array for this column.
                // Note that we only allocate an array if a column actually has holes.
                // This cuts down on unnecessary allocations.
                if (array2 == nil) {
                    array2 = [NSMutableArray array];
                    [columns addObject:array2];
                }
                [array2 addObject:fruit];
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
- (BOOL)isPowerSwap:(JIMCSwap *)swap {
    if (swap.fruitA.fruitType == 6 ) {
        return YES;
    }
    return NO;
}
- (BOOL)isPowerSwapLike:(JIMCSwap *)swap {
    if (swap.fruitA.fruitType == 6 && swap.fruitB.fruitType == 6) {
        return YES;
    }
    return NO;
}
- (BOOL)isPossibleSwap:(JIMCSwap *)swap {
    return [self.possibleSwaps containsObject:swap];
}

- (NSSet *) executePowerUp:(JIMCPowerUp *)powerUp{
    
    return [self removeMatchesForPowerUp:powerUp];
}

- (int)getLevelComboMultiplier{
    return _comboMultiplier;
}

@end
