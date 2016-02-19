//
//  MineTileCollectionViewCell.m
//  Minesweeper
//
//  Created by Amita Pai on 2/17/16.
//  Copyright © 2016 Amita Pai. All rights reserved.
//

#import "MineTileCollectionViewCell.h"

@interface MineTileCollectionViewCell ()

@property (nonatomic, assign) GridPosition gridPosition;
@property (nonatomic, assign) MineTileState state;

@property (weak, nonatomic) IBOutlet UIImageView *stateIndicatorImageView;
@property (weak, nonatomic) IBOutlet UILabel *mineCountLabel;

@end

@implementation MineTileCollectionViewCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialSetup];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(initialSetup)
                                                     name:kResetMineFieldNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(revealHiddenMine)
                                                     name:kShowAllHiddenMinesNotification
                                                   object:nil];
    }
    return  self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kResetMineFieldNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kShowAllHiddenMinesNotification
                                                  object:nil];
}

- (void)initialSetup {
    _state = INITIAL;
    _tapped = NO;
    _flagged = NO;
    _hidesMine = NO;
    _enabled = YES;
    
    self.neighboringMineCount = 0;
    
    [self updateTile];
}

- (void)revealHiddenMine {
    if (self.hidesMine) {
        self.mineCountLabel.hidden = YES;
        self.stateIndicatorImageView.hidden = NO;
        [self.stateIndicatorImageView setImage:[UIImage imageNamed:@"Mine"]];
    } else {
        self.enabled = NO;
    }
}

- (void)setNeighboringMineCount:(NSInteger)neighboringMineCount {
    _neighboringMineCount = neighboringMineCount;
    
    
    self.mineCountLabel.text = neighboringMineCount ? [NSString stringWithFormat:@"%ld", neighboringMineCount] : @"";
}

- (void)setTapped:(BOOL)tapped {
    if (!self.enabled) {
        return;
    }
    _tapped = tapped;
    _state = TAPPED;

    if (self.hidesMine) {
        [self revealHiddenMine];
    } else {
        self.mineCountLabel.hidden = NO;
        self.stateIndicatorImageView.hidden = YES;
    }
}

- (void)setFlagged:(BOOL)flagged {
    _flagged = flagged;
    _state = FLAGGED;
    _enabled = NO;
    
    self.mineCountLabel.hidden = YES;
    self.stateIndicatorImageView.hidden = NO;
    [self.stateIndicatorImageView setImage:[UIImage imageNamed:@"Flag"]];
}

- (void)updateTile {
    self.stateIndicatorImageView.hidden = YES;
    self.mineCountLabel.hidden = YES;
    switch (self.state) {
        case FLAGGED:
            self.stateIndicatorImageView.hidden = NO;
            [self.stateIndicatorImageView setImage:[UIImage imageNamed:@"Flag"]];
            break;
        case TAPPED:
            self.mineCountLabel.hidden = !(self.neighboringMineCount > 0);
            break;
        case INITIAL:
        default:
            self.stateIndicatorImageView.hidden = NO;
            self.stateIndicatorImageView.image = [UIImage imageNamed:@"Tile"];
            break;
    }
}

@end
