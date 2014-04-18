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
    NSIndexPath *index;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Choose Chapter", nil);
    provider = [BibleProvider defaultProvider];
    chapters = provider.chapters;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [chapters count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    NSString *osis = chapters[indexPath.row];
    NSString *chapterName = [provider getChapterName:osis];
    UIButton *button = (UIButton *)[cell viewWithTag:100];
    [button setTitle:chapterName forState:UIControlStateNormal];
    if ([osis isEqualToString:provider.osis]) {
        [button setHighlighted:YES];
        index = indexPath;
    } else {
        [button setHighlighted:NO];
    }
    [button setTitle:osis forState:UIControlStateApplication];
    return cell;
}

- (IBAction)touchDown:(UIButton *)sender
{
    NSString *osis = [sender titleForState:UIControlStateApplication];
    [provider changeOSIS:osis];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
