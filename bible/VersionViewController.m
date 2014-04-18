//
//  VersionViewController.m
//  bible
//
//  Created by Thom on 14-4-17.
//  Copyright (c) 2014 Liu DongMiao. All rights reserved.
//

#import "VersionViewController.h"
#import "BibleProvider.h"

@interface VersionViewController ()

@end

@implementation VersionViewController {
    BibleProvider *provider;
    NSArray *versions;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = NSLocalizedString(@"Choose Version", nil);

    provider = [BibleProvider defaultProvider];
}

- (void)viewWillAppear:(BOOL)animated
{
    versions = provider.versions;
    NSUInteger index = [versions indexOfObject:provider.version];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:animated scrollPosition:UITableViewScrollPositionMiddle];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [provider saveOSISVersion];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [versions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = [provider getVersionShortName:versions[indexPath.row]];
    cell.detailTextLabel.text = [provider getVersionFullName:versions[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [provider changeVersion:versions[indexPath.row]];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
