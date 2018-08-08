//
//  CALayer+Additions.m
//  VideoProjectI
//
//  Created by Gohar Vardanyan on 8/3/18.
//  Copyright © 2018 Gohar Vardanyan. All rights reserved.
//

#import "CALayer+Additions.h"

@implementation CALayer (Additions)

- (CALayer *)clone {
   CALayer *layer = [[self.class alloc] init];
    layer.contents = self.contents;
    layer.bounds = self.bounds;
    layer.transform = self.transform;
    layer.position = self.position;
    layer.anchorPoint = self.anchorPoint;
    layer.backgroundColor = self.backgroundColor;
    
    for (CALayer *l in self.sublayers) {
        [layer addSublayer:[l clone]];
    }
    return layer;
}


@end
