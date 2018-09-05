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
@class AVAssetExportSession;
@class UIColor;

typedef void(^ExportCancellationBlock)(void);

@interface VPExporter : NSObject

- (void)cancelExport;
- (void)exportVideoAsset:(AVAsset *)asset layer:(CALayer *)canvasLayer completionBlock:(void(^)(NSURL *URL, NSError *error))completionBlock progressBlock:(void(^)(NSInteger progressPercent,UIColor *color))progressBlock failureBlock:(void(^)(void))failureBlock;

@property (nonatomic) AVAssetExportSession *exporterSession;

@end
