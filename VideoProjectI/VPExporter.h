//
//  VPExporter.h
//  VideoProjectI
//
//  Created by Gohar Vardanyan on 8/27/18.
//  Copyright © 2018 Gohar Vardanyan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVAsset;
@class CALayer;
@class BFCancellationTokenSource;
@class AVAssetExportSession;

typedef NS_ENUM(NSUInteger, VPAnimationLayerType) {
    VPAnimationLayerStickers = 0,
    VPAnimationLayerWatermark = 1
};

typedef void(^ExportCancellationBlock)(void);

@interface VPExporter : NSObject

- (void)exportVideoAsset:(AVAsset *)asset layer:(CALayer *)canvasLayer completionBlock:(void(^)(NSURL *URL, NSError *error))completionBlock progressBlock:(void(^)(float progress, VPAnimationLayerType layerType))progressBlock failureBlock:(void(^)(void))failureBlock;

@property (nonatomic) BFCancellationTokenSource *cancellationToken;
@property (copy, nonatomic) ExportCancellationBlock exportCanccelationBlock;
@property (nonatomic) AVAssetExportSession *exporterSession;


@end
