//
//  SleekSession.m
//  SleekClient
//
//  Created by shkim on 5/16/13.
//  Copyright (c) 2013 shkim. All rights reserved.
//

#import "SleekSession.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "ServerInfoVC.h"
#import "util.h"

#define JOBID_LOGIN				101
#define JOBID_HELLO				102
#define JOBID_INITUSER			103
#define JOBID_REFRESH_THREADS	110
#define JOBID_GETMORE_THREADS	111
#define JOBID_FETCH_THREAD		121
#define JOBID_POST_THREAD		131

#define THREADLIST_PAGESIZE		20

static NSCharacterSet* s_dateSplitters;
static int s_curYear;

@implementation BoardCategory
@end

@implementation PostFile
@end

@implementation ThreadPost
@end

@implementation Thread
@end

@implementation ThreadWriteItem
@end

@implementation ThreadListItem
- (void)parseDate
{
	NSArray* arr = [self.udateStr componentsSeparatedByCharactersInSet:s_dateSplitters];
	self.dateYear = [[arr objectAtIndex:0] intValue];
	self.dateMonth = [[arr objectAtIndex:1] intValue];
	self.dateDay = [[arr objectAtIndex:2] intValue];
	self.dateHour = [[arr objectAtIndex:3] intValue];
	self.dateMinute = [[arr objectAtIndex:4] intValue];
	int second = [[arr objectAtIndex:5] intValue];
	//TRACE(@"parse('%@')->%d-%d-%d %d:%d:%d", self.udateStr, self.dateYear, self.dateMonth, self.dateDay, self.dateHour, self.dateMinute, second);

	NSDateComponents* dtcom = [[NSDateComponents alloc] init];
	[dtcom setYear:self.dateYear];
	[dtcom setMonth:self.dateMonth];
	[dtcom setDay:self.dateDay];
	[dtcom setHour:self.dateHour];
	[dtcom setMinute:self.dateMinute];
	[dtcom setSecond:second];
	NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:dtcom];
	self.timestamp = [date timeIntervalSince1970];
	
	if (self.dateYear == s_curYear)
		self.dateYear = 0;
}
@end

@interface SleekSession ()
{
	NSString* m_saveKey;
	NSString* m_address;
	int m_port;
	NSString* m_password;
	
	NSString* m_uploadUrl;
	
	NSMutableArray* m_boardCategories;
	int m_lastRequestedCategoryId;
	__weak NSString* m_lastRequestedCategoryName;
	int m_curPage;	// 1=latest
	BOOL m_isCurPageLast;

	BOOL m_onMoreLoading;
	double m_lastMoreLoadingTick;
	
	NSMutableArray* m_threads;
	
	long long m_lastAccessTime;
	long long m_newLastAccessTime;	// will be saved on terminate
	
	MBProgressHUD* m_hud;
}
@end

@implementation SleekSession

@synthesize boardCategories = m_boardCategories;
@synthesize threads = m_threads;
@synthesize categoryId = m_lastRequestedCategoryId;
@synthesize categoryName = m_lastRequestedCategoryName;
@synthesize saveKey = m_saveKey;
@synthesize isLastPage = m_isCurPageLast;

- (void)saveSettings
{
	if (self.saveKey != nil && m_lastAccessTime != m_newLastAccessTime)
	{
		NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
		NSDictionary* _dic = [ud dictionaryForKey:self.saveKey];
		if (_dic != nil)
		{
			if (m_newLastAccessTime == 0)
				m_newLastAccessTime = m_lastAccessTime;
			
			NSMutableDictionary* dic = [_dic mutableCopy];
			[dic setObject:[NSNumber numberWithLongLong:m_newLastAccessTime] forKey:PREF_KEY_LASTACESSTIME];
			[ud setObject:dic forKey:self.saveKey];
		}
	}
}

- (void)setAddress:(NSString*)address
{
	NSRange rng = [address rangeOfString:@":"];
	if (rng.length == 0)
	{
		m_address = address;
		m_port = 80;
	}
	else
	{
		m_address = [address substringToIndex:rng.location];
		m_port = [[address substringFromIndex:(rng.location+1)] intValue];
	}
	
	m_saveKey = [NSString stringWithFormat:@"%@:%d", m_address, m_port];
	
	m_threads = [[NSMutableArray alloc] initWithCapacity:THREADLIST_PAGESIZE];
	
	s_dateSplitters = [NSCharacterSet characterSetWithCharactersInString:@"- :"];
}

