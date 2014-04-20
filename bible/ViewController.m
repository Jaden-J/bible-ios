//
//  ViewController.m
//  bible
//
//  Created by Thom on 14-4-15.
//  Copyright (c) 2014 Liu DongMiao. All rights reserved.
//

#import "ViewController.h"
#import "BibleProvider.h"

@interface ViewController ()

@end

@implementation ViewController {
    NSURL *baseurl;
    BibleProvider *provider;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // http://stackoverflow.com/questions/9897978
    self.navigation.leftBarButtonItems = [NSArray arrayWithObjects:self.book, self.chapter, self.version, nil];
    // self.navigation.rightBarButtonItems = [NSArray arrayWithObjects:self.action, self.search, nil];

    // http://stackoverflow.com/questions/2455367
    self.navigation.title = NSLocalizedString(@"Reading", "Title for back to Reading Page");
    self.navigation.titleView = [[UILabel alloc] init];

    baseurl = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    provider = [BibleProvider defaultProvider];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)swipeLeft:(id)sender
{
    if ([provider nextChapter]) {
        [self reload];
    }
}

- (IBAction)swipeRight:(id)sender
{
    if ([provider previousChapter]) {
        [self reload];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.version setTitle:[provider getVersionShortName:provider.version]];
    [self reload];
}

- (void)reload
{
    [self.book setTitle:[provider getBookName:provider.chapter]];
    [self.chapter setTitle:[provider getChapterName:provider.chapter]];
    [self.webview loadHTMLString:provider.content baseURL:baseurl];
}

@end
