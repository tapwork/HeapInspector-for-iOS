//
//  RMClassDumpTableViewController.h
//  HeapInspectorExample
//
//  Created by Christian Menschel on 01.09.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "RMTableViewController.h"

typedef NS_ENUM(NSUInteger, RMClassDumpType) {
    RMClassDumpMethods,
    RMClassDumpProperties,
    RMClassDumpIvar,
    RMClassDumpClasses
};

@interface RMClassDumpTableViewController : RMTableViewController

- (instancetype)initWithObject:(id)object type:(RMClassDumpType)type;

@end