- (void)initCommon
{
	m_lastRequestedCategoryId = -1;
	m_isCurPageLast = YES;
}

- (id)initWithAddress:(NSString*)address andPassword:(NSString*)passwd
{
	self = [super init];
	if (self)
	{
		[self setAddress:address];
		m_password = passwd;
		[self initCommon];
	}
	
	return self;
}

- (id)initWithDictionary:(NSDictionary*)dic
{
	self = [super init];
	if (self)
	{
		[self setAddress:[dic objectForKey:PREF_KEY_ADDRESS]];
		self.nickname = [dic objectForKey:PREF_KEY_NICKNAME];
		self.siteTitle = [dic objectForKey:PREF_KEY_SITENAME];
		m_password = [dic objectForKey:PREF_KEY_PASSWORD];
		
		m_lastAccessTime = [[dic objectForKey:PREF_KEY_LASTACESSTIME] longLongValue];
		m_newLastAccessTime = m_lastAccessTime;
		
		[self initCommon];
	}
	
	return self;
}

- (NSDictionary*)makeDictionaryForSave
{
	NSMutableDictionary* dic = [[NSMutableDictionary alloc] initWithCapacity:4];
	
	[dic setObject:m_saveKey forKey:PREF_KEY_ADDRESS];
	[dic setObject:self.siteTitle forKey:PREF_KEY_SITENAME];
	[dic setObject:self.nickname forKey:PREF_KEY_NICKNAME];
	[dic setObject:m_password forKey:PREF_KEY_PASSWORD];

	return dic;
}

- (HttpQuerySpec*)getEmptySpec:(id<SleekSessionDelegate>)theDelegate;
{
	HttpQuerySpec* spec = [HttpQuerySpec new];
	spec.isIgnoreCache = YES;
	spec.address = m_address;
	spec.port = m_port;
	spec.userObj = theDelegate;
	
	return spec;
}

- (void)httpQueryJob:(int)jobId didFailWithStatus:(int)status forSpec:(HttpQuerySpec*)spec
{
	[self hideHud];

	if (jobId == JOBID_LOGIN)
	{
		//id<SleekSessionDelegate> deleg = (id<SleekSessionDelegate>)spec.userObj;
		alertSimpleMessage(GetLocalizedString(@"a_login_fail"));
	}
}

- (void)onJobLogin:(NSDictionary*)dic delegate:(id<SleekSessionDelegate>)theDelegate
{
	if ([dic objectForKey:@"user"] != nil)
	{
		HttpQuerySpec* spec = [self getEmptySpec:theDelegate];
		spec.resultType = HQRT_JSON;
		spec.path = @"/api/hello";
		
		[GetHttpMan() request:JOBID_HELLO forSpec:spec delegate:self];
	}
	else
	{
		dic = [dic objectForKey:@"err"];
		NSString* msg = (dic != nil) ? [dic objectForKey:@"message"] : GetLocalizedString(@"unk_error");
		
		[self hideHud];

		alertSimpleMessage(msg);
	}
}

- (void)onJobHello:(NSDictionary*)dic delegate:(id<SleekSessionDelegate>)theDelegate
{
	self.siteTitle = [dic objectForKey:@"name"];
	
	if (m_lastAccessTime == 0)
	{
		m_lastAccessTime = [[dic objectForKey:@"time"] longLongValue];
	}
	
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]];
	s_curYear = (int)[components year];
	
	HttpQuerySpec* spec = [self getEmptySpec:theDelegate];
	spec.resultType = HQRT_JSON;
	spec.path = @"/api/sessions";
	
	[GetHttpMan() request:JOBID_INITUSER forSpec:spec delegate:self];
}

