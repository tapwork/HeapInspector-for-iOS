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

#pragma mark - View Life Cycle

static const CGFloat kHeaderViewHeight = 70;

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIView *headerView = [[UIView alloc] init];
    headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, kHeaderViewHeight);
    headerView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    NSPredicate *predicate0 = [NSPredicate predicateWithFormat:@"SELF == 'alloc'"];
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"SELF == 'retain'"];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"SELF == 'storeStrong'"];
    NSPredicate *predicate3 = [NSPredicate predicateWithFormat:@"SELF == 'release'"];
    NSArray *allocs = [[self.dataSource valueForKey:@"type"] filteredArrayUsingPredicate:predicate0];
    NSArray *retains = [[self.dataSource valueForKey:@"type"] filteredArrayUsingPredicate:predicate1];
    NSArray *strongs = [[self.dataSource valueForKey:@"type"] filteredArrayUsingPredicate:predicate2];
    NSArray *releases = [[self.dataSource valueForKey:@"type"] filteredArrayUsingPredicate:predicate3];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,8,headerView.bounds.size.width,20.0)];
    label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    label.font = [UIFont systemFontOfSize:10];
    label.numberOfLines = 1;
    label.textAlignment = NSTextAlignmentCenter;
    NSInteger count = [allocs count] + [retains count] + [strongs count] - [releases count];
    label.text = [NSString stringWithFormat:@"Retain Count: %ld   Alloc: %lu  Retain: %lu  Strong: %lu  Release: %lu",
                  (long)count,
                  (unsigned long)[allocs count],
                  (unsigned long)[retains count],
                  (unsigned long)[strongs count],
                  (unsigned long)[releases count]];
    [headerView addSubview:label];
    
    UIView *superTableHeaderView = self.tableView.tableHeaderView;
    self.tableView.tableHeaderView = nil;
    CGRect tableHeaderViewFrame = superTableHeaderView.frame;
    tableHeaderViewFrame.origin.y = CGRectGetMaxY(label.frame);
    superTableHeaderView.frame = tableHeaderViewFrame;
    [headerView addSubview:superTableHeaderView];
    self.tableView.tableHeaderView = headerView;
}


#pragma mark - TableView

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HINSPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellIdent
                                                            forIndexPath:indexPath];
    
    NSDictionary *item = self.dataSource[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld %@",(long)indexPath.row, item[@"type"]];
    cell.detailTextLabel.text = item[@"last_trace"];
    
    NSArray *backtrace = item[@"all_traces"];
    if ([backtrace count] > 0) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.userInteractionEnabled = YES;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.userInteractionEnabled = NO;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = self.dataSource[indexPath.row];
    NSArray *backtrace = item[@"all_traces"];
    if ([backtrace count] > 0) {
        HINSPTableViewController *detailVC = [[HINSPTableViewController alloc] initWithDataSource:backtrace];
        detailVC.title = [NSString stringWithFormat:@"%@'s backtrace",item[@"type"]];
        [self.navigationController pushViewController:detailVC animated:YES];
    }
    
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
