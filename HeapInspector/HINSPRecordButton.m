//
//  TWRecordButton.m
//  TT
//
//  Created by Christian Menschel on 18.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "HINSPRecordButton.h"


@interface HINSPRecordButton ()

@property (nonatomic) BOOL isRecording;

@end

@implementation HINSPRecordButton
{
    CAShapeLayer *__weak _shapeLayer;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    
    }
    return self;
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

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    UIColor *color = nil;
    if (highlighted) {
        color = [self pressedColor];
        self.isRecording = !self.isRecording;
    } else {
        color = [self defaultColor];
    }
    _shapeLayer.fillColor = color.CGColor;
}

- (UIColor*)defaultColor
{
    if (self.isRecording) {
        return [UIColor redColor];
    }
    return [UIColor grayColor];
}

- (UIColor*)pressedColor
{
    return [UIColor darkGrayColor];
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
