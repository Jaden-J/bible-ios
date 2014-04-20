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
    NSString *currentBook;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Choose Book", nil);
    provider = [BibleProvider defaultProvider];
    NSUInteger matt = [provider.books indexOfObject:@"Matt"];
    NSUInteger count = [provider.books count];
    if (matt < count && matt * 2 > count) {
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:78];
        for (NSUInteger left = 0; left < matt; ++left) {
            NSUInteger right = matt + left;
            [items addObject:[provider.books objectAtIndex:left]];
            if (right < count) {
                [items addObject:[provider.books objectAtIndex:right]];
            } else {
                [items addObject:@""];
            }
        }
        books = [NSArray arrayWithArray:items];
        [items removeAllObjects];
        items = nil;
    } else {
        books = provider.books;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    currentBook = [[provider.chapter componentsSeparatedByString:@"."] firstObject];
    NSUInteger index = [books indexOfObject:currentBook];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animated];
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
    if ([currentBook isEqualToString:book]) {
        [button setHighlighted:YES];
    } else {
        [button setHighlighted:NO];
    }
    [button setTitle:book forState:UIControlStateApplication];
    return cell;
}

- (IBAction)touchDown:(UIButton *)sender
{
    NSString *book = [sender titleForState:UIControlStateApplication];
    [provider setBook:book];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
