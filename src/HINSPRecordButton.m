//
//  TWRecordButton.m
//  TT
//
//  Created by Christian Menschel on 18.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "HINSPRecordButton.h"


@interface HINSPRecordButton ()
@property (nonatomic, weak) CAShapeLayer *shapeLayer;
@end

@implementation HINSPRecordButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

#pragma mark - Actions

- (void)tapped:(id)sender
{
    self.isRecording = !self.isRecording;
}

- (void)setIsRecording:(BOOL)isRecording {
    if (_isRecording != isRecording) {
        _isRecording = isRecording;
        UIColor *color = nil;
        if (isRecording) {
            color = [self recordingColor];
        } else {
            color = [self defaultColor];
        }
        _shapeLayer.fillColor = color.CGColor;
    }
}

#pragma mark - Setter

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    CAShapeLayer *shapeLayer = (CAShapeLayer*)self.layer;
    UIColor *color = [self defaultColor];
    shapeLayer.fillColor = color.CGColor;
    CGRect rect = CGRectMake(0.0f, 0.0f, frame.size.width,frame.size.height);
    CGPathRef path = CGPathCreateWithEllipseInRect(rect, NULL);
    shapeLayer.path = path;
    CGPathRelease(path);
    _shapeLayer = shapeLayer;
}

- (UIColor*)defaultColor
{
    if (self.isRecording) {
        return [UIColor redColor];
    }
    return [UIColor grayColor];
}

- (UIColor*)recordingColor
{
    return [UIColor redColor];
}

#pragma mark - Class methdods

+ (Class)layerClass {
    
    return [CAShapeLayer class];
}

@end
