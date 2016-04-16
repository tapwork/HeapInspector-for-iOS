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
        
        self.title = [NSString stringWithFormat:@"%s: %p",
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

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,8,headerView.bounds.size.width,20.0)];
    label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    label.font = [UIFont systemFontOfSize:10];
    label.numberOfLines = 1;
    label.textAlignment = NSTextAlignmentCenter;
    NSInteger retainCount = CFGetRetainCount((__bridge CFTypeRef)self.inspectingObject);
    label.text = [NSString stringWithFormat:@"Retain Count: %ld ", (long)retainCount];
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
    NSString *symbol = [NSObject symbolForPointerValue:item[@"last_frame"]];
    cell.detailTextLabel.text = symbol;
    
    NSArray *backtrace = item[@"all_frames"];
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
    NSArray *backtraceSymbols = [self symbolsFromPointers:item[@"all_frames"]];
    if ([backtraceSymbols count] > 0) {
        HINSPTableViewController *detailVC = [[HINSPTableViewController alloc] initWithDataSource:backtraceSymbols];
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
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type contains[cd] %@ OR last_frame contains[cd] %@",
                                  searchText,searchText];
        [dataSource filterUsingPredicate:predicate];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataSource = dataSource;
            [self.tableView reloadData];
        });
    });
}

#pragma mark - Helper

- (NSArray *)symbolsFromPointers:(NSArray *)pointers
{
    NSMutableArray *symbols = [NSMutableArray array];
    for (NSValue *pointerValue in pointers) {
        NSString *symbol = [NSObject symbolForPointerValue:pointerValue];
        [symbols addObject:symbol];
    }
    return symbols;
}

@end
