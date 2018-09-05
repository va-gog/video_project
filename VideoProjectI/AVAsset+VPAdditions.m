//
//  AVAsset+VPAdditions.m
//  VideoProjectI
//
//  Created by Gohar Vardanyan on 8/27/18.
//  Copyright © 2018 Gohar Vardanyan. All rights reserved.
//

#import "AVAsset+VPAdditions.h"
#import "AVAssetTrack+VPAdditions.h"

@implementation AVAsset (VPAdditions)

- (CGSize)videoSize {
    AVAssetTrack *videoAssetTrack = [self tracksWithMediaType:AVMediaTypeVideo].firstObject;
    if (!videoAssetTrack) {
        return CGSizeZero;
    }
    return [videoAssetTrack videoSize];
}

@end
