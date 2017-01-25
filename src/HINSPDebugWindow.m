//
//  RMDebugWindow.m
//
//
//  Created by Christian Menschel on 16.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "HINSPDebugWindow.h"
#import "NSObject+HeapInspector.h"

@implementation HINSPDebugWindow
{
    UIView *_contentView;
    UIView *_dragView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        // Initialization code
        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = [UIColor colorWithWhite:0.94 alpha:0.94];
        [self addSubview:_contentView];
        
        _recordButton = [[HINSPRecordButton alloc] init];
        [_contentView addSubview:_recordButton];
        
        UIPanGestureRecognizer *pangesture = [[UIPanGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(panGestureAction:)];
        _dragView = [[UIView alloc] init];
        _dragView.backgroundColor = [UIColor darkGrayColor];
        [_dragView addGestureRecognizer:pangesture];
        [_contentView addSubview:_dragView];
        
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.font = [UIFont systemFontOfSize:10];
        _infoLabel.numberOfLines = 2;
        _infoLabel.backgroundColor = [UIColor clearColor];
        [_contentView addSubview:_infoLabel];
        
        _recordedButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _recordButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _recordedButton.hidden = YES;
        [_recordedButton setTitle:@"Recorded Heap" forState:UIControlStateNormal];
        [_contentView addSubview:_recordedButton];
        
        _activeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_activeButton setTitle:@"Heap" forState:UIControlStateNormal];
        [_contentView addSubview:_activeButton];
    }
    return self;
}

static const CGFloat kDragViewWidth = 25.0f;
static const CGFloat kRecordButtonLeftOffset = 10.0f;
static const CGFloat kInfoLabelLeftOffset = 10.0f;
static const CGFloat kInfoLabelHeight = 20.0f;
static const CGFloat kActiveButtonWidth = 85.0f;
static const CGFloat kButtonHeight = 20.0f;
static const CGFloat kRecordedButtonWidth = 110.0f;
static const CGFloat kContentViewHeight = 50.0f;
static const CGFloat kContentViewY = 80.0f;

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect contentViewRect = _contentView.frame;
    if (_contentView.frame.size.width == 0.0) {
        contentViewRect.origin.y = kContentViewY;
    }
    contentViewRect.size.width = [UIScreen mainScreen].bounds.size.width;
    contentViewRect.size.height = kContentViewHeight;
    _contentView.frame = contentViewRect;
    
    CGSize recordButtonSize = CGSizeMake(_contentView.bounds.size.height/1.5,
                                         _contentView.bounds.size.height/1.5);
    _recordButton.frame = CGRectMake(kRecordButtonLeftOffset,
                                     floorf((_contentView.bounds.size.height - recordButtonSize.height)/2),
                                     recordButtonSize.width,
                                     recordButtonSize.height);

    _dragView.frame = CGRectMake(_contentView.bounds.size.width - kDragViewWidth,
                                 0.0f,
                                 kDragViewWidth,
                                 _contentView.bounds.size.height);
    CGFloat x = CGRectGetMaxX(_recordButton.frame) + kInfoLabelLeftOffset;
    CGFloat width = _contentView.bounds.size.width - _dragView.bounds.size.width - x;

    _infoLabel.frame = CGRectMake(x,
                                  _contentView.bounds.size.height - kInfoLabelHeight,
                                  width,
                                  kInfoLabelHeight);
    
    CGFloat buttonY = floorf((_contentView.bounds.size.height - kButtonHeight)/2);
    _recordedButton.frame = CGRectMake(_infoLabel.frame.origin.x - 2.0,
                                       buttonY,
                                       kRecordedButtonWidth,
                                       kButtonHeight);
    
    _activeButton.frame = CGRectMake(CGRectGetMaxX(_recordedButton.frame) + 20.0,
                                     buttonY,
                                     kActiveButtonWidth,
                                     kButtonHeight);
    

}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL allowTouch = NO;
    if (CGRectContainsPoint(_contentView.frame, point)) {
        allowTouch = YES;
    }
    if (self.rootViewController.presentedViewController) {
        allowTouch = YES;
    }
    return allowTouch;
}

- (void)panGestureAction:(UIPanGestureRecognizer *)panGesture
{
    if (panGesture.state == UIGestureRecognizerStateChanged) {
        CGFloat selfHeight = _contentView.bounds.size.height;
        CGPoint newCenter = _contentView.center;
       // newCenter.x += [panGesture translationInView:self].x;
        newCenter.y += [panGesture translationInView:self].y;
        // Reset the translation of the recognizer.
        [panGesture setTranslation:CGPointZero inView:self];
        if (newCenter.y > selfHeight &&
            newCenter.y < [UIScreen mainScreen].bounds.size.height - selfHeight) {
                    _contentView.center = newCenter;
        }
    }
}

@end
