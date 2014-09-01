//
//  RMShowViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 30.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "RMShowViewController.h"

@interface RMShowViewController ()

@end

@implementation RMShowViewController
{
    id _objectToInspect;
    UITextView *_textView;
    UIScrollView *_scrollView;
    
}

- (instancetype)initWithObject:(id)object
{
    self = [super init];
    if (self) {
        self.title = @"Showing View";
        self.edgesForExtendedLayout = UIRectEdgeNone;
        _objectToInspect = object;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_scrollView];
    
    [self setEditButton];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self handleClassType];
}

- (void)setEditButton
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Edit"
                                              style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(editButtonTapped:)];

}

- (void)setSaveButton
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Save"
                                              style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(saveButtonTapped:)];
    
}

#pragma mark - Actions

- (void)editButtonTapped:(id)sender
{
    _textView.editable = YES;
    [self setSaveButton];
}

- (void)saveButtonTapped:(id)sender
{
    if ([_objectToInspect isKindOfClass:[NSAttributedString class]]) {
        _objectToInspect = _textView.attributedText;
    } else if ([_objectToInspect isKindOfClass:[NSString class]]) {
        _objectToInspect = _textView.text;
    }
    _textView.editable = NO;
    [self setEditButton];
}

#pragma mark - Helper

- (void)handleClassType {
    UIImage *screenshot = nil;
    if ([_objectToInspect isKindOfClass:[UIView class]]) {
        screenshot = [self screenshotOfView:_objectToInspect];
    } else if ([_objectToInspect isKindOfClass:[UIViewController class]] &&
               [_objectToInspect isViewLoaded]) {
        screenshot = [self screenshotOfView:[_objectToInspect view]];
    } else if ([_objectToInspect isKindOfClass:[NSString class]] ||
               [_objectToInspect isKindOfClass:[NSAttributedString class]]) {
        UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _textView = textView;
        self.navigationItem.rightBarButtonItem.enabled = YES;
        [self.view addSubview:textView];
        
        if ([_objectToInspect isKindOfClass:[NSString class]]) {
            textView.text = _objectToInspect;
        } else if ([_objectToInspect isKindOfClass:[NSAttributedString class]]) {
            textView.attributedText = _objectToInspect;
        }
    }
    
    if (screenshot) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:screenshot];
        CGSize size = screenshot.size;
        imageView.bounds = CGRectMake(0.0,0.0,size.width,size.height);
        imageView.center = _scrollView.center;
        [_scrollView addSubview:imageView];
        _scrollView.contentSize = CGSizeMake(screenshot.size.width, screenshot.size.height);
    }
}

- (UIImage *)screenshotOfView:(UIView *)view
{
    CALayer *layer = [view layer];
    CGRect bounds = layer.bounds;
    
    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    {
        [layer renderInContext:context];
    }
    CGContextRestoreGState(context);
    
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return snapshot;
}

@end
