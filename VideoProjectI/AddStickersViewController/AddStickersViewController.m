//
//  AddStickersViewController.m
//  VideoProjectI
//
//  Created by Gohar Vardanyan on 8/1/18.
//  Copyright © 2018 Gohar Vardanyan. All rights reserved.
//

#import "AddStickersViewController.h"
#import "AddStickersCollectionViewCell.h"
#import <AVKit/AVKit.h>
#import "CALayer+Additions.h"

@interface AddStickersViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic) AVAsset *videoAsset;
@property (nonatomic) AVPlayer *player;
@property (weak, nonatomic) IBOutlet UIView *contetnView;
@property (weak, nonatomic) IBOutlet UIView *stickerCanvas;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) UITapGestureRecognizer *tapGestureForPlayer;
@property (nonatomic) UIImageView *tapedImageView;
@property (readonly) BOOL isPlaying;
@property (nonatomic) NSMutableArray *stickers;
@property (nonatomic) UIImageView *duplicateImageView;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (readonly) BOOL isEpty;

@end

@implementation AddStickersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setHidden:NO];
    [self navigationBarRightItem:self.navigationItem];
    
    self.stickers = [[NSMutableArray alloc] initWithObjects:@"starI", @"starII", @"starIII", @"starIV", @"starV", @"starVI", @"starVII", @"starVIII", @"starIX", nil];
    
    [self addVideoPlayer];
    [self addGestures];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.view bringSubviewToFront:self.contetnView];

}

- (void)addVideoPlayer {
    //something
    self.videoAsset = [AVAsset assetWithURL:self.chosenVideoURL];
    self.player = [[AVPlayer alloc] initWithURL:self.chosenVideoURL];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.player currentItem]];
    
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.contetnView.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.needsDisplayOnBoundsChange = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
    
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.contetnView.layer insertSublayer:self.playerLayer atIndex:0];
    self.stickerCanvas.backgroundColor = [UIColor clearColor];
    
    [self.player play];
    
    [self dismissViewControllerAnimated:YES completion:^{
        self.navigationController.navigationBar.hidden = NO;
    }];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *playerItem = [notification object];
    [playerItem seekToTime:kCMTimeZero completionHandler:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
    if (status == AVPlayerStatusReadyToPlay) {
        self.stickerCanvas.frame = self.playerLayer.videoRect;
        self.stickerCanvas.userInteractionEnabled = YES;
        self.stickerCanvas.layer.masksToBounds = YES;
    }
}

- (void)addGestures {
    UITapGestureRecognizer *tapGestureForPlayer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playerTapGestureAction:)];
    self.tapGestureForPlayer = tapGestureForPlayer;
    tapGestureForPlayer.delegate = self;
    [self.contetnView addGestureRecognizer:tapGestureForPlayer];
    
    UITapGestureRecognizer *tapGestureForCollectionView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(collectionViewTapAction:)];
    [self.collectionView addGestureRecognizer:tapGestureForCollectionView];
    
    UILongPressGestureRecognizer *longPressgesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerAction:)];
    longPressgesture.minimumPressDuration = 0.3;
    [self.collectionView addGestureRecognizer:longPressgesture];
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureAction:)];
    pinchGesture.delegate = self;
    [self.contetnView addGestureRecognizer:pinchGesture];
    
    UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationGestureAction:)];
    rotationGesture.delegate = self;
    [self.contetnView addGestureRecognizer:rotationGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizer:)];
    [self.contetnView addGestureRecognizer:panGesture];
}

#pragma mark - Gesture Actiions

- (void)playerTapGestureAction:(UITapGestureRecognizer *)gesture {
    self.player.rate = !self.player.rate;
}

- (void)collectionViewTapAction:(UITapGestureRecognizer *)gesture {
    CGPoint touchPoint = [gesture locationInView:self.collectionView];
    NSIndexPath *selectedCellIndexPath = [self.collectionView indexPathForItemAtPoint:touchPoint];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:selectedCellIndexPath];
    
    UIImageView *imageView = (UIImageView *)cell.contentView.subviews.firstObject;
    CGFloat imageSize = self.stickerCanvas.frame.size.height * 0.3;
    NSInteger randomX = arc4random() % ((int)self.stickerCanvas.frame.size.width - (int)imageSize);
    NSInteger randomY = arc4random() % ((int)self.stickerCanvas.frame.size.height - (int)imageSize);
    
    self.duplicateImageView = [[UIImageView alloc] initWithImage:imageView.image];
    self.duplicateImageView.frame = CGRectMake((CGFloat)randomX, (CGFloat)randomY, imageSize, imageSize);
    [self checktapedSticker:self.duplicateImageView];

    [self addTapGestureForChoosenImageView:self.duplicateImageView];
    
    [self.stickerCanvas addSubview:self.duplicateImageView];
}

