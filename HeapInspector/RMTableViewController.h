//
//  RMTableViewController.h
//  HeapInspectorExample
//
//  Created by Christian Menschel on 01.09.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMTableViewCell.h"

@interface RMTableViewController : UITableViewController

@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, readonly) NSArray *dataSourceUnfiltered;
@property (nonatomic, strong) id inspectingObject;

- (instancetype)initWithObject:(id)object;
- (instancetype)initWithPointerString:(NSString *)pointer;


- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar;
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar;
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar;
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText;


@end
