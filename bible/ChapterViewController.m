//
//  ChapterViewController.m
//  bible
//
//  Created by Thom on 14-4-18.
//  Copyright (c) 2014 Liu DongMiao. All rights reserved.
//

#import "ChapterViewController.h"
#import "BibleProvider.h"

@interface ChapterViewController ()

@end

@implementation ChapterViewController {
    BibleProvider *provider;
    NSArray *chapters;
    NSString *currentChapter;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Choose Chapter", nil);
    provider = [BibleProvider defaultProvider];
    chapters = provider.chapters;
    currentChapter = provider.chapter;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUInteger index = [chapters indexOfObject:currentChapter];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animated];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [chapters count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    NSString *chapter = chapters[indexPath.row];
    NSString *chapterName = [provider getChapterName:chapter];
    UIButton *button = (UIButton *)[cell viewWithTag:100];
    [button setTitle:chapterName forState:UIControlStateNormal];
    if ([chapter isEqualToString:currentChapter]) {
        [button setHighlighted:YES];
    } else {
        [button setHighlighted:NO];
    }
    [button setTitle:chapter forState:UIControlStateApplication];
    return cell;
}

- (IBAction)touchDown:(UIButton *)sender
{
    NSString *chapter = [sender titleForState:UIControlStateApplication];
    [provider setChapter:chapter];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