- (void)checktapedSticker:(UIImageView *)imageview {
    if (self.tapedImageView) {
    self.tapedImageView.layer.borderColor = [UIColor clearColor].CGColor;
    }
    self.tapedImageView = imageview;
    self.tapedImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.tapedImageView.layer.borderWidth = 1.5;
}

- (void)longPressGestureRecognizerAction:(UILongPressGestureRecognizer *)longPressGesture {
    CGPoint touchPoint = [longPressGesture locationInView:self.collectionView];
    NSIndexPath *selectedCellIndexPath = [self.collectionView indexPathForItemAtPoint:touchPoint];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:selectedCellIndexPath];
    
    CGPoint touchPointInView = [longPressGesture locationInView:self.contetnView];
    
    if (longPressGesture.state ==  UIGestureRecognizerStateBegan) {
        UIImageView *imageView = (UIImageView *)[cell.contentView.subviews objectAtIndex:0];
        self.duplicateImageView = [[UIImageView alloc] initWithImage:imageView.image];
        CGFloat imageSize = self.stickerCanvas.frame.size.height * 0.3;
        self.duplicateImageView.frame = CGRectMake(0, 0, imageSize, imageSize);
        self.duplicateImageView.center = CGPointMake(touchPointInView.x, touchPointInView.y);
        
        [self.contetnView addSubview:self.duplicateImageView];
    } else if (longPressGesture.state == UIGestureRecognizerStateChanged) {
        self.duplicateImageView.center = CGPointMake(touchPointInView.x, touchPointInView.y);
    } else if (longPressGesture.state == UIGestureRecognizerStateEnded) {
        if (CGRectContainsPoint(self.stickerCanvas.frame, self.duplicateImageView.frame.origin)) {
            CGRect rectInCanvasView = [self.contetnView convertRect:self.duplicateImageView.frame toView:self.stickerCanvas];
            self.duplicateImageView.frame = rectInCanvasView;
            [self addTapGestureForChoosenImageView:self.duplicateImageView];
            [self checktapedSticker:self.duplicateImageView];
            [self.stickerCanvas addSubview:self.duplicateImageView];
            self.duplicateImageView = nil;
        } else {
            [self.duplicateImageView removeFromSuperview];
        }
    }
}

- (void)pinchGestureAction:(UIPinchGestureRecognizer *)gesture {
    if (self.tapedImageView != nil && (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged)) {
        CGRect bounds = self.tapedImageView.bounds;
        CGPoint pinchCenter = [gesture locationInView:self.tapedImageView];
        pinchCenter.x -= CGRectGetMidX(bounds);
        pinchCenter.y -= CGRectGetMidY(bounds);
        CGAffineTransform transform = self.tapedImageView.transform;
        transform = CGAffineTransformTranslate(transform, pinchCenter.x, pinchCenter.y);
        CGFloat scale = gesture.scale;
        transform = CGAffineTransformScale(transform, scale, scale);
        transform = CGAffineTransformTranslate(transform, -pinchCenter.x, -pinchCenter.y);
        self.tapedImageView.transform = transform;
        gesture.scale = 1.0;
    }
}

- (void)rotationGestureAction:(UIRotationGestureRecognizer *)gesture {
    if (self.tapedImageView != nil && (gesture.state == UIGestureRecognizerStateBegan || gesture.state ==  UIGestureRecognizerStateChanged)) {
        self.tapedImageView.transform = CGAffineTransformRotate(self.tapedImageView.transform, gesture.rotation);
        gesture.rotation = 0;
    }
}

- (void)panGestureRecognizer:(UIPanGestureRecognizer *)gesture {
    CGPoint transition = [gesture translationInView:self.stickerCanvas];
    self.tapedImageView.center = CGPointMake(self.tapedImageView.center.x + transition.x, self.tapedImageView.center.y + transition.y);
    [gesture setTranslation:CGPointZero inView:self.stickerCanvas];
}

- (void)addTapGestureForChoosenImageView:(UIImageView *)imageView {
    UITapGestureRecognizer *tapGestureForChoosenSticker = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureForChoosenStickerAction:)];
    tapGestureForChoosenSticker.delegate = self;
    imageView.userInteractionEnabled = YES;
    [imageView addGestureRecognizer:tapGestureForChoosenSticker];
}

