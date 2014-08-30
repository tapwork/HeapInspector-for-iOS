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
    UIView *_viewToShow;
}

- (instancetype)initWithObject:(id)object
{
    self = [super init];
    if (self) {
        self.title = @"Showing View";
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
        if ([object isKindOfClass:[UIView class]]) {
            _viewToShow = (UIView *)object;
        } else if ([object isKindOfClass:[UIViewController class]] &&
                [object isViewLoaded]) {
            _viewToShow = [object view];
        }
       
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.view addSubview:_viewToShow];
}



@end
