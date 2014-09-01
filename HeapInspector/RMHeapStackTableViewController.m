//
//  RMHeapStackTableViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 23.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "RMHeapStackTableViewController.h"
#import "RMHeapStackDetailTableViewController.h"
#import "RMTableViewCell.h"

@interface RMHeapStackTableViewController ()

@end

@implementation RMHeapStackTableViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithTitle:@"Close"
                                             style:UIBarButtonItemStylePlain
                                             target:self
                                             action:@selector(closeButton:)];
}

#pragma mark - Actions

- (void)closeButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableView DataSource & Delegate

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
    
    NSString *string = self.dataSource[indexPath.row];
    cell.textLabel.text = string;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellValue = self.dataSource[indexPath.row];
    NSString *pointerValue = [self pointerStringFromCellText:cellValue];
    RMHeapStackDetailTableViewController *detailVC = nil;
    detailVC = [[RMHeapStackDetailTableViewController alloc] initWithPointerString:pointerValue];
    [self.navigationController pushViewController:detailVC animated:YES];
}

#pragma mark - Helper

- (NSString *)pointerStringFromCellText:(NSString *)cellText
{
    NSArray *components = [cellText componentsSeparatedByString:@": "];
    
    return [components lastObject];
}

@end
