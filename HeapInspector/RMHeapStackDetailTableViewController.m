//
//  RMHeapStackDetailTableViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 29.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "RMHeapStackDetailTableViewController.h"
#import "RMResponderChainViewController.h"
#import "RMShowViewController.h"
#import "RMTableViewCell.h"
#import "RMClassDumpTableViewController.h"

static NSString *const kCellTitleShow = @"Show";
static NSString *const kCellTitleResponderChain = @"Responder Chain";
static NSString *const kCellTitleMethods = @"Methods";
static NSString *const kCellTitleIvars = @"iVars";
static NSString *const kCellTitleProperties = @"Properties";
static NSString *const kCellTitleRecursiveDesc = @"Recursive Description";

static const CGFloat kHeaderViewHeight = 80.0f;

@interface RMHeapStackDetailTableViewController ()

@end

@implementation RMHeapStackDetailTableViewController


#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Object Inspector";
    
    [self setupHeaderView];
    [self prepareDataSource];
}

- (void)setupHeaderView
{
    UITextView *headerView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, kHeaderViewHeight)];
    headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    headerView.editable = NO;
    headerView.text = [self.inspectingObject description];
    headerView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.tableView.tableHeaderView = headerView;
}

#pragma mark - DataSource

- (void)prepareDataSource
{
    NSMutableArray *dataSource = [@[] mutableCopy];
    
    if ([self.inspectingObject isKindOfClass:[UIResponder class]]) {
        [dataSource addObject:kCellTitleResponderChain];
    }
    if ([self.inspectingObject isKindOfClass:[UIView class]] ||
        [self.inspectingObject isKindOfClass:[UIViewController class]]) {
        [dataSource addObject:kCellTitleShow];
        if ([self.inspectingObject isKindOfClass:[UIView class]]) {
             [dataSource addObject:kCellTitleRecursiveDesc];
        }
    }
    [dataSource addObject:kCellTitleMethods];
    [dataSource addObject:kCellTitleProperties];
    [dataSource addObject:kCellTitleIvars];
   
    
    self.dataSource = dataSource;
    [self.tableView reloadData];
}

#pragma mark - UITableview dataSource & Delegate

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
    
    NSString *item = self.dataSource[indexPath.row];
    cell.textLabel.text = item;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *targetController = nil;
    NSString *item = self.dataSource[indexPath.row];
    if ([item isEqualToString:kCellTitleResponderChain]) {
        targetController = [[RMResponderChainViewController alloc] initWithObject:self.inspectingObject];
    } else if ([item isEqualToString:kCellTitleShow]) {
        targetController = [[RMShowViewController alloc] initWithObject:self.inspectingObject];
    } else if ([item isEqualToString:kCellTitleMethods]) {
        targetController = [[RMClassDumpTableViewController alloc] initWithObject:self.inspectingObject type:RMClassDumpMethods];
    } else if ([item isEqualToString:kCellTitleIvars]) {
        targetController = [[RMClassDumpTableViewController alloc] initWithObject:self.inspectingObject type:RMClassDumpIvar];
    } else if ([item isEqualToString:kCellTitleProperties]) {
        targetController = [[RMClassDumpTableViewController alloc] initWithObject:self.inspectingObject type:RMClassDumpProperties];
    } else if ([item isEqualToString:kCellTitleRecursiveDesc]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        NSString *recursiveDesc = [self.inspectingObject performSelector:@selector(recursiveDescription)];
        targetController = [[RMShowViewController alloc] initWithObject:recursiveDesc];
        ((RMShowViewController *)targetController).showEditButton = NO;
    }
#pragma clang diagnostic pop
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController pushViewController:targetController animated:YES];
}


@end