- (void)onJobInitUser:(NSDictionary*)dic delegate:(id<SleekSessionDelegate>)theDelegate
{
	[self hideHud];
	
	BOOL success = NO;
	if (dic != nil)
	{
		//NSString* userName = [dic objectForKey:@"name"];
		NSArray* cates = [dic objectForKey:@"categoriesOrdered"];
		if (cates != nil)
		{
			m_boardCategories = [[NSMutableArray alloc] initWithCapacity:[cates count]];
			
			for (NSDictionary* cate in cates)
			{
				BoardCategory* item = [BoardCategory new];
				item.cid = [[cate objectForKey:@"id"] intValue];
				item.name = [cate objectForKey:@"name"];
				//TRACE(@"cate: %d=%@", item.cid, item.name);
				[m_boardCategories addObject:item];
			}
		}
		
		success = ([m_boardCategories count] > 0);			
	}

	if (!success)
	{
		alertSimpleMessage(GetLocalizedString(@"api_fail"));
	}
	else
	{
		[theDelegate sleekSessionLoginPassed:self];
	}
}

- (void)onJobGetList:(NSDictionary*)dic isMore:(BOOL)isMoreFetch delegate:(id<SleekSessionDelegate>)theDelegate
{
	NSArray* thrs = [dic objectForKey:@"threads"];
	m_isCurPageLast = [[dic objectForKey:@"last"] boolValue];
	
	if (thrs != nil)
	{
		for (NSDictionary* thr in thrs)
		{
			ThreadListItem* item = [ThreadListItem new];
			item.tid = [[thr objectForKey:@"_id"] intValue];
			item.categoryId = [[thr objectForKey:@"cid"] intValue];
			item.hit = [[thr objectForKey:@"hit"] intValue];
			item.length = [[thr objectForKey:@"length"] intValue];
			item.categoryName = [[thr objectForKey:@"category"] objectForKey:@"name"];
			item.title = [thr objectForKey:@"title"];
			item.writer = [thr objectForKey:@"writer"];
			item.udateStr = [thr objectForKey:@"udateStr"];
			[item parseDate];
			
			item.udate = [[thr objectForKey:@"udate"] longLongValue];
			item.isUnreadNew = [self isNewerThanLastAccess:item.udate];

			if (isMoreFetch)
			{
				ThreadListItem* lastItem = [m_threads lastObject];
				if (lastItem.tid == item.tid)
				{
					NSTRACE(@"Last thread item duplicated");
					continue;
				}
			}
			
			[m_threads addObject:item];
		}
	}
	
	[self hideHud];
	m_onMoreLoading = NO;
	
	[theDelegate sleekSession:self selectedCategory:m_isCurPageLast];
}

- (void)onJobFetchThread:(NSDictionary*)dic delegate:(id<SleekSessionDelegate>)theDelegate
{	
	//TRACE(@"Got thread: %@", dic);
	Thread* ti = [Thread new];
	
	NSDictionary* dicThread = [dic objectForKey:@"thread"];
	ti.title = [dicThread objectForKey:@"title"];
	ti.tid = [[dicThread objectForKey:@"_id"] intValue];
	
	NSArray* posts = [dic objectForKey:@"posts"];
	if (posts != nil)
	{
		NSMutableArray* pis = [[NSMutableArray alloc] initWithCapacity:posts.count];
		
		for (NSDictionary* post in posts)
		{
			ThreadPost* pi = [ThreadPost new];
			pi.pid = [[post objectForKey:@"_id"] intValue];
			long long cdate = [[post objectForKey:@"cdate"] longLongValue];
			pi.isNewer = [self isNewerThanLastAccess:cdate];
			//pi.visible = [[post objectForKey:@"visible"] boolValue];
			//pi.editable = [[post objectForKey:@"editable"] boolValue];
			pi.writer = [post objectForKey:@"writer"];
			pi.text = [post objectForKey:@"text"];
			pi.cdateStr = [post objectForKey:@"cdateStr"];
			
			NSArray* files = [post objectForKey:@"files"];
			if (files != nil)
			{
				NSMutableArray* pfs  = [[NSMutableArray alloc] initWithCapacity:files.count];
				for (NSDictionary* file in files)
				{
					PostFile* pf = [PostFile new];
					pf.name = [file objectForKey:@"name"];
					pf.url = [file objectForKey:@"url"];
					[pfs addObject:pf];
				}
				pi.files = pfs;
			}
			
			[pis addObject:pi];
		}
		
		ti.posts = pis;
	}
	
	[theDelegate sleekSession:self gotThread:ti];
}

