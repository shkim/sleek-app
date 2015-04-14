//
//  ContentVC.m
//  sleek
//
//  Created by shkim on 9/4/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import "ContentVC.h"
#import "WebLinkVC.h"
#import "ImageVC.h"
#import "WriteVC.h"
#import "SleekSession.h"
#import "AppDelegate.h"
#import "SettingsVC.h"
#import "util.h"

#import "UIViewController+ECSlidingViewController.h"

#define PENDING_TYPE_URL		1
#define PENDING_TYPE_IMAGE		2

NSRegularExpression* s_regexLine2BR = nil;
NSRegularExpression* s_regexHttp2Link = nil;
NSRegularExpression* s_regexFindImg = nil;
NSRegularExpression* s_regexFindImgHttp = nil;
NSRegularExpression* s_regexCheckImgExt = nil;
NSRegularExpression* s_regexCheckSleekImgLink = nil;

@interface ContentVC () <SleekSessionDelegate, SleekThreadWriteDelegate, UIWebViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate>
{
	UIWebView* m_webView;
	
	int m_pendingType;
	int m_pendingImageNum;
	BOOL m_bNewerPostFound;
	BOOL m_anyReplyWritten;
}

- (NSString*)makeHtml;

@end

@implementation ContentVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	if (s_regexLine2BR == nil)
	{
		s_regexLine2BR = [NSRegularExpression regularExpressionWithPattern:@"\n|\r"
			options:(NSRegularExpressionUseUnixLineSeparators) error:nil];
			
		s_regexHttp2Link = [NSRegularExpression regularExpressionWithPattern:@"([^\"'=]|^)(https?://[^ \"'<>\n\r\\)]+)"
			options:(NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators)
			error:nil];
			
		s_regexFindImg = [NSRegularExpression regularExpressionWithPattern:@"(<img\\s.+?>)"
			options:(NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators)
			error:nil];

		s_regexFindImgHttp = [NSRegularExpression regularExpressionWithPattern:@"(https?://[^ \"'<>\r\n&]+)"
			options:(NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators)
			error:nil];
			
		s_regexCheckImgExt = [NSRegularExpression regularExpressionWithPattern:@"(jpg|jpeg|gif|png)"
			options:(NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators)
			error:nil];
			
		s_regexCheckSleekImgLink = [NSRegularExpression regularExpressionWithPattern:@"img:(\\d+):(.+?)$"
			options:0 error:nil];

	}
	
	UIBarButtonItem* btnWrite = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
		target:self action:@selector(onComposeClicked)];
	self.navigationItem.rightBarButtonItem = btnWrite;

	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];

	[self renderHtml];
}

