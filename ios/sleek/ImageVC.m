//
//  ImageVC.m
//  SleekClient
//
//  Created by shkim on 5/27/13.
//  Copyright (c) 2013 shkim. All rights reserved.
//

#import "ImageVC.h"
#import "HttpMan.h"
#import "AppDelegate.h"
#import "util.h"

#define JOBID_DOWNLOAD_IMAGE	999

#define PENDING_ALERT_DOWNFAIL		1
#define PENDING_ALERT_SAVECONFIRM	2

@interface ArcProgressView : UIView
{
	float m_currentProgress;
}

- (ArcProgressView*)initWithFrame:(CGRect)frame;
- (void)setProgress:(float)progress;

@end

@implementation ArcProgressView

- (ArcProgressView*)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	return self;
}

- (void)setProgress:(float)progress
{
	m_currentProgress = progress;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGRect allRect = self.bounds;   
	CGRect circleRect = CGRectMake(allRect.origin.x + 2, allRect.origin.y + 2, allRect.size.width - 4, allRect.size.height - 4);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Draw background
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0); // white
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 0.2); // translucent white
	CGContextClearRect(context, allRect);
//	CGContextSetRGBFillColor(context, 0,0,0, 1);
	CGContextSetLineWidth(context, 2.0);
	CGContextFillEllipseInRect(context, circleRect);
	CGContextStrokeEllipseInRect(context, circleRect);
	
	// Draw progress
	float x = (allRect.size.width / 2);
	float y = (allRect.size.height / 2);
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0); // white
	CGContextMoveToPoint(context, x, y);
	CGContextAddArc(context, x, y, (allRect.size.width - 4) / 2, -(M_PI / 2), (m_currentProgress * 2 * M_PI) - M_PI / 2, 0);
	CGContextClosePath(context);
	CGContextFillPath(context);
}

@end


#pragma mark -

@interface ImageVC () <UIScrollViewDelegate, HttpQueryDelegate>
{
	UIScrollView* m_scrView;
	UIImageView* m_imgView;
	ArcProgressView* m_arcPrgsView;
	
	int m_pendingAlert;
}

@end

@implementation ImageVC

- (void)viewDidLoad
{
	[super viewDidLoad];

	CGRect frame = [UIScreen mainScreen].bounds;
	self.view.frame = frame;
	
	m_scrView = [[UIScrollView alloc] initWithFrame:frame];
	m_scrView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	m_scrView.multipleTouchEnabled = YES;
	m_scrView.opaque = YES;
	m_scrView.userInteractionEnabled = YES;
	m_scrView.clipsToBounds = YES;
	m_scrView.contentMode = UIViewContentModeCenter;
	m_scrView.delegate = self;
	m_scrView.minimumZoomScale = 1;
	m_scrView.maximumZoomScale = 4;
	m_scrView.decelerationRate = .85;
	[self.view addSubview:m_scrView];

	CGRect arcFrm;
	arcFrm.size.width = 100;
	arcFrm.size.height = 100;
	arcFrm.origin.x = (frame.size.width - arcFrm.size.width) /2;
	arcFrm.origin.y = (frame.size.height - arcFrm.size.height) /2;
	m_arcPrgsView = [[ArcProgressView alloc] initWithFrame:arcFrm];
	m_arcPrgsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin 
		| UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
	[m_scrView addSubview:m_arcPrgsView];

	
	HttpQuerySpec* spec = [HttpQuerySpec new];
	spec.resultType = HQRT_BINARY_WITH_PROGRESS;
	[spec setUrl:self.imageUrl];
	[GetHttpMan() request:JOBID_DOWNLOAD_IMAGE forSpec:spec delegate:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if (m_imgView == nil)
	{
		[GetHttpMan() cancelJob:JOBID_DOWNLOAD_IMAGE];
	}
	
	[UIApplication sharedApplication].statusBarHidden = NO;
	[self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)httpQueryJob:(int)jobId didFailWithStatus:(int)status forSpec:(HttpQuerySpec*)spec
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
		message:GetLocalizedString(@"imgdown_fail")
		delegate:self cancelButtonTitle:GetLocalizedString(@"ok") otherButtonTitles:nil];
		
	m_pendingAlert = PENDING_ALERT_DOWNFAIL;
	[alert show];
}

- (void)httpQueryJob:(int)jobId progressSoFar:(NSUInteger)current progressTotal:(NSUInteger)total forSpec:(HttpQuerySpec*)spec
{
	NSTRACE(@"Prgs: curr=%d, total=%d", current, total);
	float progress = (float)current / (float)total;
	[m_arcPrgsView setProgress:progress];
}

- (void)httpQueryJob:(int)jobId didSucceedWithResult:(id)result forSpec:(HttpQuerySpec*)spec
{
	ASSERT(jobId == JOBID_DOWNLOAD_IMAGE);
	[m_arcPrgsView removeFromSuperview];
	m_arcPrgsView = nil;
	
	UIImage* image = [[UIImage alloc] initWithData:(NSData*)result];
	ASSERT(image != nil);
	[self setupImage:image];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	NSTRACE(@"will rotate: %.1f, %.1f, %.1f", m_scrView.frame.size.width, m_scrView.frame.size.height, m_scrView.zoomScale);
	[self resetImageFrame:m_scrView.zoomScale];
}






















