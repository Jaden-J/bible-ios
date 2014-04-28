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
    NSIndexPath *currentIndexPath;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = NSLocalizedString(@"Choose Version", nil);

    provider = [BibleProvider defaultProvider];
    versions = provider.versions;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUInteger index = [versions indexOfObject:provider.version];
    currentIndexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.tableView selectRowAtIndexPath:currentIndexPath animated:animated scrollPosition:UITableViewScrollPositionMiddle];
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
    NSString *versionName = versions[indexPath.row];
    NSString *versionShortName =[provider getVersionShortName:versionName];
    if ([versionShortName isEqualToString:[versionName uppercaseString]]) {
        cell.textLabel.text = versionShortName;
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", versionShortName, [versionName uppercaseString]];
    }
    cell.detailTextLabel.text = [provider getVersionFullName:versionName];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath compare:currentIndexPath] != NSOrderedSame) {
        [self.tableView deselectRowAtIndexPath:currentIndexPath animated:NO];
        [provider setVersion:versions[indexPath.row]];
        [provider save];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
