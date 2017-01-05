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
    UIActivityIndicatorView *_loadingSpinner;
    BOOL _isSearching;
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_isSearching) {
        [self.tableView.tableHeaderView becomeFirstResponder];
    }
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
    
    _loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [_loadingSpinner hidesWhenStopped];
    _loadingSpinner.frame = CGRectMake(11, 11, 20, 20);
    [self.tableView.tableHeaderView addSubview:_loadingSpinner];
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
    cell.detailTextLabel.text = value;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - SeachBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if ([searchBar.text length] == 0 && !_isSearching) {
        [searchBar setShowsCancelButton:YES animated:YES];
        _dataSourceUnfiltered = self.dataSource;
        _isSearching = YES;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    if ([searchBar.text length] == 0) {
        [searchBar setShowsCancelButton:NO animated:YES];
        self.dataSource = _dataSourceUnfiltered;
        [self.tableView reloadData];
        _isSearching = NO;
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    searchBar.text = nil;
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.tableView.tableHeaderView bringSubviewToFront:_loadingSpinner];
    [_loadingSpinner startAnimating];
    NSMutableArray *serps = [self.dataSourceUnfiltered mutableCopy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@",
                                  searchText];
        [serps filterUsingPredicate:predicate];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.dataSource = [serps copy];
            [self.tableView reloadData];
            [_loadingSpinner stopAnimating];
        });
    });
}

@end