- (void)resetImageFrame:(CGFloat)curZoom
{
	CGSize sizeImage = m_imgView.image.size;
	CGSize sizeScreen = m_scrView.bounds.size;
	
	const CGFloat ratioImg = sizeImage.width / sizeImage.height;
    const CGFloat ratioScr = sizeScreen.width / sizeScreen.height;
	
	CGRect frameImg;
	
	if (ratioScr < ratioImg)
	{
		// fit width
		frameImg.size.width = sizeScreen.width;
		frameImg.size.height = sizeImage.height * sizeScreen.width / sizeImage.width;
		frameImg.origin.x = 0;
		frameImg.origin.y = (sizeScreen.height - frameImg.size.height) /2;
	}
	else
	{
		// fit height
		frameImg.size.height = sizeScreen.height;
		frameImg.size.width = sizeImage.width * sizeScreen.height / sizeImage.height;
		frameImg.origin.y = 0;
		frameImg.origin.x = (sizeScreen.width - frameImg.size.width) /2;
	}

	UIEdgeInsets insets;
	insets.top = insets.bottom = frameImg.origin.y;
	insets.left = insets.right = frameImg.origin.x;
	
	m_scrView.contentInset = insets;
	m_scrView.contentSize = frameImg.size;
	frameImg.origin = CGPointMake(0,0);
	m_imgView.frame = frameImg;
	m_scrView.zoomScale = curZoom;
}

- (void)onSaveClick
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:GetLocalizedString(@"q_save_album")
		message:[NSString stringWithFormat:@"이미지 (%.0fx%.0f)", m_imgView.image.size.width, m_imgView.image.size.height]
		delegate:self
		cancelButtonTitle:GetLocalizedString(@"no")
		otherButtonTitles:GetLocalizedString(@"yes"), nil];

	m_pendingAlert = PENDING_ALERT_SAVECONFIRM;
	[alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (m_pendingAlert == PENDING_ALERT_DOWNFAIL)
	{
		[self.navigationController popViewControllerAnimated:YES];
		return;
	}
	
	m_pendingAlert = 0;
	
	if (buttonIndex != 1)
		return;

	UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
	[activityView startAnimating];
	[activityView sizeToFit];
	[activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
	UIBarButtonItem *loadingView = [[UIBarButtonItem alloc] initWithCustomView:activityView];
	[self.navigationItem setRightBarButtonItem:loadingView];
	
	// NSString* filename [imageUrl lastPathComponent];
	UIImageWriteToSavedPhotosAlbum(m_imgView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void) image:(UIImage*)image didFinishSavingWithError:(NSError *)error contextInfo:(NSDictionary*)info
{
	self.navigationItem.rightBarButtonItem = nil;
	alertSimpleMessage(GetLocalizedString(@"img_saved"));
}




- (void)setupImage:(UIImage*)img
{
	m_imgView = [[UIImageView alloc] initWithImage:img];	
	m_imgView.contentMode = UIViewContentModeScaleAspectFit;
	m_imgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	[self resetImageFrame:1];

	[m_scrView addSubview:m_imgView];
	
	// add gesture recognizers to the image view
	UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTap:)];

	[doubleTap setNumberOfTapsRequired:2];
	[twoFingerTap setNumberOfTouchesRequired:2];

	[m_scrView addGestureRecognizer:singleTap];
	[m_scrView addGestureRecognizer:doubleTap];
	[m_scrView addGestureRecognizer:twoFingerTap];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
		target:self action:@selector(onSaveClick)];

}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return m_imgView;
}

#define ZOOM_STEP 1.5

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center
{
	CGRect zoomRect;

	// the zoom rect is in the content view's coordinates. 
	//    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
	//    As the zoom scale decreases, so more content is visible, the size of the rect grows.
	zoomRect.size.height = [m_scrView frame].size.height / scale;
	zoomRect.size.width  = [m_scrView frame].size.width  / scale;

	// choose an origin so as to get the right center.
	zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
	zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);

	return zoomRect;
}

- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
	UIApplication* app = [UIApplication sharedApplication];
	
	if (app.statusBarHidden)
	{
		// show
		[app setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
		[self.navigationController setNavigationBarHidden:NO animated:YES];
	}
	else
	{
		// hide
		[app setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
		[self.navigationController setNavigationBarHidden:YES animated:YES];
	}
}

- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
	// double tap zooms in
	float newScale = [m_scrView zoomScale] * ZOOM_STEP;
	if (newScale >= m_scrView.maximumZoomScale)
		return;
		
	CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gestureRecognizer locationInView:m_imgView]];
	[m_scrView zoomToRect:zoomRect animated:YES];
}

- (void)handleTwoFingerTap:(UIGestureRecognizer *)gestureRecognizer
{
	// two-finger tap zooms out
	float newScale = [m_scrView zoomScale] / ZOOM_STEP;
	if (newScale <= m_scrView.minimumZoomScale)
		return;
	
	CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[gestureRecognizer locationInView:m_imgView]];
	[m_scrView zoomToRect:zoomRect animated:YES];
}

@end
