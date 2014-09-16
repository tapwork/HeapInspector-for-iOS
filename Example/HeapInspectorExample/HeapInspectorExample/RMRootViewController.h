//
//  RMRootViewController.h
//  HeapInspectorExample
//
//  Created by Christian Menschel on 20.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RMRootViewController : UIViewController

// The strong reference will retain the detailViewController,
// so the ViewController won't be deallocated after popping back
@property (nonatomic) UIViewController *strongDetailViewController;


@end
