//
//  RMHeapStackTableViewController.m
//  HeapInspectorExample
//
//  Created by Christian Menschel on 23.08.14.
//  Copyright (c) 2014 tapwork. All rights reserved.
//

#import "HINSPHeapStackTableViewController.h"
#import "HINSPHeapStackDetailTableViewController.h"
#import "HINSPTableViewCell.h"
#import "NSObject+HeapInspector.h"

@interface HINSPHeapStackTableViewController ()

@end

@implementation HINSPHeapStackTableViewController
{
     BOOL _wasRecording;
}

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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([NSObject isSnapshotRecording]) {
        _wasRecording = YES;
        [NSObject endSnapshot];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (_wasRecording) {
        [NSObject resumeSnapshot];
    }
}

#pragma mark - Actions

- (void)closeButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableView DataSource & Delegate

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
    HINSPHeapStackDetailTableViewController *detailVC = nil;
    detailVC = [[HINSPHeapStackDetailTableViewController alloc] initWithPointerString:pointerValue];
    [self.navigationController pushViewController:detailVC animated:YES];
}


#pragma mark - Helper

- (NSString *)pointerStringFromCellText:(NSString *)cellText
{
    NSArray *components = [cellText componentsSeparatedByString:@": "];
    
    return [components lastObject];
}

@end
