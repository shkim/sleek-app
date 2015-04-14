//
//  MainListVC.m
//  sleek
//
//  Created by shkim on 9/4/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import "MainListVC.h"
#import "AppDelegate.h"
#import "ContentVC.h"
#import "WriteVC.h"
#import "LeftSideVC.h"
#import "RightSideVC.h"
#import "SettingsVC.h"

#import "UIViewController+ECSlidingViewController.h"

@implementation NormalListCell

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	[self.lbCategory setEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 4) andCornerRadius:4];
	[self.lbReplyCount setEdgeInsets:UIEdgeInsetsMake(0, 3, 0, 3) andCornerRadius:6];
	
	UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:(76.0/255.0) green:(161.0/255.0) blue:(255.0/255.0) alpha:1.0];
    bgColorView.layer.masksToBounds = YES;
    self.selectedBackgroundView = bgColorView;
}

- (void)setup:(ThreadListItem*)info
{
	self.lbSubject.text = info.title;
	self.lbWriter.text = info.writer;
	self.lbViewCount.text = [NSString stringWithFormat:@"%d", info.hit];

	self.lbCategory.text = info.categoryName;
	
	if (info.isUnreadNew)
	{
		self.lbSubject.textColor = [UIColor blueColor];
		self.lbUpdateTime.textColor = [UIColor blueColor];
	}
	else
	{
		self.lbSubject.textColor = [UIColor blackColor];
		self.lbUpdateTime.textColor = [UIColor grayColor];
	}
	
	if (info.length > 1)
	{
		self.lbReplyCount.hidden = NO;
		self.lbReplyCount.text = [NSString stringWithFormat:@"%d", info.length];
	}
	else
	{
		self.lbReplyCount.hidden = YES;
	}
	
	int curTimestamp = [[NSDate date] timeIntervalSince1970];
	int timediff = curTimestamp - info.timestamp;

	NSString* dateStr;
	if (timediff <= 60)
	{
		dateStr = @"1분 전";
	}
	else if (timediff < 60*60)
	{
		dateStr = [NSString stringWithFormat:@"%d분 전", timediff/60];
	}
	else if (timediff < 60*60*24)
	{
		int hour = timediff/(60*60);
		int minute = (timediff - (hour * 60*60))/60;
		dateStr = [NSString stringWithFormat:@"%d시간 %d분 전", hour, minute];
	}
	else if (timediff < 60*60*24*2)
	{
		dateStr = [NSString stringWithFormat:@"어제 %02d:%02d", info.dateHour, info.dateMinute];
	}
	else if (timediff < 60*60*24*3)
	{
		dateStr = [NSString stringWithFormat:@"그저께 %02d:%02d", info.dateHour, info.dateMinute];
	}
	else
	{
		//dateStr = tli.udateStr;
		if (info.dateYear == 0)
		{
			dateStr = [NSString stringWithFormat:@"%d월 %d일 %d시 %d분",
				info.dateMonth, info.dateDay, info.dateHour, info.dateMinute];
		}
		else
		{
			dateStr = [NSString stringWithFormat:@"%d년 %d월 %d일 %d시 %d분",
				info.dateYear, info.dateMonth, info.dateDay, info.dateHour, info.dateMinute];
		}
	}
	
	self.lbUpdateTime.text = dateStr;
}

@end

@interface MainListVC () <SleekThreadWriteDelegate>
{
	NSInteger m_selectedIndexPathRow;
	int m_writtenThreadId;
	BOOL m_needRefreshList;
}

@end

@implementation MainListVC

+ (UIImage*)leftSideButtonImage
{
	static UIImage *leftSideImage = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(20.f, 13.f), NO, 0.0f);
		
		[[UIColor blackColor] setFill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 20, 1)] fill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(0, 5, 20, 1)] fill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(0, 10, 20, 1)] fill];
		
		[[UIColor whiteColor] setFill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(0, 1, 20, 2)] fill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(0, 6,  20, 2)] fill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(0, 11, 20, 2)] fill];   
		
		leftSideImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	});
	
    return leftSideImage;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	self.title = @"슬릭앱";

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
		target:self action:@selector(onComposeClicked)];

	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[self class] leftSideButtonImage]
		style:UIBarButtonItemStylePlain target:self action:@selector(toggleLeftSide)];
		
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

	UIRefreshControl* refreshControl = [[UIRefreshControl alloc]init];
    [refreshControl addTarget:self action:@selector(onRefreshControlFired) forControlEvents:UIControlEventValueChanged];
	self.refreshControl = refreshControl;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
	
	if (m_needRefreshList)
	{
		m_needRefreshList = NO;
		SleekSession* session = GetAppDelegate().currentSession;
		[session selectCategory:session.categoryId delegate:self];
	}
	
	if ([self.tableView numberOfRowsInSection:0] > 0)
	{
		[self.tableView reloadData];
	}
}

