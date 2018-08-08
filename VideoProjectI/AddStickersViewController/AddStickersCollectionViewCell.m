//
//  AddStickersCollectionViewCell.m
//  VideoProjectI
//
//  Created by Gohar Vardanyan on 8/7/18.
//  Copyright © 2018 Gohar Vardanyan. All rights reserved.
//

#import "AddStickersCollectionViewCell.h"

@implementation AddStickersCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)fillCellWithImage:(UIImageView *)imageView {
    imageView.frame = self.contentView.frame;
    [self.contentView addSubview:imageView];
}

@end
