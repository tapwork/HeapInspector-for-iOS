//
//  RMRefHistoryTableViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 11.09.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "HINSPRefHistoryTableViewController.h"
#import "NSObject+HeapInspector.h"
#import "HINSPTableViewCell.h"
#import "HINSPTableViewController.h"

@interface HINSPRefHistoryTableViewController ()

@end

@implementation HINSPRefHistoryTableViewController


#pragma mark - Init

- (instancetype)initWithObject:(id)object
{
    self = [super initWithObject:object];
    if (self) {
        
        self.title = [NSString stringWithFormat:@"Reference History: %s: %p",
                      object_getClassName(self.inspectingObject),
                      self.inspectingObject];
        
        NSArray *dataSource = [NSObject referenceHistoryForObject:object];
        self.dataSource = dataSource;
    }
    return self;
}

#pragma mark - TableView

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HINSPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellIdent
                                                            forIndexPath:indexPath];
    
    NSDictionary *item = self.dataSource[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%d %@",indexPath.row, item[@"type"]];
    cell.detailTextLabel.text = item[@"last_trace"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = self.dataSource[indexPath.row];
    HINSPTableViewController *detailVC = [[HINSPTableViewController alloc] initWithDataSource:item[@"all_traces"]];
    detailVC.title = [NSString stringWithFormat:@"%@'s backtrace",item[@"type"]];
    [self.navigationController pushViewController:detailVC animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Search

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSMutableArray *dataSource = [self.dataSourceUnfiltered mutableCopy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type contains[cd] %@ OR last_trace contains[cd] %@",
                                  searchText,searchText];
        [dataSource filterUsingPredicate:predicate];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataSource = dataSource;
            [self.tableView reloadData];
        });
    });
}

@end
