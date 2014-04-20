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

- (void)viewWillDisappear:(BOOL)animated
{
    [self.webview stringByEvaluatingJavaScriptFromString:@"getFirstVisibleVerse()"];
    [provider save];
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

- (void)setVerse:(NSString *)verse
{
    [provider setVerse:verse];
}

- (void)setCopyText:(NSString *)selected
{
    NSArray *array = [selected componentsSeparatedByString:@"\n"];
    [provider setSelected:array[1]];
    // TODO: content
}

- (void)setHighlighted:(NSString *)highlighted
{
    NSLog(@"setHighlighted: %@", highlighted);
}

- (void)showAnnotation:(NSString *)link
{
    NSString *title;
    if ([link rangeOfString:@"!f."].location != NSNotFound || [link hasPrefix:@"f"]) {
        title = NSLocalizedString(@"footnote", nil);
    } else if ([link rangeOfString:@"!x."].location != NSNotFound || [link hasPrefix:@"c"]){
        title = NSLocalizedString(@"cross reference", nil);
    } else {
        return;
    }
    NSString *annotation = [provider getAnnotation:link];
    if (annotation == nil || [annotation length] == 0) {
        return;
    }
    NSString *html = [NSString stringWithFormat:@"html2text('%@')", annotation];
    NSString *message = [self.webview stringByEvaluatingJavaScriptFromString:html];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil
                          cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    [alert show];
}

- (void)showNote:(NSString *)note
{
    NSLog(@"showNote: %@", note);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];
    if ([[url scheme] isEqualToString:@"bible"]) {
        NSString *method = [url host];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString([method stringByAppendingString:@":"]);
        if ([self respondsToSelector:selector]) {
            NSString *payload = [webView stringByEvaluatingJavaScriptFromString:@"window.payload"];
            [self performSelector:selector withObject:payload];
        }
#pragma clang diagnostic pop
        return NO;
    } else {
        return YES;
    }
}

@end
