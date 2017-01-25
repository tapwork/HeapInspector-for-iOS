//
//  RMClassDumpTableViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 01.09.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "HINSPClassDumpTableViewController.h"
#import "HINSPHeapStackDetailTableViewController.h"
#import <objc/runtime.h>
#import "HINSPHeapStackDetailTableViewController.h"

@interface HINSPClassDumpTableViewController ()

@end

@implementation HINSPClassDumpTableViewController
{
    RMClassDumpType _type;
}

#pragma mark - Init

- (instancetype)initWithObject:(id)object type:(RMClassDumpType)type
{
    self = [super initWithObject:object];
    if (self) {
        _type = type;
        
        self.title = [NSString stringWithFormat:@"%s: %p",
                      object_getClassName(self.inspectingObject),
                      self.inspectingObject];
    }
    return self;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_type == RMClassDumpMethods) {
        self.tableView.allowsSelection = NO;
    }
    [self prepareDataSource];
}

#pragma mark - DataSources

- (void)prepareDataSource
{
    NSArray *dataSource = nil;
    switch (_type) {
        case RMClassDumpMethods:
            dataSource = [self retrieveMethods];
            break;
        case RMClassDumpIvar:
            dataSource = [self retrieveIvars];
            break;
        case RMClassDumpProperties:
            dataSource = [self retrieveProperties];
            break;
            
        default:
            break;
    }
    self.dataSource = dataSource;
    [self.tableView reloadData];
}

- (NSArray *)retrieveMethods
{
   // self.title = @"Methods";
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
    
    free(superList);
    free(selflist);
    
    return [dataSource copy];
}

- (NSArray *)retrieveIvars
{
  //  self.title = @"iVars";
    NSMutableArray *dataSource = [@[] mutableCopy];
    NSMutableOrderedSet *superIvars = [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet *selfIvars = [[NSMutableOrderedSet alloc] init];
    unsigned int mc = 0;
    Ivar *selflist = class_copyIvarList([self.inspectingObject class], &mc);
    // Retrieve self's methods
    for(int i = 0; i < mc; i++) {
        NSString *signature = [NSString stringWithUTF8String:ivar_getName(selflist[i])];
        if (signature) {
            [selfIvars addObject:signature];
        }
    }
    
    // Retrieve super's methods
    Ivar *superlist = class_copyIvarList([self.inspectingObject superclass], &mc);
    for(int i = 0; i < mc; i++) {
        NSString *signature = [NSString stringWithUTF8String:ivar_getName(superlist[i])];
        if (signature) {
            [superIvars addObject:signature];
        }
    }
    
    // remove the super's iVars from self's collection
    [selfIvars minusOrderedSet:superIvars];
    
    NSArray *section1 = [[selfIvars array] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSArray *section2 = [[superIvars array] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [dataSource addObject:section1];
    [dataSource addObject:section2];
    
    free(superlist);
    free(selflist);
    
    return [dataSource copy];
}

- (NSArray *)retrieveProperties
{
  //  self.title = @"Properties";
    NSMutableArray *dataSource = [@[] mutableCopy];
    NSMutableOrderedSet *superProperties = [[NSMutableOrderedSet alloc] init];
    NSMutableOrderedSet *selProperties = [[NSMutableOrderedSet alloc] init];
    unsigned int mc = 0;
    objc_property_t *selflist = class_copyPropertyList([self.inspectingObject class], &mc);
    // Retrieve self's methods
    for(int i = 0; i < mc; i++) {
        NSString *signature = [NSString stringWithUTF8String:property_getName(selflist[i])];
        if (signature) {
            [selProperties addObject:signature];
            //  printf("%s property_getAttributes %s\n",property_getName(selflist[i]), getPropertyType(selflist[i]));
        }
    }
    
    // Retrieve super's methods
    objc_property_t *superlist = class_copyPropertyList([self.inspectingObject superclass], &mc);
    for(int i = 0; i < mc; i++) {
        NSString *signature = [NSString stringWithUTF8String:property_getName(superlist[i])];
        if (signature) {
            [superProperties addObject:signature];
        }
    }
    
    // remove the super's properties from self's collection
    [selProperties minusOrderedSet:superProperties];
    
    NSArray *section1 = [[selProperties array] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSArray *section2 = [[superProperties array] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [dataSource addObject:section1];
    [dataSource addObject:section2];
    
    free(superlist);
    free(selflist);
    
    return [dataSource copy];
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
                title = @"Self's Methods";
            } else if (section == 1) {
                title = @"Super's Methods";
            }
            break;
        case RMClassDumpIvar:
            if (section == 0) {
                title = @"Self's iVars";
            } else if (section == 1) {
                title = @"Super's iVars";
            }
            break;
        case RMClassDumpProperties:
            if (section == 0) {
                title = @"Self's Properties";
            } else if (section == 1) {
                title = @"Super's Properties";
            }
            break;
        default:
            break;
    }
    
    
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellIdent
                                                            forIndexPath:indexPath];
    
    NSString *item = self.dataSource[indexPath.section][indexPath.row];
    cell.textLabel.text = item;

    if ([self canPerformKVO:item forObject:self.inspectingObject]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *item = self.dataSource[indexPath.section][indexPath.row];
    id newInspectingObject = nil;
    if ([self canPerformKVO:item forObject:self.inspectingObject]) {
        newInspectingObject = [self performKVO:item
                                     forObject:self.inspectingObject];
    }
    if (newInspectingObject) {
        HINSPHeapStackDetailTableViewController *detailVC = nil;
        detailVC = [[HINSPHeapStackDetailTableViewController alloc] initWithObject:newInspectingObject];
        [self.navigationController pushViewController:detailVC animated:YES];
    } else {
        NSString *typeString = (_type == RMClassDumpProperties) ? @"Property" : @"iVar";
        NSString *message = [NSString stringWithFormat:@"%@ is nil",typeString];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"nil"
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Helper
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (BOOL)canPerformKVO:(NSString *)selectorStr forObject:(id)object
{
    BOOL canPerform = NO;
    @try {
        if (_type == RMClassDumpProperties) {
            id result = [object valueForKeyPath:selectorStr];
            canPerform = (result != nil && [result conformsToProtocol:@protocol(NSObject)]);
        }
    }
    @catch (NSException *exception) {
        canPerform = NO;
    }
    @finally {
        
    }
    
    
    return canPerform;
}

- (instancetype)performKVO:(NSString *)selectorStr forObject:(id)object
{
    if ((_type == RMClassDumpProperties ||
         _type == RMClassDumpIvar) &&
        [object conformsToProtocol:@protocol(NSObject)]) {
        return [object valueForKeyPath:selectorStr];
    }
    
    return nil;
}
#pragma clang diagnostic pop

#pragma mark - Search

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSMutableArray *dataSource = [self.dataSourceUnfiltered mutableCopy];
    NSMutableArray *serps_1 = [dataSource[0] mutableCopy];
    NSMutableArray *serps_2 = [dataSource[1] mutableCopy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@",
                                  searchText];
        [serps_1 filterUsingPredicate:predicate];
        [serps_2 filterUsingPredicate:predicate];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataSource = @[serps_1,serps_2];
            [self.tableView reloadData];
        });
    });
}

@end
