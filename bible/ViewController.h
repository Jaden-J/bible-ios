//
//  ViewController.h
//  bible
//
//  Created by Thom on 14-4-15.
//  Copyright (c) 2014 Liu DongMiao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *book;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *chapter;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *version;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *search;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *action;

@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigation;

- (void)reload;

@end
