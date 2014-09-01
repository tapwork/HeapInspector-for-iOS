//
//  RMResponderChainViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 29.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "RMResponderChainViewController.h"
#import "RMHeapStackDetailTableViewController.h"
#import "RMTableViewCell.h"

@interface RMResponderChainViewController ()

@end

@implementation RMResponderChainViewController

#pragma mark - Init

- (instancetype)initWithObject:(id)object
{
    self = [super initWithObject:object];
    if (self) {
        
        self.title = @"Responder Chain";
        
        NSMutableArray *responders = [NSMutableArray array];
        [responders addObject:object];
        id tryResponder = [object nextResponder];
        while (tryResponder) {
            [responders addObject:tryResponder];
            tryResponder = [tryResponder nextResponder];
        }
        
        self.dataSource = responders;
    }
    return self;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[RMTableViewCell class] forCellReuseIdentifier:kTableViewCellIdent];
}


#pragma mark - UITableView dataSource & Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellIdent
                                                            forIndexPath:indexPath];
    
    id object = self.dataSource[indexPath.row];
    NSString *content = [NSString stringWithFormat:@"%s: %p",
                         object_getClassName(object),
                         object];
    cell.textLabel.text = content;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = self.dataSource[indexPath.row];
    RMHeapStackDetailTableViewController *detailVC = [[RMHeapStackDetailTableViewController alloc]
                                                      initWithObject:object];
    [self.navigationController pushViewController:detailVC animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
