//
//  SettingsVC.h
//  sleek
//
//  Created by shkim on 9/13/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CONTENT_FONTSIZE_MIN 	1
#define CONTENT_FONTSIZE_MAX	3

@interface SettingsVC : UITableViewController

@property (weak, nonatomic) IBOutlet UISwitch *swNotifyNew;
@property (weak, nonatomic) IBOutlet UISwitch *swNotifyRe;
@property (weak, nonatomic) IBOutlet UILabel *lbFontSize;
@property (weak, nonatomic) IBOutlet UISlider *sliFontSize;
@property (weak, nonatomic) IBOutlet UILabel *lbPostOrder;

- (IBAction)onFontSizeChange:(UISlider *)sender;
- (IBAction)onFontSizeEnd:(UISlider *)sender;

@end
