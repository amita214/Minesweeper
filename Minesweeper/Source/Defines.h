//
//  Defines.h
//  Minesweeper
//
//  Created by Amita Pai on 2/17/16.
//  Copyright © 2016 Amita Pai. All rights reserved.
//

#ifndef Defines_h
#define Defines_h

#import <UIKit/UIKit.h>

#define MAX_HIDDEN_MINES        10
#define MAX_ROWS_COLUMN         8

#define GRID_SIZE               MAX_ROWS_COLUMN * MAX_ROWS_COLUMN
#define ROW_FROM_INDEX(X)       (X) / MAX_ROWS_COLUMN
#define COLUMN_FROM_INDEX(X)    (X) % MAX_ROWS_COLUMN
#define INDEXIFY(R, C)          (R) * MAX_ROWS_COLUMN + (C)

#define IS_VALID_ROW(R)         (R) >= 0 && (R) < MAX_ROWS_COLUMN
#define IS_VALID_COLUMN(C)      (C) >= 0 && (C) < MAX_ROWS_COLUMN

#define IS_VALID_POSITION(X)    (X) >= 0 && (X) < GRID_SIZE

#define FLAGGED_TILE_MASK       8

#pragma mark - struct definitions
typedef struct Grid {
    int row, column;
} GridPosition;


#pragma mark - enum definitions
typedef enum {
    INITIAL,
    FLAGGED,
    TAPPED
} MineTileState;

#pragma mark - String constants
extern NSString * const kMineTileReuseIdentifier;

extern NSString * const kResetMineFieldNotification;
extern NSString * const kShowAllHiddenMinesNotification;

#endif /* Defines_h */
