//
//  RightSideVC.h
//  sleek
//
//  Created by shkim on 9/8/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RightSideVC : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cstrSideMargin;

- (void)onSessionChanged;

@end
