//
//  AVAssetTrack+VPAdditions.m
//  VideoProjectI
//
//  Created by Gohar Vardanyan on 8/27/18.
//  Copyright © 2018 Gohar Vardanyan. All rights reserved.
//

#import "AVAssetTrack+VPAdditions.h"

//import something
@implementation AVAssetTrack (VPAdditions)

- (CGSize)videoSize {
    CGSize videoSize = self.naturalSize;
    videoSize = CGSizeApplyAffineTransform(videoSize, self.preferredTransform);
    return CGSizeMake(fabs(videoSize.width), fabs(videoSize.height));
}

@end