- (void)onJobPostThread:(NSDictionary*)dic delegate:(id<SleekSessionDelegate>)theDelegate
{
//	int pid = [[dic objectForKey:@"pid"] intValue];
	int tid = [[dic objectForKey:@"tid"] intValue];
//	NSTRACE(@"Thread posted pid=%d, tid=%d", pid, tid);
	
	[theDelegate sleekSession:self postedThreadId:tid];
}

- (void)httpQueryJob:(int)jobId didSucceedWithResult:(id)result forSpec:(HttpQuerySpec*)spec
{
	//NSTRACE(@"jobOK %d: %@", jobId, result);
	
	switch(jobId)
	{
	case JOBID_LOGIN:
		[self onJobLogin:(NSDictionary*)result delegate:(id<SleekSessionDelegate>)spec.userObj];
		break;
	case JOBID_HELLO:
		[self onJobHello:(NSDictionary*)result delegate:(id<SleekSessionDelegate>)spec.userObj];
		break;
	case JOBID_INITUSER:
		[self onJobInitUser:[(NSDictionary*)result objectForKey:@"user"] delegate:(id<SleekSessionDelegate>)spec.userObj];
		break;
	case JOBID_REFRESH_THREADS:
		[self onJobGetList:(NSDictionary*)result isMore:NO delegate:(id<SleekSessionDelegate>)spec.userObj];
		break;
	case JOBID_GETMORE_THREADS:
		[self onJobGetList:(NSDictionary*)result isMore:YES delegate:(id<SleekSessionDelegate>)spec.userObj];
		break;
	case JOBID_FETCH_THREAD:
		[self onJobFetchThread:(NSDictionary*)result delegate:(id<SleekSessionDelegate>)spec.userObj];
		break;
	case JOBID_POST_THREAD:
		[self onJobPostThread:(NSDictionary*)result delegate:(id<SleekSessionDelegate>)spec.userObj];
		break;
	}
}

- (BOOL)isNewerThanLastAccess:(long long)aTimeValue
{
	return (aTimeValue > m_lastAccessTime);
}

- (void)updateLastAccessTime:(long long)aTimeValue
{
	if (m_newLastAccessTime < aTimeValue)
	{
		m_newLastAccessTime = aTimeValue;
	}
}

- (BOOL) isLoggedIn
{
	return [m_boardCategories count] > 0;
}

- (void)doLogin:(id<SleekSessionDelegate>)theDelegate
{
	HttpQuerySpec* spec = [self getEmptySpec:theDelegate];
	spec.resultType = HQRT_JSON;
	spec.path = @"/api/sessions";
	spec.isPostMethod = YES;
	
	[spec addValue:m_password forKey:@"password"];
	[spec addValue:@"true" forKey:@"remember"];
	
	m_hud = [GetAppDelegate() createHUD];
	m_hud.dimBackground = YES;
	m_hud.labelText = GetLocalizedString(@"connecting");
	[m_hud show:YES];
	
	[GetHttpMan() request:JOBID_LOGIN forSpec:spec delegate:self];
}

- (BOOL)isMoreThreadLoadPending
{
	if (m_onMoreLoading)
	{
		double now = CACurrentMediaTime();
		if ((now - m_lastMoreLoadingTick) > 3)
		{
			// ignore if more than 3 seconds
			NSTRACE(@"MoreLoad pending over 3sec. ignore");
			m_onMoreLoading = NO;
			return NO;
		}
		
		NSTRACE(@"Yes is MoreLoad pending...");
		return YES;
	}
	
	return NO;
}

