//
//  RMHeapStackDetailTableViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 29.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "RMHeapStackDetailTableViewController.h"
#import "RMHeapStackInspector.h"
#import "RMResponderChainViewController.h"
#import "RMShowViewController.h"

static NSString *const kTableViewCellIdent = @"kTableViewCellIdent";

@interface RMHeapStackDetailTableViewController ()

@end

@implementation RMHeapStackDetailTableViewController
{
    id _inspectingObject;
    NSArray *_dataSource;
}
- (instancetype)initWithPointerString:(NSString *)pointer
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
         // Retrieve a real object from the pointer
        _inspectingObject = [RMHeapStackInspector objectForPointer:pointer];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kTableViewCellIdent];
    [self prepareDataSource];
}

- (void)prepareDataSource
{
    NSMutableArray *dataSource = [@[] mutableCopy];
    
    if ([_inspectingObject isKindOfClass:[UIResponder class]]) {
        [dataSource addObject:@"Responder Chain"];
    }
    if ([_inspectingObject isKindOfClass:[UIView class]] ||
        [_inspectingObject isKindOfClass:[UIViewController class]]) {
        [dataSource addObject:@"Show"];
    }
    [dataSource addObject:@"Methods"];
    [dataSource addObject:@"properties & iVars"];
    [dataSource addObject:@"Class hierarchy"];
    
    _dataSource = dataSource;
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_dataSource count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellIdent
                                                            forIndexPath:indexPath];
    
    NSString *item = _dataSource[indexPath.row];
    cell.textLabel.text = item;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *targetController = nil;
    NSString *item = _dataSource[indexPath.row];
    if ([item isEqualToString:@"Responder Chain"]) {
        targetController = [[RMResponderChainViewController alloc] initWithObject:_inspectingObject];
    } else if ([item isEqualToString:@"Show"]) {
        targetController = [[RMShowViewController alloc] initWithObject:_inspectingObject];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController pushViewController:targetController animated:YES];
}

@end
