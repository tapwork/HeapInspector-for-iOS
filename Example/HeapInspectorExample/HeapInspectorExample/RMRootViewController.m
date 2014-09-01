//
//  RMRootViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 20.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "RMRootViewController.h"
#import "RMDetailViewController.h"

@interface RMRootViewController ()

@end

@implementation RMRootViewController
{
    NSMutableArray *_leakingObjectsContainer;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _leakingObjectsContainer = [@[] mutableCopy];
    
    CGSize buttonSize = CGSizeMake(200, 50);
    
    UIButton *s_button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [s_button addTarget:self action:@selector(buttonStrongTapped:) forControlEvents:UIControlEventTouchUpInside];
    [s_button setTitle:@"Open Details (strong)" forState:UIControlStateNormal];
   
    s_button.frame = CGRectMake(floorf((self.view.bounds.size.width - buttonSize.width)/2),
                              floorf((self.view.bounds.size.height - buttonSize.height)/2),
                              buttonSize.width,
                              buttonSize.height);
    
    UIButton *w_button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [w_button addTarget:self action:@selector(buttonWeakTapped:) forControlEvents:UIControlEventTouchUpInside];
    [w_button setTitle:@"Open Details (weak)" forState:UIControlStateNormal];
    w_button.frame = CGRectMake(floorf((self.view.bounds.size.width - buttonSize.width)/2),
                                CGRectGetMaxY(s_button.frame) + 5.0,
                                buttonSize.width,
                                buttonSize.height);
    
    UIButton *l_button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [l_button addTarget:self action:@selector(buttonLeakTapped:) forControlEvents:UIControlEventTouchUpInside];
    [l_button setTitle:@"Open Details (leaking)" forState:UIControlStateNormal];
    l_button.frame = CGRectMake(floorf((self.view.bounds.size.width - buttonSize.width)/2),
                                CGRectGetMaxY(w_button.frame) + 5.0,
                                buttonSize.width,
                                buttonSize.height);
    
    s_button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    w_button.autoresizingMask = s_button.autoresizingMask;
    l_button.autoresizingMask = s_button.autoresizingMask;
    [self.view addSubview:s_button];
    [self.view addSubview:w_button];
    [self.view addSubview:l_button];
}

- (void)buttonStrongTapped:(id)sender
{
    RMDetailViewController *details = [[RMDetailViewController alloc] init];
    details.isStrongRetained = YES;
    self.strongDetailViewController = details;
    [self.navigationController pushViewController:details animated:YES];
}

- (void)buttonWeakTapped:(id)sender
{
    RMDetailViewController *details = [[RMDetailViewController alloc] init];
    self.weakDetailViewController = details;
    [self.navigationController pushViewController:details animated:YES];
}

- (void)buttonLeakTapped:(id)sender
{
    RMDetailViewController *details = [[RMDetailViewController alloc] init];
    details.isStrongRetained = YES;
    [_leakingObjectsContainer addObject:details];
    [self.navigationController pushViewController:details animated:YES];
}


@end
