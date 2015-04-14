//
//  AppDelegate.h
//  sleek
//
//  Created by shkim on 9/2/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HttpMan;
@class MBProgressHUD;
@class SleekSession;
@class ThreadListVC;
@class ServerInfoVC;

@interface SessionListItem : NSObject
@property (nonatomic, strong) NSString* key;	// host address
@property (nonatomic, strong) NSString* name;	// site name
@property (nonatomic, assign) BOOL isCurrent;
@end

@interface GlobalSettings : NSObject
@property (nonatomic, assign) NSInteger fontSize;	// 0(min),1,2(max)
@property (nonatomic, assign) BOOL orderNewIsUp;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong, setter = setCurrentSession:) SleekSession* currentSession;
@property (nonatomic, strong) GlobalSettings* settings;
@property (nonatomic, readonly) BOOL isIpad;

- (HttpMan*)getHttpManager;

- (void)dismissServerInfoAndShowMainList:(ServerInfoVC*)vc;
- (void)updateSessionList;
- (NSArray*)getSessionList;

- (MBProgressHUD*)createHUD;
- (MBProgressHUD*)createToast;

@end
