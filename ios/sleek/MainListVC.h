//
//  MainListVC.h
//  sleek
//
//  Created by shkim on 9/4/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SleekSession.h"
#import "OSLabel.h"

@class ECSlidingViewController;

@interface NormalListCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lbSubject;
@property (weak, nonatomic) IBOutlet UILabel *lbWriter;
@property (weak, nonatomic) IBOutlet UILabel *lbViewCount;
@property (weak, nonatomic) IBOutlet UILabel *lbUpdateTime;
@property (weak, nonatomic) IBOutlet OSLabel *lbCategory;
@property (weak, nonatomic) IBOutlet OSLabel *lbReplyCount;

- (void)setup:(ThreadListItem*)info;

@end

@interface MainListVC : UITableViewController <UITableViewDataSource, UITableViewDelegate, SleekSessionDelegate>

- (void)onSessionChanged:(SleekSession*)session;

+ (MainListVC*)getMainListVC:(ECSlidingViewController*)slidingVC;
+ (void)resetTopAndGoSettings:(ECSlidingViewController*)slidingVC;

@end
