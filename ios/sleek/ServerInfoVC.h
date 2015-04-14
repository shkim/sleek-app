//
//  ServerInfoVC.h
//  sleek
//
//  Created by shkim on 9/4/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SleekSession.h"

extern NSString* const PREF_KEY_SITENAME;
extern NSString* const PREF_KEY_ADDRESS;
extern NSString* const PREF_KEY_PASSWORD;
extern NSString* const PREF_KEY_NICKNAME;
extern NSString* const PREF_KEY_LASTACESSTIME;
extern NSString* const PREF_KEY_LASTSESSION;
extern NSString* const PREF_KEY_ALLSESSIONS;

extern NSString* const PREF_KEY_FONTSIZE;
extern NSString* const PREF_KEY_NEWISUP;

@class SessionListItem;

@interface ServerInfoVC : UIViewController <SleekSessionDelegate>

@property (nonatomic, assign) BOOL isFirstServer;
@property (nonatomic, weak) SessionListItem* sli;

@property (nonatomic, weak) IBOutlet UIScrollView* scrView;
@property (nonatomic, weak) IBOutlet UIView *contentView;

@property (nonatomic, weak) IBOutlet UITextField* tfAddress;
@property (nonatomic, weak) IBOutlet UITextField* tfPassword;
@property (nonatomic, weak) IBOutlet UITextField* tfNickname;
@property (weak, nonatomic) IBOutlet UIButton *btnOK;
@property (weak, nonatomic) IBOutlet UIButton *btnDelete;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cstrContentWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cstrContentHeight;

- (IBAction)clickOK:(id)sender;
- (IBAction)clickRemove:(id)sender;

@end
