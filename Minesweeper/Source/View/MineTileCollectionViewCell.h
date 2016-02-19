//
//  MineTileCollectionViewCell.h
//  Minesweeper
//
//  Created by Amita Pai on 2/17/16.
//  Copyright © 2016 Amita Pai. All rights reserved.
//


@protocol MineFieldDelegate <NSObject>

- (void)mineFieldValidationFailure;
- (void)mineFieldValidationSuccess;

@end

@interface MineTileCollectionViewCell : UICollectionViewCell

@property (nonatomic, assign) NSInteger indexPosition;

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
@property (nonatomic, assign, getter=isTapped) BOOL tapped;
@property (nonatomic, assign, getter=isFlagged) BOOL flagged;
@property (nonatomic, assign) BOOL hidesMine;
@property (nonatomic, assign) NSInteger neighboringMineCount;

@property (nonatomic, weak) id <MineFieldDelegate> mineFieldDelegate;

- (void)updateTile;

@end
