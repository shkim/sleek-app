//
//  SleekSession.h
//  SleekClient
//
//  Created by shkim on 5/16/13.
//  Copyright (c) 2013 shkim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpMan.h"

@class SleekSession;

@interface BoardCategory : NSObject
@property (nonatomic, assign) int cid;
@property (nonatomic, strong) NSString* name;
@end

@interface PostFile : NSObject
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* url;
@end

@interface ThreadPost : NSObject
@property (nonatomic, assign) int pid;
@property (nonatomic, assign) BOOL isNewer;
//@property (nonatomic, assign) BOOL visible;
//@property (nonatomic, assign) BOOL editable;
@property (nonatomic, strong) NSString* writer;
@property (nonatomic, strong) NSString* text;
@property (nonatomic, strong) NSString* cdateStr;
@property (nonatomic, strong) NSArray* files;
@end

@interface Thread : NSObject
@property (nonatomic, assign) int tid;
@property (nonatomic, assign) int categoryId;
@property (nonatomic, strong) NSString* categoryName;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* writer;
@property (nonatomic, strong) NSString* udateStr;
@property (nonatomic, strong) NSArray* posts;
@end

@interface ThreadListItem : NSObject
@property (nonatomic, assign) int tid;
@property (nonatomic, assign) int categoryId;
@property (nonatomic, assign) int hit;
@property (nonatomic, assign) int length;
@property (nonatomic, strong) NSString* categoryName;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* writer;
@property (nonatomic, strong) NSString* udateStr;
@property (nonatomic, assign) int dateYear;
@property (nonatomic, assign) int dateMonth;
@property (nonatomic, assign) int dateDay;
@property (nonatomic, assign) int dateHour;
@property (nonatomic, assign) int dateMinute;
@property (nonatomic, assign) int timestamp;
@property (nonatomic, assign) long long udate;
@property (nonatomic, assign) BOOL isUnreadNew;
- (void)parseDate;
@end

@interface ThreadWriteItem : NSObject
@property (nonatomic, assign) int categoryId;
@property (nonatomic, assign) int replyThreadId;
@property (nonatomic, strong) NSString* title;	// nil when reply
//@property (nonatomic, strong) NSString* writer;
@property (nonatomic, strong) NSString* text;
@end

@protocol SleekSessionDelegate <NSObject>

@optional
- (void)sleekSessionLoginPassed:(SleekSession*)session;
- (void)sleekSession:(SleekSession*)session selectedCategory:(BOOL)isLast;
- (void)sleekSession:(SleekSession*)session gotThread:(Thread*)ti;
- (void)sleekSession:(SleekSession*)session postedThreadId:(int)tid;

@end


@interface SleekSession : NSObject <HttpQueryDelegate>

- (id)initWithAddress:(NSString*)address andPassword:(NSString*)passwd;
- (id)initWithDictionary:(NSDictionary*)dic;
- (void)saveSettings;

- (BOOL)isNewerThanLastAccess:(long long)aTimeValue;
- (void)updateLastAccessTime:(long long)aTimeValue;
- (BOOL)isLoggedIn;

- (void)doLogin:(id<SleekSessionDelegate>)theDelegate;
- (void)selectCategory:(int)cid delegate:(id<SleekSessionDelegate>)theDelegate;
- (void)getThread:(int)tid delegate:(id<SleekSessionDelegate>)theDelegate;
- (void)getMoreThreads:(id<SleekSessionDelegate>)theDelegate;
- (void)postThread:(ThreadWriteItem*)item delegate:(id<SleekSessionDelegate>)theDelegate;

- (void)hideHud;
- (NSDictionary*)makeDictionaryForSave;

@property (nonatomic, strong) NSString* siteTitle;
@property (nonatomic, strong) NSString* nickname;
@property (nonatomic, readonly) NSArray* boardCategories;
@property (nonatomic, readonly) NSArray* threads;
@property (nonatomic, readonly) int categoryId;
@property (nonatomic, readonly) NSString* categoryName;
@property (nonatomic, readonly) NSString* saveKey;	// hostname with :port
@property (nonatomic, readonly) BOOL isLastPage;

@end