- (void)renderHtml
{
	if (m_webView == nil)
	{
		m_webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
		m_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		m_webView.delegate = self;
		m_webView.dataDetectorTypes = UIDataDetectorTypeNone;
		[self.view addSubview:m_webView];
	}

	NSString* bundlePath = [[NSBundle mainBundle] bundlePath];
	NSURL *baseURL = [NSURL fileURLWithPath:bundlePath];
	
	self.title = self.sleekThread.title;
	[m_webView loadHTMLString:[self makeHtml] baseURL:baseURL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
	
	[m_webView loadHTMLString:@"" baseURL:nil];
	m_webView.delegate = nil;
	[m_webView removeFromSuperview];
	m_webView = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.navigationController.view removeGestureRecognizer:self.slidingViewController.panGesture];
	
	if (m_webView == nil)
	{
		[self renderHtml];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if (m_anyReplyWritten)
	{
		[self.writeDelegate sleekPostedThreadId:0];
	}
}

- (void)onComposeClicked
{
	UIStoryboard* sb = self.slidingViewController.underLeftViewController.storyboard;
	WriteVC* vc = [sb instantiateViewControllerWithIdentifier:@"Write"];
	vc.writeDelegate = self;
	vc.replySubject = self.sleekThread.title;
	vc.replyThreadId = self.sleekThread.tid;
	[self.navigationController pushViewController:vc animated:YES];
}

- (void)sleekPostedThreadId:(int)tid
{
	[GetAppDelegate().currentSession getThread:tid delegate:self];
	m_anyReplyWritten = YES;
}

- (void)sleekSession:(SleekSession*)session gotThread:(Thread*)ti
{
	self.sleekThread = ti;
	[self renderHtml];
}

static int imgLinkCount;

- (NSString*)makeHtml
{
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"template" ofType:@"html"];
	NSString *templateHtml = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
	
	int fontSize4Html;
	switch(GetAppDelegate().settings.fontSize)
	{
	case CONTENT_FONTSIZE_MIN:
		fontSize4Html = 10;
		break;
	case CONTENT_FONTSIZE_MAX:
		fontSize4Html = 20;
		break;
	default:
		fontSize4Html = 15;
	}
	
	NSRange rngBody = [templateHtml rangeOfString:@"$$BODY$$"];
	ASSERT(rngBody.location != NSNotFound);
	
	NSMutableString* strbuf = [[NSMutableString alloc] initWithCapacity:8192];
	[strbuf appendString:[templateHtml substringToIndex:rngBody.location]];
	
	[strbuf replaceOccurrencesOfString:@"$FS_BODY$"
		withString:[NSString stringWithFormat:@"%d", fontSize4Html]
		options:NSLiteralSearch
		range:NSMakeRange(0, [strbuf length])];

	__weak Thread* ti = self.sleekThread;
	
	[strbuf appendFormat:@"<div class=\"title\">%@</div>", ti.title];
	
	imgLinkCount = 0;
	
	const int itemCount = (int) [ti.posts count];
	const BOOL newIsUp = GetAppDelegate().settings.orderNewIsUp;
	int iItem = newIsUp ? itemCount : 0;
	for(;;)
	{
		ThreadPost* tp;
		
		if (newIsUp)
		{
			if (iItem > 0)
				tp = [ti.posts objectAtIndex:--iItem];
			else
				break;
		}
		else
		{
			if (iItem < itemCount)
				tp = [ti.posts objectAtIndex:iItem++];
			else
				break;
		}
		
		if (!m_bNewerPostFound && tp.isNewer)
		{
			m_bNewerPostFound = YES;
			[strbuf appendFormat:@"<a id=\"LastViewPos\"></a>"];
		}
		
		[strbuf appendFormat:@"<div class=\"header\"><span class=\"nick\">%@</span>", tp.writer];
		[strbuf appendFormat:@"<span class=\"date%@\">%@</span><br/></div>", (tp.isNewer ? @"New" : @""), tp.cdateStr];

		if (tp.files != nil)
		{
			[strbuf appendString:@"<div class=\"attach\">"];
			
			for (PostFile* file in tp.files)
			{
				NSRange dotPos = [file.name rangeOfString:@"." options:NSBackwardsSearch];
				if (dotPos.location != NSNotFound)
				{
					dotPos.location += dotPos.length;
					dotPos.length = [file.name length] - dotPos.location;
				
					NSRange rngExt = [s_regexCheckImgExt rangeOfFirstMatchInString:file.name options:0 range:dotPos];
					if (rngExt.location != NSNotFound)
					{
						// image
						[strbuf appendFormat:@"<div id=\"i%d\"></div><a href=\"img:%d:%@\" class=\"image\">%@</a><br/>", imgLinkCount, imgLinkCount, file.url, file.name];
						++imgLinkCount;
						continue;
					}

				}
				
				// unknown format
				[strbuf appendFormat:@"<a href=\"unk:%@\" class=\"unkfile\">%@</a><br/>", file.url, file.name];
			}
			
			[strbuf appendString:@"</div>"];
		}
		
/*		
		.replace(/([^"'=]|^)(https?:\/\/[^ "'<>\n\r\)]+\.(jpg|jpeg|gif|png))(\n| )/ig, "$1<span class=\"au-target auurl\"><a href=\"$2\" target=\"_blank\">$2</a></span>")
		.replace(/([^"'=]|^)(https?:\/\/[^ "'<>\n\r\)]+)/g, "$1<a href=\"$2\" target=\"_blank\">$2</a>")
		.replace(/(&lt;img\s.+?&gt;)/gi, "<span class=\"au-target\">$1</span>")
		.replace(/(&lt;a\s.+?(\/a|\s\/)&gt;)/gim, "<span class=\"au-target aulink\">$1</span>")
		//.replace(/(&lt;object\s.+?&gt;)\s*((?:&lt;param.+?&gt;|&lt;\/param&gt;)*)\s*((?:&lt;embed.+?&gt;|&lt;\/embed&gt;)*)\s*(&lt;\/object&gt;)/gim, "<span class=\"au-target\">$1$2$4</span>"))
		.replace(/(&lt;object.+?\/object&gt;)/gim, "<span class=\"au-target\">$1</span>")
		.replace(/(?:^|<PRE>)((?:&lt;embed.+?&gt;|&lt;\/embed&gt;)+)/gim, "<span class=\"au-target\">$1</span>")
*/	

		NSMutableString* text = [NSMutableString stringWithString:tp.text];
		{
			[s_regexLine2BR replaceMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@"<br/>"];
			
			[s_regexHttp2Link replaceMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@"$1<a href=\"url:$2\">$2</a>"];

			NSArray *imglinks = [s_regexFindImg matchesInString:text options:0 range:NSMakeRange(0, text.length)];
			for(NSTextCheckingResult *result in [imglinks reverseObjectEnumerator])
			{
				NSRange tagRange = [result range];
				NSRange linkRange = [s_regexFindImgHttp rangeOfFirstMatchInString:text
					options:(NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators)
					range:tagRange];

				NSString* imglink = [text substringWithRange:linkRange];
				NSString* filename = [imglink lastPathComponent];
				NSString* replacement = [NSString stringWithFormat:@"<div id=\"i%d\"></div><a href=\"img:%d:%@\" class=\"image\">%@</a>", imgLinkCount, imgLinkCount, imglink, filename];
				++imgLinkCount;
				
				[text replaceCharactersInRange:tagRange withString:replacement];
			}

		}

		[strbuf appendFormat:@"<div class=\"thread\">%@</div>", text];
	}

	[strbuf appendString:[templateHtml substringFromIndex:(rngBody.location + rngBody.length)]];
	return strbuf;
}



- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
//	TRACE(@"sheet action: %d", buttonIndex);

	if (m_pendingType == PENDING_TYPE_URL)
	{
		if (buttonIndex == 0)
		{
			WebLinkVC* vc = [[WebLinkVC alloc] init];
			vc.linkUrl = sheet.title;
			[self.navigationController pushViewController:vc animated:YES];
		}
		else if (buttonIndex == 1)
		{
			NSURL* url = [NSURL URLWithString:sheet.title];
			[[UIApplication sharedApplication] openURL:url];
		}
	}
	else if (m_pendingType == PENDING_TYPE_IMAGE)
	{
		if (buttonIndex == 0)
		{
			NSString* script = [NSString stringWithFormat:@"showImage(%d,'%@')", m_pendingImageNum, sheet.title];
			//[_webView stringByEvaluatingJavaScriptFromString:script];
			[m_webView performSelector:@selector(stringByEvaluatingJavaScriptFromString:) withObject:script afterDelay:0.1];
		}
		else if (buttonIndex == 1)
		{
			ImageVC* vc = [[ImageVC alloc] init];
			vc.title = self.title;
			vc.imageUrl = sheet.title;
			[self.navigationController pushViewController:vc animated:YES];
		}
	}
}

- (void)showPopupSheet:(NSString*)url type:(int)type
{
	m_pendingType = type;
	UIActionSheet* sheet;
	
	if (type == PENDING_TYPE_URL)
	{
		NSRange range = [url rangeOfString:@"://www.youtube.com" options:NSCaseInsensitiveSearch];
		NSString* extViewTitle = (range.location == NSNotFound) ?
			GetLocalizedString(@"view_safari") : GetLocalizedString(@"view_youtube");
		
		sheet = [[UIActionSheet alloc] initWithTitle:url
			delegate:self
			cancelButtonTitle:GetLocalizedString(@"cancel")
			destructiveButtonTitle:nil
			otherButtonTitles:GetLocalizedString(@"openlink"), extViewTitle, nil];
	}
	else if (type == PENDING_TYPE_IMAGE)
	{
		sheet = [[UIActionSheet alloc] initWithTitle:url
			delegate:self
			cancelButtonTitle:GetLocalizedString(@"cancel")
			destructiveButtonTitle:nil
			otherButtonTitles:GetLocalizedString(@"insert_body"),
			GetLocalizedString(@"show_viewer"), nil];
	}
	else return;
	
//	[sheet showFromTabBar:GetAppDelegate().tabBarController.tabBar];
	[sheet showInView:GetAppDelegate().window.rootViewController.view];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[GetAppDelegate().currentSession hideHud];

	if (m_bNewerPostFound)
	{
		m_bNewerPostFound = NO;
		[webView stringByEvaluatingJavaScriptFromString:@"document.location.href='#LastViewPos'"];
	}
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if (navigationType == UIWebViewNavigationTypeLinkClicked)
	{
		NSURL* url = request.URL;
		NSString* addr = [url absoluteString];
		NSTRACE(@"addr=%@", addr);
		
		if ([addr isEqualToString:@"sleek:reply"])
		{
			//[self composeClicked];
			NSTRACE(@"TODO: compose click");
			return NO;
		}
		
		NSRange range = [addr rangeOfString:@"url:"];
		if (range.location == 0)
		{
			range.location = range.length;
			range.length = [addr length] - range.location;
			[self showPopupSheet:[addr substringWithRange:range] type:PENDING_TYPE_URL];
			return NO;
		}
		
		NSTextCheckingResult* res = [s_regexCheckSleekImgLink firstMatchInString:addr options:0 range:NSMakeRange(0, addr.length)];
		if ([res numberOfRanges] == 3)
		{
			m_pendingImageNum = [[addr substringWithRange:[res rangeAtIndex:1]] intValue];
			[self showPopupSheet:[addr substringWithRange:[res rangeAtIndex:2]] type:PENDING_TYPE_IMAGE];
			return NO;
		}

		range = [addr rangeOfString:@"unk:"];
		if (range.location == 0)
		{
			alertSimpleMessage(@"지원되지 않는 포맷입니다.");
			return NO;
		}
	}

	return YES;
}

@end
