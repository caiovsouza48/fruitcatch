

#import "JIMCFruit.h"
#import "JIMCTile.h"
#import "JIMCSwap.h"
#import "JIMCChain.h"

@class JIMCPowerUp;

#import "MyScene.h"
static const NSInteger NumColumns = 9;
static const NSInteger NumRows = 9;

@interface JIMCLevel : NSObject

@property (assign, nonatomic) NSUInteger targetScore;
@property (assign, nonatomic) NSUInteger maximumMoves;

// Create a level by loading it from a file.
- (instancetype)initWithFile:(NSString *)filename;
- (JIMCFruit *)createFruitAtColumn:(NSInteger)column row:(NSInteger)row withType:(NSUInteger)fruitType;
// Fills up the level with new JIMCFruit objects. The level is guaranteed free
// from matches at this point.
// You call this method at the beginning of a new game and whenever the player
// taps the Shuffle button.
// Returns a set containing all the new JIMCFruit objects.
- (NSSet *)shuffle;

// Returns the fruit at the specified column and row, or nil when there is none.
- (JIMCFruit *)fruitAtColumn:(NSInteger)column row:(NSInteger)row;

// Determines whether there's a tile at the specified column and row.
- (JIMCTile *)tileAtColumn:(NSInteger)column row:(NSInteger)row;

- (void)removeFruitAtColumn:(NSInteger)column row:(NSInteger)row;

// Swaps the positions of the two fruits from the JIMCSwap object.
- (void)performSwap:(JIMCSwap *)swap;

// Determines whether the suggested swap is a valid one, i.e. it results in at
// least one new chain of 3 or more fruits of the same type.
- (BOOL)isPossibleSwap:(JIMCSwap *)swap;

// Recalculates which moves are valid.
- (NSSet *)detectPossibleSwaps;
-(int)verificaDestruir:(JIMCFruit *)fruit;
// Detects whether there are any chains of 3 or more fruits, and removes them
// from the level.
// Returns a set containing JIMCChain objects, which describe the JIMCFruits
// that were removed.
- (NSSet *)removeMatchesAllType:(JIMCSwap *)fruit;
- (NSSet *)removeMatches;
// Detects where there are holes and shifts any fruits down to fill up those
// holes. In effect, this "bubbles" the holes up to the top of the column.
// Returns an array that contains a sub-array for each column that had holes,
// with the JIMCFruit objects that have shifted. Those fruits are already
// moved to their new position. The objects are ordered from the bottom up.
- (NSArray *)fillHoles;

// Where necessary, adds new fruits to fill up the holes at the top of the
// columns.
// Returns an array that contains a sub-array for each column that had holes,
// with the new JIMCFruit objects. Fruits are ordered from the top down.
- (NSArray *)topUpFruits;

// Should be called at the start of every new turn.
- (void)resetComboMultiplier;

- (NSSet *) executePowerUp:(JIMCPowerUp *)powerUp;

- (NSSet *)removeMatchesForPowerUp:(JIMCPowerUp *)powerUp;

- (void)fruitsBySet:(NSSet *)set;

@property (strong, nonatomic) MyScene *scene;
-(NSSet *)deletarFrutas;
- (BOOL)isPowerSwap:(JIMCSwap *)swap;

- (BOOL)isSelectedFruit:(JIMCFruit *)fruit;
- (BOOL)isPowerSwapLike:(JIMCSwap *)swap;
- (NSSet *)removeMatchesAll;

@end
