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

@property (strong, nonatomic) UITapGestureRecognizer *doubleTapGestureRecognizer;
@end

@implementation MineTileCollectionViewCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(initialSetup)
                                                     name:kResetMineFieldNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(revealHiddenMine)
                                                     name:kShowAllHiddenMinesNotification
                                                   object:nil];
        
        _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped)];
        _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        _doubleTapGestureRecognizer.numberOfTouchesRequired = 1;
        _doubleTapGestureRecognizer.delaysTouchesBegan = YES;
        [self addGestureRecognizer:_doubleTapGestureRecognizer];
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
    self.state = tapped ? TAPPED : INITIAL;

    if (self.hidesMine) {
        [self revealHiddenMine];
    } else {
        self.mineCountLabel.hidden = NO;
        self.stateIndicatorImageView.hidden = YES;
    }
}

- (void)setFlagged:(BOOL)flagged {
    _flagged = flagged;
    self.state = flagged ? FLAGGED : INITIAL;

    _enabled = !flagged;
}

- (void)setState:(MineTileState)state {
    _state = state;
    
    [self updateTile];
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
            [self.stateIndicatorImageView setImage:[UIImage imageNamed:@"Tile"]];
            break;
    }
}

- (void)doubleTapped {
    self.flagged = !self.flagged;
}
@end
