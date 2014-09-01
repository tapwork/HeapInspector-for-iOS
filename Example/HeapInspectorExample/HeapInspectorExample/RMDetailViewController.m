//
//  RMDetailViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 20.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "RMDetailViewController.h"

@interface RMDetailViewController ()

@end

@implementation RMDetailViewController


- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor colorWithRed:0.8 green:0.9 blue:0.9 alpha:1.0];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    CGRect bounds = label.bounds;
    bounds.size.width = 250.0f;
    bounds.size.height = 50.0f;
    label.bounds = bounds;
    label.center = self.view.center;
    if (self.isStrongRetained) {
        label.text = @"I am strong retained";
    } else {
        label.text = @"I am weak";
    }
    [self.view addSubview:label];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