- (void)tapGestureForChoosenStickerAction:(UITapGestureRecognizer *)gesture {
    [self checktapedSticker:(UIImageView *)gesture.view];
    [self.stickerCanvas bringSubviewToFront:self.tapedImageView];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return  self.stickers.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AddStickersCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    UIImageView *sticker = [[UIImageView alloc] initWithImage:[UIImage imageNamed:self.stickers[indexPath.item]]];
    if (cell.contentView.subviews.count != 0) {
        [[cell.contentView.subviews firstObject] removeFromSuperview];
    }
    
    [cell fillCellWithImage:sticker];
    return cell;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([gestureRecognizer isEqual:self.tapGestureForPlayer]) {
        CGPoint touchLocat = CGPointZero;
        BOOL isContained = NO;
        for (UIImageView *imageView in self.stickerCanvas.subviews) {
            touchLocat = [touch locationInView:imageView];
            isContained = CGRectContainsPoint(imageView.bounds, touchLocat);
            if (isContained) {
                break;
            }
        }
        return !isContained;
    } else {
        return YES;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - RightBarButtonAction

- (void)rightItemAction {
    if (!self.isEpty) {
        [self addStickersOnVideo];
    } else {
        [self showAlertWithTitle:@"There is no choosen stickers" withMessage:@"Please add stickers on the video"];
    }
}

- (void)addStickersOnVideo {
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *videoAssetTrack = [self.videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    assert(videoAssetTrack);
    [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration)
                              ofTrack:videoAssetTrack
                               atTime:kCMTimeZero error:nil];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.videoAsset.duration);
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionTrack];
    [layerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [layerInstruction setOpacity:0.0 atTime:self.videoAsset.duration];
    
    instruction.layerInstructions = @[layerInstruction];
    
    CGSize naturalSize = CGSizeApplyAffineTransform(videoAssetTrack.naturalSize, videoAssetTrack.preferredTransform);
    naturalSize = CGSizeMake(fabs(naturalSize.width), fabs(naturalSize.height));
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.renderSize = naturalSize;
    mainCompositionInst.instructions = [NSArray arrayWithObject:instruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    
    [self addAniamtionOnComposition:mainCompositionInst videoSize:naturalSize];
    
    [self exportVideoForComposition:composition videoComposition:mainCompositionInst];
    
}

- (void)addAniamtionOnComposition:(AVMutableVideoComposition *)videoComposition videoSize:(CGSize)videoSize {
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = parentLayer.bounds;
    parentLayer.geometryFlipped = YES;
    
    CGFloat fl = videoSize.width / self.stickerCanvas.layer.bounds.size.width;
    CALayer *layer = [self.stickerCanvas.layer clone];
    
    layer.affineTransform = CGAffineTransformMakeScale(fl, fl);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:layer];
    layer.position = CGPointMake(CGRectGetMidX(parentLayer.bounds), CGRectGetMidY(parentLayer.bounds));
    
    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool
                                      videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

- (void)exportVideoForComposition:(AVMutableComposition *)mixComposition videoComposition:(AVMutableVideoComposition *)mainCompositionInst {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"FinalVideo.mov"]];
    
    [[NSFileManager defaultManager] removeItemAtPath:myPathDocs error:nil];
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = url;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        AVPlayerViewController *vc = [[AVPlayerViewController alloc] init];
        AVPlayer *player = [[AVPlayer alloc] initWithURL:url];
        vc.player = player;
        [player play];
        [self presentViewController:vc animated:YES completion:nil];
    }];
}

- (void)showAlertWithTitle:(NSString *)title withMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)navigationBarRightItem:(UINavigationItem *)navigationItem {
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(rightItemAction)];
    navigationItem.rightBarButtonItem = rightItem;
    self.navigationController.navigationBar.alpha = 1.0;
    
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, navBarHeight, navBarHeight)];
    
    self.navigationItem.titleView = titleView;
    
    UIImage *image = [UIImage imageNamed:@"delete"];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(titleView.center.x - 10.0, titleView.center.y - 10.0, 20, 20)];
    deleteButton.imageView.tintColor = [UIColor blueColor];
    [deleteButton addTarget:self action:@selector(deleteButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [deleteButton setImage:image forState:UIControlStateNormal];
    [deleteButton.imageView setTintColor:[UIColor blueColor]];
    [navigationItem.titleView addSubview:deleteButton];
}

- (void)deleteButtonAction {
    [self.tapedImageView removeFromSuperview];
    //////////////////
}

- (BOOL)isPlaying {
    return self.player.rate != 0;
}

- (BOOL)isEpty {
    return !self.stickerCanvas.subviews.count;
}

- (void)dealloc {
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

@end