- (void)toggleLeftSide
{
	if ([self.slidingViewController currentTopViewPosition] == ECSlidingViewControllerTopViewPositionCentered)
	{
		[self.slidingViewController anchorTopViewToRightAnimated:YES];
	}
	else
	{
		[self.slidingViewController resetTopViewAnimated:YES];
	}
}

- (void)onRefreshControlFired
{
	[self.refreshControl endRefreshing];

	SleekSession* session = GetAppDelegate().currentSession;
	[session selectCategory:session.categoryId delegate:self];
}

- (void)onComposeClicked
{
	WriteVC* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Write"];
	vc.boardCategoryId = GetAppDelegate().currentSession.categoryId;
	vc.writeDelegate = self;
	[self.navigationController pushViewController:vc animated:YES];
}

- (void)sleekPostedThreadId:(int)tid
{
	NSTRACE(@"ret from write, request tid %d", tid);
	m_needRefreshList = YES;
	m_writtenThreadId = tid;
}

+ (MainListVC*)getMainListVC:(ECSlidingViewController*)slidingVC
{
	UINavigationController* navVC = (UINavigationController*) slidingVC.topViewController;
	return navVC.viewControllers[0];
}

+ (void)resetTopAndGoSettings:(ECSlidingViewController*)slidingVC
{
	UINavigationController* navVC = (UINavigationController*) slidingVC.topViewController;
	MainListVC* celf = navVC.viewControllers[0];
	SettingsVC* vc = [celf.storyboard instantiateViewControllerWithIdentifier:@"Settings"];
	
	[slidingVC resetTopViewAnimated:NO onComplete:^{
		[navVC pushViewController:vc animated:YES];
	}];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSArray* arr = GetAppDelegate().currentSession.threads;
	return [arr count] + (GetAppDelegate().currentSession.isLastPage ? 0:1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	SleekSession* session = GetAppDelegate().currentSession;
	NSArray* arr = session.threads;
	
	if (session.isLastPage == NO && indexPath.row == [arr count])
	{
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"WaitMoreCell"];
		[session getMoreThreads:self];
		return cell;
	}
	else
	{
		NormalListCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NormalCell"];
		
		if (indexPath.row < arr.count)
		{
			ThreadListItem* item = [arr objectAtIndex:indexPath.row];
			[cell setup:item];
		}
		
		return cell;
	}
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray* arr = GetAppDelegate().currentSession.threads;
	ThreadListItem* tli = [arr objectAtIndex:indexPath.row];
	
	[GetAppDelegate().currentSession getThread:tli.tid delegate:self];
	m_selectedIndexPathRow = indexPath.row;
}

#pragma mark -- Sleek session

- (void)onSessionChanged:(SleekSession*)session
{
	self.title = session.siteTitle;
	
	[GetAppDelegate().currentSession selectCategory:0 delegate:self];

	LeftSideVC* leftVC = (LeftSideVC*) self.slidingViewController.underLeftViewController;
	[leftVC onSessionChanged];
	
	RightSideVC* rightVC = (RightSideVC*) self.slidingViewController.underRightViewController;
	[rightVC onSessionChanged];
}

- (void)sleekSession:(SleekSession*)session selectedCategory:(BOOL)isLast
{
	self.title = session.categoryName;
	[self.tableView reloadData];
	
	if (m_writtenThreadId != 0)
	{
		[GetAppDelegate().currentSession getThread:m_writtenThreadId delegate:self];
		m_selectedIndexPathRow = -1;
		m_writtenThreadId = 0;
	}
}

- (void)sleekSession:(SleekSession*)session gotThread:(Thread*)ti
{
	if (m_selectedIndexPathRow < 0)
	{
		// go to view directly (just before written)
	}
	else
	{
		NSArray* arr = GetAppDelegate().currentSession.threads;
		ThreadListItem* tli = [arr objectAtIndex:m_selectedIndexPathRow];
		if (tli.tid == ti.tid && tli.isUnreadNew)
		{
			[session updateLastAccessTime:tli.udate];
		}
		
		[self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:m_selectedIndexPathRow inSection:0] animated:NO];
	}
	
	ContentVC* vc = [[ContentVC alloc] init];
	vc.sleekThread = ti;
	vc.writeDelegate = self;
	[self.navigationController pushViewController:vc animated:YES];
}

@end
