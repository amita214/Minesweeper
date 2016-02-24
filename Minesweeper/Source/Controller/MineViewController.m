//
//  ViewController.m
//  Minesweeper
//
//  Created by Amita Pai on 2/17/16.
//  Copyright © 2016 Amita Pai. All rights reserved.
//

#import "MineViewController.h"
#import "MineTileCollectionViewCell.h"

#import <AVFoundation/AVFoundation.h>

@interface MineViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, MineFieldDelegate> {
    NSMutableArray *_hiddenMinePositions;
    
    BOOL _isFailed;
    
    NSTimer *_updateTimer;
    NSUInteger _timerSeconds;
}

@property (weak, nonatomic) IBOutlet UIImageView *referenceBackgroundImageView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (weak, nonatomic) IBOutlet UIView *carpetView; // only to diable taps once game over - won/lost

@property (strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, assign) NSInteger revealedTileCount;
@property (nonatomic, assign) NSInteger validationCount; //count of tiles completed validation

@end

@implementation MineViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self resetMine];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setRevealedTileCount:(NSInteger)revealedTileCount {
    _revealedTileCount = revealedTileCount;
    
    if (revealedTileCount == MAX_HIDDEN_MINES) {
        [self finalResult];
    }
}

- (void)setValidationCount:(NSInteger)validationCount {
    _validationCount = validationCount;
    
    if (validationCount == 0) {
        [self finalResult];
    }
}

#pragma mark - IB Outlets
- (IBAction)resetMineField:(UIButton *)sender {
    [self stopTimer];
    if (_revealedTileCount < GRID_SIZE) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kResetMineFieldNotification
                                                            object:nil];
        
        [self performSelector:@selector(resetMine) withObject:nil afterDelay:0.1f];
    }
}

- (IBAction)validateMineField:(UIButton *)sender {
    [self stopTimer];
    
    if (_revealedTileCount < GRID_SIZE) {
        _isFailed = !(self.revealedTileCount == MAX_HIDDEN_MINES);
        [self finalResult];
    }
}

- (void)gameOver {
    [self stopTimer];
    _isFailed = YES;
    [self finalResult];
}

- (void)showAlertWithMessage: (NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Minesweeper"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                
                                            }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Mine Field Delegate
- (void)mineFieldValidationSuccess {
    self.validationCount--;
    
}

- (void)mineFieldValidationFailure {
    self.validationCount--;
    _isFailed = YES;
}

- (void)finalResult {
    [self stopTimer];
    if (_isFailed) {
        NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"bomb" ofType:@"mp3"];
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
        
        if (!self.audioPlayer) {
            NSError *error;
            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&error];
            self.audioPlayer.numberOfLoops = 0;
        }
        [self.audioPlayer play];
        
        [self showAlertWithMessage:@"Game Over!!"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowAllHiddenMinesNotification
                                                                object:nil];
        });
        _revealedTileCount = 0;
    } else {
        [self showAlertWithMessage:@"Congratulations!!"];
    }
    [self.carpetView.superview bringSubviewToFront:self.carpetView];
}

#pragma  mark - Mine Calculations
- (void)resetMine {
    _revealedTileCount = GRID_SIZE;
    _validationCount = GRID_SIZE;
    _isFailed = NO;
    _timerSeconds = 0;

    [self.carpetView.superview sendSubviewToBack:self.carpetView];
    
    if (!_hiddenMinePositions) {
        _hiddenMinePositions = [NSMutableArray arrayWithCapacity:MAX_HIDDEN_MINES];
    } else {
        [_hiddenMinePositions removeAllObjects];
    }
    
    [self randomlyChoseMinePositions];
    [self startTimer];
}

- (void)randomlyChoseMinePositions {
    NSMutableDictionary *neighborMinesCountDict = [NSMutableDictionary new];
    
    // get 10 random numbers between 0 and 63
    do {
        int tilePosition = arc4random_uniform(GRID_SIZE);
        
        if ([_hiddenMinePositions indexOfObject:@(tilePosition)] == NSNotFound) {
            [_hiddenMinePositions addObject:@(tilePosition)];
            [neighborMinesCountDict removeObjectForKey:@(tilePosition)];
            
            [self secureMineAt:tilePosition archive:neighborMinesCountDict];
            
            // Mark tiles as hiding mines
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(NSInteger)tilePosition inSection:0];
            MineTileCollectionViewCell *cell = (MineTileCollectionViewCell *) [self.collectionView cellForItemAtIndexPath:indexPath];
            cell.hidesMine = YES;
        }
    } while (_hiddenMinePositions.count < MAX_HIDDEN_MINES);
    
    // update neighboring mine count for all tiles
    [neighborMinesCountDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *  _Nonnull key, NSNumber *  _Nonnull obj, BOOL * _Nonnull stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:key.integerValue inSection:0];
        MineTileCollectionViewCell *cell = (MineTileCollectionViewCell *) [self.collectionView cellForItemAtIndexPath:indexPath];
        if (!cell.hidesMine) {
            cell.neighboringMineCount = obj.integerValue;
        }
    }];
}

