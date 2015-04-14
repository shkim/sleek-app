//
//  AppDelegate.m
//  sleek
//
//  Created by shkim on 9/2/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import "AppDelegate.h"
#import "MainListVC.h"
#import "ServerInfoVC.h"
#import "LeftSideVC.h"
#import "RightSideVC.h"
#import "HttpMan.h"

#import "ECSlidingViewController.h"
#import "MBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>

@interface AppDelegate () <SleekSessionDelegate>
{
	HttpMan* m_httpMan;
//	ThreadListVC* m_threadListVC;
	NSMutableArray* m_sessionList;	// not actual working session, just session info list
}

@property (nonatomic, strong) ECSlidingViewController *slidingViewController;
@end

@implementation SessionListItem
@end
@implementation GlobalSettings
@end

@implementation AppDelegate

@synthesize currentSession = m_currentSession;
@synthesize settings = m_settings;
@synthesize isIpad = m_isIpad;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	m_isIpad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
	
	m_httpMan = [[HttpMan alloc] init];
	m_sessionList = [[NSMutableArray alloc] initWithCapacity:2];
	m_settings = [GlobalSettings new];

	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"sleek" bundle:nil];
	UIViewController* vcRoot;
	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	m_settings.fontSize = [ud integerForKey:PREF_KEY_FONTSIZE];
	m_settings.orderNewIsUp = [ud boolForKey:PREF_KEY_NEWISUP];
	
	NSString* lastSessName = [ud stringForKey:PREF_KEY_LASTSESSION];
	NSDictionary* dic = lastSessName == nil ? nil : [ud dictionaryForKey:lastSessName];
	if (dic == nil)
	{
		// first run, show the server-info form
		ServerInfoVC* vc = [storyboard instantiateViewControllerWithIdentifier:@"ServerInfo"];
		vc.isFirstServer = YES;
		vcRoot = vc;
		m_currentSession = nil;
	}
	else
	{		
		// goto sleek
		MainListVC* vc = [storyboard instantiateViewControllerWithIdentifier:@"MainList"];
		vcRoot = vc;

		m_currentSession = [[SleekSession alloc] initWithDictionary:dic];
		[self updateSessionList];
	}

	UINavigationController* navVC = [[UINavigationController alloc] initWithRootViewController:vcRoot];
	navVC.navigationBar.barTintColor = [UIColor colorWithRed:(96/255.0) green:(128/255.0) blue:(180/255.0) alpha:0.1];
	navVC.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
	navVC.navigationBar.tintColor = [UIColor whiteColor];	// back button color

	self.slidingViewController = [ECSlidingViewController slidingWithTopViewController:navVC];
	self.slidingViewController.topViewAnchoredGesture = ECSlidingViewControllerAnchoredGesturePanning | ECSlidingViewControllerAnchoredGestureTapping;

	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = self.slidingViewController;
	[self.window makeKeyAndVisible];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

	if (m_currentSession != nil)
	{
		[m_currentSession doLogin:self];
		[self setupSideVCs:storyboard];
	}
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)saveSettings
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
#ifdef DEBUG
	exit(0);
#endif
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}



- (MBProgressHUD*)createHUD
{
	MBProgressHUD* hud = [[MBProgressHUD alloc] initWithView:self.slidingViewController.view];
	[self.slidingViewController.view addSubview:hud];
	hud.removeFromSuperViewOnHide = YES;
	return hud;
}

- (MBProgressHUD*)createToast
{
	MBProgressHUD* toast = [[MBProgressHUD alloc] initWithWindow:GetAppDelegate().window];
	[self.slidingViewController.view addSubview:toast];
	toast.removeFromSuperViewOnHide = YES;
	toast.mode = MBProgressHUDModeText;
	toast.userInteractionEnabled = NO;
	toast.margin = 10.f;
	toast.yOffset = self.slidingViewController.view.frame.size.height * 0.5f - 50;

	return toast;
}

- (HttpMan*)getHttpManager
{
	return m_httpMan;
}

- (void)setupSideVCs:(UIStoryboard*)storyboard
{
	LeftSideVC* vcLeft = [storyboard instantiateViewControllerWithIdentifier:@"LeftSide"];
	self.slidingViewController.underLeftViewController = vcLeft;

	RightSideVC* vcRight = [storyboard instantiateViewControllerWithIdentifier:@"RightSide"];
	self.slidingViewController.underRightViewController = vcRight;

	CGFloat amount = m_isIpad ? 88 : 44;
	self.slidingViewController.anchorRightPeekAmount = amount;
	self.slidingViewController.anchorLeftPeekAmount = amount;
	
	CALayer* layer = self.slidingViewController.topViewController.view.layer;

	layer.masksToBounds = NO;
	//layer.cornerRadius = 8;
	layer.shadowRadius = 16;
	layer.shadowOpacity = 0.9;
//	layer.shadowOffset = CGSizeMake(-15, 20);
	
//	layer.cornerRadius = 3;
//	layer.masksToBounds = YES;

}

- (void)dismissServerInfoAndShowMainList:(ServerInfoVC*)sviVC
{
	MainListVC* vc = [sviVC.storyboard instantiateViewControllerWithIdentifier:@"MainList"];
	UINavigationController* navVC = (UINavigationController*) self.slidingViewController.topViewController;
	[navVC setViewControllers:@[vc] animated:NO];
	
	[self setupSideVCs:vc.storyboard];
}

- (void)sleekSessionLoginPassed:(SleekSession*)session
{
	[self setCurrentSession:session];
}

- (void)setCurrentSession:(SleekSession*)session
{
	m_currentSession = session;
	
	for (SessionListItem* sli in m_sessionList)
	{
		sli.isCurrent = [sli.key isEqualToString:session.saveKey];
	}
	
	UINavigationController* navVC = (UINavigationController*) self.slidingViewController.topViewController;
	MainListVC* mainListVC = navVC.viewControllers[0];
	[mainListVC onSessionChanged:session];
}

- (void)updateSessionList
{
	[m_sessionList removeAllObjects];
	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSArray* arrSess = [ud arrayForKey:PREF_KEY_ALLSESSIONS];
	
	for (NSString* key in arrSess)
	{
		NSDictionary* dic = [ud dictionaryForKey:key];
		if (dic != nil)
		{
			SessionListItem* sli = [[SessionListItem alloc] init];
			sli.key = key;
			sli.name = [dic objectForKey:PREF_KEY_SITENAME];
			sli.isCurrent = [key isEqualToString:self.currentSession.saveKey];
			[m_sessionList addObject:sli];
		}
	}
	
//	[(SideRightVC*)self.mainVC.rightPanel onSessionListChanged];
}

- (NSArray*)getSessionList
{
	return m_sessionList;
}

@end
