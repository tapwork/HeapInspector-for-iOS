//
//  RMResponderChainViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 29.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "HINSPResponderChainViewController.h"
#import "HINSPHeapStackDetailTableViewController.h"
#import "HINSPTableViewCell.h"

@interface HINSPResponderChainViewController ()

@end

@implementation HINSPResponderChainViewController

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
    [self.tableView registerClass:[HINSPTableViewCell class] forCellReuseIdentifier:kTableViewCellIdent];
    self.tableView.tableHeaderView = nil;
}


#pragma mark - UITableView dataSource & Delegate

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
    HINSPHeapStackDetailTableViewController *detailVC = [[HINSPHeapStackDetailTableViewController alloc]
                                                      initWithObject:object];
    [self.navigationController pushViewController:detailVC animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
