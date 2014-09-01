//
//  RMTableViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 01.09.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "RMTableViewController.h"
#import "RMHeapStackInspector.h"

@interface RMTableViewController () <UISearchBarDelegate>

@end

@implementation RMTableViewController

- (id)init
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
        self.inspectingObject = [RMHeapStackInspector objectForPointer:pointer];
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



#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupSearchBar];
    [self.tableView registerClass:[RMTableViewCell class] forCellReuseIdentifier:kTableViewCellIdent];
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
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellIdent forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}

#pragma mark - SeachBarDelegate

@end
