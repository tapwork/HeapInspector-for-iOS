//
//  RMHeapStackDetailTableViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 29.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "HINSPHeapStackDetailTableViewController.h"
#import "HINSPResponderChainViewController.h"
#import "HINSPShowViewController.h"
#import "HINSPTableViewCell.h"
#import "HINSPClassDumpTableViewController.h"
#import "HINSPRefHistoryTableViewController.h"
#import "NSObject+HeapInspector.h"

static NSString *const kCellTitleShow = @"Show";
static NSString *const kCellTitleResponderChain = @"Responder Chain";
static NSString *const kCellTitleMethods = @"Methods";
static NSString *const kCellTitleReferenceHistory = @"Reference History";
static NSString *const kCellTitleIvars = @"iVars";
static NSString *const kCellTitleProperties = @"Properties";
static NSString *const kCellTitleRecursiveDesc = @"Recursive Description";

static const CGFloat kHeaderViewHeight = 100.0f;

@interface HINSPHeapStackDetailTableViewController ()

@end

@implementation HINSPHeapStackDetailTableViewController
{
    UITextView *_headerTextView;
    UIFont *_boldFont;
    UIFont *_regFont;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Object Inspector";
    _boldFont = [UIFont boldSystemFontOfSize:12];
    _regFont = [UIFont systemFontOfSize:12];
    
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
    if ([self.inspectingObject conformsToProtocol:@protocol(NSObject)] &&
         [self.inspectingObject respondsToSelector:@selector(description)]) {
        NSInteger retainCount = CFGetRetainCount((__bridge CFTypeRef)self.inspectingObject);
        NSString *retainCountString = [NSString stringWithFormat:@"Retain count: %ld\n", (long)retainCount];
        NSString *infoHeaderText = [retainCountString stringByAppendingString:[self.inspectingObject description]];
        _headerTextView.text = infoHeaderText;
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
    
    NSArray *refHistory = [NSObject referenceHistoryForObject:self.inspectingObject];
    if ([refHistory count]) {
        [dataSource addObject:kCellTitleReferenceHistory];
    }
    
    if ([self.inspectingObject isKindOfClass:[UIResponder class]]) {
        [dataSource addObject:kCellTitleResponderChain];
    }
    if ([self.inspectingObject isKindOfClass:[UIView class]] ||
        [self.inspectingObject isKindOfClass:[UIImage class]] ||
        [self.inspectingObject isKindOfClass:[UIViewController class]]) {
        [dataSource addObject:kCellTitleShow];
        if ([self.inspectingObject isKindOfClass:[UIView class]]) {
             [dataSource addObject:kCellTitleRecursiveDesc];
        }
    }
    
    [dataSource addObject:kCellTitleMethods];
    [dataSource addObject:kCellTitleProperties];
    [dataSource addObject:kCellTitleIvars];
    
    self.dataSource = [dataSource copy];
    [self.tableView reloadData];
}

#pragma mark - UITableview dataSource & Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellIdent
                                                            forIndexPath:indexPath];
    
    NSString *item = self.dataSource[indexPath.row];
    cell.textLabel.text = item;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if ([item isEqualToString:kCellTitleReferenceHistory]) {
        cell.textLabel.font = _boldFont;
    } else {
        cell.textLabel.font = _regFont;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *targetController = nil;
    NSString *item = self.dataSource[indexPath.row];
    if ([item isEqualToString:kCellTitleResponderChain]) {
        targetController = [[HINSPResponderChainViewController alloc] initWithObject:self.inspectingObject];
    } else if ([item isEqualToString:kCellTitleShow]) {
        targetController = [[HINSPShowViewController alloc] initWithObject:self.inspectingObject];
    } else if ([item isEqualToString:kCellTitleMethods]) {
        targetController = [[HINSPClassDumpTableViewController alloc] initWithObject:self.inspectingObject type:RMClassDumpMethods];
    } else if ([item isEqualToString:kCellTitleIvars]) {
        targetController = [[HINSPClassDumpTableViewController alloc] initWithObject:self.inspectingObject type:RMClassDumpIvar];
    } else if ([item isEqualToString:kCellTitleProperties]) {
        targetController = [[HINSPClassDumpTableViewController alloc] initWithObject:self.inspectingObject type:RMClassDumpProperties];
    } else if ([item isEqualToString:kCellTitleRecursiveDesc]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        NSString *recursiveDesc = [self.inspectingObject performSelector:@selector(recursiveDescription)];
        targetController = [[HINSPShowViewController alloc] initWithObject:recursiveDesc];
        ((HINSPShowViewController *)targetController).shouldShowEditButton = NO;
    } else if ([item isEqualToString:kCellTitleReferenceHistory]) {
        targetController = [[HINSPRefHistoryTableViewController alloc] initWithObject:self.inspectingObject];
    }
#pragma clang diagnostic pop
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController pushViewController:targetController animated:YES];
}


@end