- (void)secureMineAt:(int)position archive:(NSMutableDictionary *)dict {
    NSArray *neighborPositions = [self getValidNeighborPositionsFor:position];
    for (NSNumber *aPos in neighborPositions) {
        // Proceed only if neighboring tile does not hide a mine
        if ([_hiddenMinePositions indexOfObject:aPos] == NSNotFound) {
            NSNumber *count = dict[aPos] ? dict[aPos] : @(0);
            dict[aPos] = @(count.intValue + 1);
        }
    }
}

- (NSArray *)getValidNeighborPositionsFor:(int)position {
    int row = ROW_FROM_INDEX(position);
    int column = COLUMN_FROM_INDEX(position);
    
    NSMutableArray *neighborPositions = [NSMutableArray array];
    if (IS_VALID_ROW(row-1)) {
        if (IS_VALID_COLUMN(column-1)) {
            [neighborPositions addObject:@(INDEXIFY(row-1, column-1))];
        }
        [neighborPositions addObject:@(INDEXIFY(row-1, column))];
        if (IS_VALID_COLUMN(column+1)) {
            [neighborPositions addObject:@(INDEXIFY(row-1, column+1))];
        }
    }
    if (IS_VALID_COLUMN(column-1)) {
        [neighborPositions addObject:@(INDEXIFY(row, column-1))];
    }
    if (IS_VALID_COLUMN(column+1)) {
        [neighborPositions addObject:@(INDEXIFY(row, column+1))];
    }
    
    if (IS_VALID_ROW(row+1)) {
        if (IS_VALID_COLUMN(column-1)) {
            [neighborPositions addObject:@(INDEXIFY(row+1, column-1))];
        }
        [neighborPositions addObject:@(INDEXIFY(row+1, column))];
        if (IS_VALID_COLUMN(column+1)) {
            [neighborPositions addObject:@(INDEXIFY(row+1, column+1))];
        }
    }
    return neighborPositions;
}

- (void)cascadeTapFromCell:(MineTileCollectionViewCell *)cell atPosition:(int)position {
    if (!cell.isEnabled || cell.tapped) {
        return;
    }
    cell.tapped = YES;
    self.revealedTileCount--;
    if (cell.hidesMine) {
        [self gameOver];
    } else if (cell.neighboringMineCount <= 0) {
        NSArray *neighborPositions = [self getValidNeighborPositionsFor:position];
        for (NSNumber *aPos in neighborPositions) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:aPos.integerValue inSection:0];
            MineTileCollectionViewCell *nextCell = (MineTileCollectionViewCell *) [self.collectionView cellForItemAtIndexPath:indexPath];
            [self cascadeTapFromCell:nextCell atPosition:aPos.intValue];
        }
    }
    
}

#pragma mark - Collection View Data Source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return GRID_SIZE;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MineTileCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kMineTileReuseIdentifier forIndexPath:indexPath];
    [cell initialSetup];
    cell.indexPosition = indexPath.row;
    cell.mineFieldDelegate = self;
    return cell;
}

#pragma mark - Collection View Delegate - Flow Layout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat tileWidth = self.referenceBackgroundImageView.frame.size.width / MAX_ROWS_COLUMN;
    CGFloat tileHeight = self.referenceBackgroundImageView.frame.size.height / MAX_ROWS_COLUMN;
    return CGSizeMake(tileWidth, tileHeight);
}

#pragma mark - Collection View Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    MineTileCollectionViewCell *cell = (MineTileCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self cascadeTapFromCell:cell atPosition:(int)indexPath.row];
}

#pragma mark - Timer
- (void)startTimer {
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTimer) userInfo:nil repeats:true];
    
    self.timerLabel.text = [NSString stringWithFormat:@"00:00:00"];
}

- (void)stopTimer {
    
    [_updateTimer invalidate];
    _updateTimer = nil;
}

- (void)updateTimer {
    _timerSeconds++;
    NSUInteger hours = _timerSeconds / 3600;
    NSUInteger remainder = _timerSeconds % 3600;
    NSUInteger minutes = remainder / 60;
    remainder %= 60;
    self.timerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", hours, minutes, remainder];
}

@end