- (void)selectCategory:(int)cid delegate:(id<SleekSessionDelegate>)theDelegate
{
	if ([self isMoreThreadLoadPending])
		return;
		
	if (cid != m_lastRequestedCategoryId)
	{
		m_lastRequestedCategoryId = cid;
		
		if (cid == 0)
		{
			m_lastRequestedCategoryName = self.siteTitle;
		}
		else
		{
			for (BoardCategory* cate in m_boardCategories)
			{
				if (cate.cid == cid)
				{
					m_lastRequestedCategoryName = cate.name;
					break;
				}
			}
		}
	}
	
	HttpQuerySpec* spec = [self getEmptySpec:theDelegate];
	spec.resultType = HQRT_JSON;
	spec.path = @"/api/threads";
	
	m_curPage = 1;
	[spec addValue:[NSString stringWithFormat:@"%d", cid] forKey:@"c"];
	[spec addValue:[NSString stringWithFormat:@"%d", m_curPage] forKey:@"pg"];
	[spec addValue:[NSString stringWithFormat:@"%d", THREADLIST_PAGESIZE] forKey:@"ps"];
	
	m_hud = [GetAppDelegate() createHUD];
	m_hud.dimBackground = YES;
	m_hud.labelText = GetLocalizedString(@"loading");
	[m_hud show:YES];

	[m_threads removeAllObjects];
	
	[GetHttpMan() request:JOBID_REFRESH_THREADS forSpec:spec delegate:self];
}

- (void)getMoreThreads:(id<SleekSessionDelegate>)theDelegate
{
	if (m_threads.count == 0)
	{
		NSTRACE(@"Cur thread count is zero, ignore more load.");
		return;
	}
	
	if ([self isMoreThreadLoadPending])
		return;

	HttpQuerySpec* spec = [self getEmptySpec:theDelegate];
	spec.resultType = HQRT_JSON;
	spec.path = @"/api/threads";
	
	[spec addValue:[NSString stringWithFormat:@"%d", m_lastRequestedCategoryId] forKey:@"c"];
	[spec addValue:[NSString stringWithFormat:@"%d", ++m_curPage] forKey:@"pg"];
	[spec addValue:[NSString stringWithFormat:@"%d", THREADLIST_PAGESIZE] forKey:@"ps"];
	
	m_hud = [GetAppDelegate() createHUD];
	m_hud.dimBackground = YES;
	m_hud.labelText = GetLocalizedString(@"loading");
	[m_hud show:YES];

	m_onMoreLoading = YES;
	m_lastMoreLoadingTick = CACurrentMediaTime();

	[GetHttpMan() request:JOBID_GETMORE_THREADS forSpec:spec delegate:self];
}

- (void)getThread:(int)tid delegate:(id<SleekSessionDelegate>)theDelegate
{
	HttpQuerySpec* spec = [self getEmptySpec:theDelegate];
	spec.resultType = HQRT_JSON;
	spec.path = [NSString stringWithFormat:@"/api/threads/%d", tid];
	
	m_hud = [GetAppDelegate() createHUD];
	m_hud.dimBackground = YES;
	m_hud.labelText = GetLocalizedString(@"loading");
	[m_hud show:YES];
	
	[GetHttpMan() request:JOBID_FETCH_THREAD forSpec:spec delegate:self];
}

- (void)postThread:(ThreadWriteItem*)item delegate:(id<SleekSessionDelegate>)theDelegate
{
	HttpQuerySpec* spec = [self getEmptySpec:theDelegate];
	spec.resultType = HQRT_JSON;
	spec.isPostMethod = YES;
	
	if (item.replyThreadId == 0)
	{
		spec.path = @"/api/threads";
		[spec addValue:item.title forKey:@"title"];
		[spec addValue:[NSString stringWithFormat:@"%d", item.categoryId] forKey:@"cid"];
	}
	else
	{
		spec.path = [NSString stringWithFormat:@"/api/threads/%d", item.replyThreadId];
	}
	
	[spec addValue:self.nickname forKey:@"writer"];
	[spec addValue:item.text forKey:@"text"];
	
	m_hud = [GetAppDelegate() createHUD];
	m_hud.dimBackground = YES;
	m_hud.labelText = GetLocalizedString(@"posting");
	[m_hud show:YES];
	
	[GetHttpMan() request:JOBID_POST_THREAD forSpec:spec delegate:self];
}

- (void)hideHud
{
	[m_hud hide:YES];
	m_hud = nil;
}

@end
