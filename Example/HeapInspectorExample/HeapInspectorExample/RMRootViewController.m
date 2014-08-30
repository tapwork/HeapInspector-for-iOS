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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Open Details" forState:UIControlStateNormal];
    CGSize buttonSize = CGSizeMake(200, 50);
    button.frame = CGRectMake(floorf((self.view.bounds.size.width - buttonSize.width)/2),
                              floorf((self.view.bounds.size.height - buttonSize.height)/2),
                              buttonSize.width,
                              buttonSize.height);
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:button];
}

- (void)buttonTapped:(id)sender
{
    RMDetailViewController *details = [[RMDetailViewController alloc] init];
    self.strongDetailViewController = details;
    //self.weakDetailViewController = details;
    [self.navigationController pushViewController:details animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
