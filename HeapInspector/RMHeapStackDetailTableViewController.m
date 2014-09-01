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

static const CGFloat kHeaderViewHeight = 100.0f;

@interface RMHeapStackDetailTableViewController ()

@end

@implementation RMHeapStackDetailTableViewController
{
    UITextView *_headerTextView;
}

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
    CGRect headerViewFrame = CGRectMake(0.0, 0.0,
                                        self.tableView.bounds.size.width,
                                        kHeaderViewHeight);
    UIView *headerView = [[UIView alloc] initWithFrame:headerViewFrame];
    headerView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    
    CGRect titleLabelFrame = CGRectMake(5.0, 5.0,
                                        headerView.bounds.size.width - 10.0,
                                        15.0);
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleLabelFrame];

    CGRect textViewFrame = CGRectMake(0.0, CGRectGetMaxY(titleLabel.frame),
                                      headerView.bounds.size.width,
                                      headerView.bounds.size.height - CGRectGetMaxY(titleLabel.frame));
    UITextView *textView = [[UITextView alloc] initWithFrame:textViewFrame];

    titleLabel.text = [NSString stringWithFormat:@"%s: %p",
                       object_getClassName(self.inspectingObject),
                       self.inspectingObject];
    titleLabel.font = [UIFont boldSystemFontOfSize:12];
    titleLabel.backgroundColor = [UIColor clearColor];
    [headerView addSubview:titleLabel];
    
    // Add a switch if the object is of bool type
    if ([self.inspectingObject respondsToSelector:@selector(boolValue)] &&
        [NSStringFromClass([self.inspectingObject class]) isEqualToString:@"__NSCFBoolean"]) {
        UISwitch *boolSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        CGRect switchFrame = boolSwitch.frame;
        switchFrame.origin.x = headerViewFrame.size.width - switchFrame.size.width - 10.0;
        switchFrame.origin.y = 5.0;
        boolSwitch.frame = switchFrame;
        [boolSwitch addTarget:self action:@selector(boolSwitchToggle:) forControlEvents:UIControlEventValueChanged];
        boolSwitch.on = [self.inspectingObject boolValue];
        [headerView addSubview:boolSwitch];
    }
    
    textView.editable = NO;
    textView.backgroundColor = [UIColor clearColor];
    _headerTextView = textView;
    [headerView addSubview:textView];
    
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.tableView.tableHeaderView = headerView;
    [self updateHeaderView];
}

- (void)updateHeaderView
{
    if ([self.inspectingObject respondsToSelector:@selector(description)]) {
        _headerTextView.text = [self.inspectingObject description];
    }
}

#pragma mark - Actions

- (void)boolSwitchToggle:(UISwitch *)boolSwitch
{
    self.inspectingObject = @(boolSwitch.on);
    [self updateHeaderView];
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
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
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
