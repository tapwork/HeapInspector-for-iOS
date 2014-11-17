//
//  RMRootViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 20.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "RMRootViewController.h"
#import "RMGalleryWrongViewCotroller.h"

@interface RMRootViewController () <RMGalleryWrongViewCotrollerDelegate>

@end

@implementation RMRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGSize buttonSize = CGSizeMake(200, 50);
    UIButton *gallerybutton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [gallerybutton addTarget:self action:@selector(buttonLeakTapped:) forControlEvents:UIControlEventTouchUpInside];
    [gallerybutton setTitle:@"Gallery" forState:UIControlStateNormal];
    gallerybutton.frame = CGRectMake(floorf((self.view.bounds.size.width - buttonSize.width)/2),
                                floorf((self.view.bounds.size.height - buttonSize.height)/2),
                                buttonSize.width,
                                buttonSize.height);
    
    gallerybutton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:gallerybutton];
}

- (void)buttonLeakTapped:(id)sender
{
    self.detailViewController = [[RMGalleryWrongViewCotroller alloc] init];
    self.detailViewController.delegate = self;
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}


@end
