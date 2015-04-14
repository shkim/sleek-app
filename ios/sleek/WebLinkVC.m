//
//  WebLinkVC.m
//  SleekClient
//
//  Created by shkim on 5/27/13.
//  Copyright (c) 2013 shkim. All rights reserved.
//

#import "WebLinkVC.h"

@interface WebLinkVC ()
{
	UIWebView* m_webView;
	UIActivityIndicatorView* m_activityWait;
}

@end

@implementation WebLinkVC

- (void)viewDidLoad
{
    [super viewDidLoad];

	m_webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
	m_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	m_webView.delegate = self;
	[self.view addSubview:m_webView];
	
	m_activityWait = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	m_activityWait.hidesWhenStopped = YES;
	m_activityWait.frame = m_webView.frame;
	[m_activityWait startAnimating];
	[self.view addSubview:m_activityWait];
	
	NSURL *_url = [NSURL URLWithString:self.linkUrl];
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:_url];
	[m_webView loadRequest:requestObj];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[m_activityWait stopAnimating];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	[m_activityWait startAnimating];
	return YES;
}

@end
