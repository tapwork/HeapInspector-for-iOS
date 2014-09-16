//
//  RMTableViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 01.09.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "HINSPTableViewController.h"
#import "HINSPHeapStackInspector.h"

@interface HINSPTableViewController () <UISearchBarDelegate>

@end

@implementation HINSPTableViewController
{
    NSArray *_originalDataSource;
}

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (instancetype)initWithPointerString:(NSString *)pointer
{
    self = [self init];
    if (self) {
        // Retrieve a real object from the pointer
        self.inspectingObject = [HINSPHeapStackInspector objectForPointer:pointer];
    }
    return self;
}

- (instancetype)initWithObject:(id)object
{
    self = [self init];
    if (self) {
        // Retrieve a real object from the pointer
        self.inspectingObject = object;
    }
    return self;
}

- (instancetype)initWithDataSource:(NSArray *)dataSource
{
    self = [self init];
    if (self) {
        // Retrieve a real object from the pointer
        self.dataSource = dataSource;
    }
    return self;
}

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupSearchBar];
    [self.tableView registerClass:[HINSPTableViewCell class] forCellReuseIdentifier:kTableViewCellIdent];
}

- (void)setupSearchBar
{
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    CGRect frame = searchBar.frame;
    frame.size.width = self.view.bounds.size.width;
    frame.size.height = 44.0f;
    searchBar.frame = frame;
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    searchBar.delegate = self;
    self.tableView.tableHeaderView = searchBar;
}

#pragma mark - Table view data source

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
    HINSPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellIdent forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *value = self.dataSource[indexPath.row];
    cell.textLabel.text = value;
    
    return cell;
}

#pragma mark - SeachBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
     _dataSourceUnfiltered = self.dataSource;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
    
    self.dataSource = _dataSourceUnfiltered;
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    [searchBar resignFirstResponder];
    searchBar.text = nil;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSMutableArray *serps = [self.dataSourceUnfiltered mutableCopy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@",
                                  searchText];
        [serps filterUsingPredicate:predicate];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataSource = serps;
            [self.tableView reloadData];
        });
    });
}

@end
