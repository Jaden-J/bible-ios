//
//  BookViewController.m
//  bible
//
//  Created by Thom on 14-4-18.
//  Copyright (c) 2014 Liu DongMiao. All rights reserved.
//

#import "BookViewController.h"
#import "BibleProvider.h"

@interface BookViewController ()

@end

@implementation BookViewController {
    BibleProvider *provider;
    NSArray *books;
    NSIndexPath *index;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Choose Book", nil);
    provider = [BibleProvider defaultProvider];
    NSArray *osises = provider.books;
    NSUInteger matt = [osises indexOfObject:@"Matt"];
    NSUInteger count = [osises count];
    if (matt < count && matt * 2 > count) {
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:78];
        for (NSUInteger left = 0; left < matt; ++left) {
            NSUInteger right = matt + left;
            [items addObject:[osises objectAtIndex:left]];
            if (right < count) {
                [items addObject:[osises objectAtIndex:right]];
            } else {
                [items addObject:@""];
            }
        }
        books = items;
    } else {
        books = osises;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [books count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    UIButton *button = (UIButton *)[cell viewWithTag:100];
    NSString *book= books[indexPath.row];
    [button setTitle:book forState:UIControlStateApplication];
    if ([book length] == 0) {
        [button setHidden:YES];
        [button setEnabled:NO];
        return cell;
    } else {
        [button setHidden:NO];
        [button setEnabled:YES];
    }

    NSString *bookName = [provider getBookName:book];
    [button setTitle:bookName forState:UIControlStateNormal];
    if ([provider.osis hasPrefix:[book stringByAppendingString:@"."]]) {
        [button setHighlighted:YES];
        [button setSelected:YES];
        index = indexPath;
    } else {
        [button setHighlighted:NO];
        [button setSelected:NO];
    }
    [button setTitle:book forState:UIControlStateApplication];
    return cell;
}

- (IBAction)touchDown:(UIButton *)sender
{
    NSString *book = [sender titleForState:UIControlStateApplication];
    [provider changeBook:book];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
