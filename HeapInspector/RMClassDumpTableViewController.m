//
//  RMClassDumpTableViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 01.09.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "RMClassDumpTableViewController.h"
#import "RMHeapStackDetailTableViewController.h"
#import <objc/runtime.h>

@interface RMClassDumpTableViewController ()

@end

@implementation RMClassDumpTableViewController
{
    RMClassDumpType _type;
}

#pragma mark - Init

- (instancetype)initWithObject:(id)object type:(RMClassDumpType)type
{
    self = [super initWithObject:object];
    if (self) {
        _type = type;
        self.title = @"";
    }
    return self;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.allowsSelection = NO;
    [self prepareDataSource];
}

#pragma mark - DataSources

- (void)prepareDataSource
{
    switch (_type) {
        case RMClassDumpMethods:
            [self retrieveMethods];
            break;
            
        default:
            break;
    }
}

- (void)retrieveMethods
{
    NSMutableArray *dataSource = [@[] mutableCopy];
    NSMutableOrderedSet *superMethods = [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet *selfMethods = [[NSMutableOrderedSet alloc] init];
    unsigned int mc = 0;
    Method *selflist = class_copyMethodList([self.inspectingObject class], &mc);
    // Retrieve self's methods
    for(int i = 0; i < mc; i++) {
        NSString *signature = [NSString stringWithUTF8String:sel_getName(method_getName(selflist[i]))];
        if (signature) {
            [selfMethods addObject:signature];
        }
    }
    
    // Retrieve super's methods
    Method *superList = class_copyMethodList([self.inspectingObject superclass], &mc);
    for(int i = 0; i < mc; i++) {
        NSString *signature = [NSString stringWithUTF8String:sel_getName(method_getName(superList[i]))];
        if (signature) {
            [superMethods addObject:signature];
        }
    }
    
    // remove the super's methods from self's collection
    [selfMethods minusOrderedSet:superMethods];
    
    NSArray *section1 = [[selfMethods array] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSArray *section2 = [[superMethods array] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [dataSource addObject:section1];
    [dataSource addObject:section2];
    
    // sorting now
    self.dataSource = dataSource;
    [self.tableView reloadData];
    free(superList);
    free(selflist);
}

- (void)retrieveIvars
{
    
}

- (void)retrieveProperties
{
    
}

#pragma mark - UITableView dataSource & delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.dataSource count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionDataSource = self.dataSource[section];
    return [sectionDataSource count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    switch (_type) {
        case RMClassDumpMethods:
            if (section == 0) {
                title = @"Self's methods";
            } else if (section == 1) {
                title = @"Super's methods";
            }
        default:
            break;
    }
    
    
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellIdent
                                                            forIndexPath:indexPath];
    
    NSString* methodName = self.dataSource[indexPath.section][indexPath.row];
    cell.textLabel.text = methodName;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}


@end
