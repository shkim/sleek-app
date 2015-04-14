//
//  LeftSideVC.h
//  sleek
//
//  Created by shkim on 9/4/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SideListCell : UITableViewCell
@end

@interface LeftSideVC : UIViewController

- (void)onSessionChanged;

@property (nonatomic, weak) IBOutlet UITableView* tableView;
@property (nonatomic, weak) IBOutlet UISearchBar* searchBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cstrSideMargin;

//@property (nonatomic, weak) NSString* selectedCategoryName;

@property (nonatomic, readonly, getter = getColorNonSel) UIColor* bgColorNonSel;
@property (nonatomic, readonly, getter = getColorSelected) UIColor* bgColorSelected;

@end
