//
//  RMGaleryCollectionViewCell.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 12/11/14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "RMGaleryCollectionViewCell.h"

@interface RMGaleryCollectionViewCell ()

@property (nonatomic) UIImageView *imageView;

@end

@implementation RMGaleryCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] init];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.imageView];
        
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imageView.frame = self.bounds;
}

@end
