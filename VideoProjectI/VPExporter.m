//
//  VPExporter.m
//  VideoProjectI
//
//  Created by Gohar Vardanyan on 8/27/18.
//  Copyright © 2018 Gohar Vardanyan. All rights reserved.
//

#import "VPExporter.h"
#import <AVKit/AVKit.h>
#import "CALayer+Additions.h"
#import "AVAsset+VPAdditions.h"
#import <Bolts/Bolts.h>

typedef NS_ENUM(NSUInteger, VPAnimationLayerType) {
    VPAnimationLayerStickers = 0,
    VPAnimationLayerWatermark = 1
};

@interface VPExporter()

@property (nonatomic) void(^progressBlock)(NSInteger progress, UIColor *color);
@property (nonatomic) void(^completionBlock)(NSURL *URL, NSError *error);
@property (nonatomic) AVAsset *asset;
@property (nonatomic) AVMutableVideoComposition *mainCompositionInst;
@property (nonatomic) CALayer *canvasLayer;
@property (nonatomic) VPAnimationLayerType layerType;
@property (nonatomic) BFCancellationTokenSource *cancellationToken;

@end

@implementation VPExporter

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.cancellationToken = [BFCancellationTokenSource cancellationTokenSource];
    [self.cancellationToken.token registerCancellationObserverWithBlock:^{
        NSLog(@"is canccelation requested %d.",self.cancellationToken.isCancellationRequested);
    }];
}

- (void)exportVideoAsset:(AVAsset *)asset layer:(CALayer *)canvasLayer completionBlock:(void(^)(NSURL *URL, NSError *error))completionBlock progressBlock:(void(^)(NSInteger progress, UIColor *color))progressBlock failureBlock:(void(^)(void))failureBlock {
    
    self.asset = asset;
    self.canvasLayer = canvasLayer;
    self.completionBlock = completionBlock;
    self.progressBlock = progressBlock;
    self.layerType = VPAnimationLayerStickers;
    [[self exportVideoAsync:self.cancellationToken] continueWithSuccessBlock:^id _Nullable(BFTask * _Nonnull t) {
        if (t.error || [[t.result class] isEqual:[NSError class]]) {
            if (failureBlock) {
            failureBlock();
            }
            return t;
        } else {
            self.asset = [AVAsset assetWithURL:t.result];
            self.layerType = VPAnimationLayerWatermark;
            return [[self exportVideoAsync:self.cancellationToken] continueWithSuccessBlock:^id _Nullable(BFTask * _Nonnull t) {
                if (t.error || [[t.result class] isEqual:[NSError class]]) {
                    if (failureBlock) {
                    failureBlock();
                    }
                } else {
                    if (completionBlock) {
                    self.completionBlock(t.result, nil);
                    }
                }
                return t;
            } cancellationToken:self.cancellationToken.token];
        }
    } cancellationToken:self.cancellationToken.token];
}

- (BFTask *)exportVideoAsync:(BFCancellationTokenSource *)cancellationToken {
    BFTaskCompletionSource *successful = [BFTaskCompletionSource taskCompletionSource];
    AVMutableComposition *composition = [self compositionForExport];
    
    [self setupLayerForAnimation];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"FinalVideo.mov"]];
    
    [[NSFileManager defaultManager] removeItemAtPath:myPathDocs error:nil];
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    
    self.exporterSession = [[AVAssetExportSession alloc] initWithAsset:composition
                                                            presetName:AVAssetExportPresetHighestQuality];
    self.exporterSession.outputURL = url;
    self.exporterSession.outputFileType = AVFileTypeQuickTimeMovie;
    self.exporterSession.shouldOptimizeForNetworkUse = YES;
    self.exporterSession.videoComposition = self.mainCompositionInst;
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateExportProgress) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    
    [self.exporterSession exportAsynchronouslyWithCompletionHandler:^{
        [timer invalidate];
            switch (self.exporterSession.status) {
                case AVAssetExportSessionStatusCancelled:
                    [successful cancel];
                    break;
                case AVAssetExportSessionStatusCompleted:
                    [successful setResult:self.exporterSession.outputURL];
                    break;
                case AVAssetExportSessionStatusFailed:
                    [successful setError:self.exporterSession.error];
                    break;
                default:
                    [successful setResult:self.exporterSession.outputURL];
                    break;
        }
    }];
    return successful.task;
}

- (AVMutableComposition *)compositionForExport {
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *videoAssetTrack = [self.asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration)
                              ofTrack:videoAssetTrack
                               atTime:kCMTimeZero error:nil];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.asset.duration);
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionTrack];
    [layerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [layerInstruction setOpacity:0.0 atTime:self.asset.duration];
    instruction.layerInstructions = @[layerInstruction];
    
    CGSize naturalSize = [self.asset videoSize];
    self.mainCompositionInst = [AVMutableVideoComposition videoComposition];
    self.mainCompositionInst.renderSize = naturalSize;
    self.mainCompositionInst.instructions = [NSArray arrayWithObject:instruction];
    self.mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    return composition;
}

- (void)setupLayerForAnimation {
    CGSize naturalSize = [self.asset videoSize];
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
    videoLayer.frame = parentLayer.bounds;
    parentLayer.geometryFlipped = YES;
    
    [parentLayer addSublayer:videoLayer];
    CALayer *layer = nil;
    if (self.layerType == VPAnimationLayerStickers) {
        layer = [self stickerAnimationLayer:(CGPointMake(CGRectGetMidX(parentLayer.bounds), CGRectGetMidY(parentLayer.bounds)))];
    } else if (self.layerType == VPAnimationLayerWatermark) {
        layer = [self watermarkAnimationLayer];
    }
    [parentLayer addSublayer:layer];
    
    self.mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool
                                              videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

- (void)updateExportProgress {
    NSInteger progress = 0;
    if (self.layerType == VPAnimationLayerStickers) {
        progress = self.exporterSession.progress * 50;
        self.progressBlock(progress, [UIColor blueColor]);
    } else {
        progress = self.exporterSession.progress * 50 + 50;
        self.progressBlock(progress, [UIColor purpleColor]);
    }
}

- (CALayer *)stickerAnimationLayer:(CGPoint)position {
    CGSize naturalSize = [self.asset videoSize];
    
    CGFloat fl = naturalSize.width / self.canvasLayer.bounds.size.width;
    CALayer *layer = [self.canvasLayer clone];
    layer.affineTransform = CGAffineTransformMakeScale(fl, fl);
    
    layer.position = position;
    
    return layer;
}

- (CALayer *)watermarkAnimationLayer {
    UIImage *watermark = [UIImage imageNamed:@"watermark"];
    
    CALayer *layer = [CALayer layer];
    
    CGSize naturalSize = [self.asset videoSize];
    if (naturalSize.width > naturalSize.height) {
        layer.frame = CGRectMake(15.0, 0.0, [self.asset videoSize].height * 0.3, [self.asset videoSize].height * 0.3);
    } else {
        layer.frame = CGRectMake(15.0, 0.0, [self.asset videoSize].height * 0.1, [self.asset videoSize].height * 0.1);
    }
    [layer setContents:(id)[watermark CGImage]];
    
    return layer;
}

- (void)cancelExport {
    [self.cancellationToken cancel];
    [self.exporterSession cancelExport];
    self.exporterSession = nil;
}

@end
