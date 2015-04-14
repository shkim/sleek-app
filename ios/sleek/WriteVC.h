//
//  WriteVC.h
//  sleek
//
//  Created by shkim on 9/11/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SleekThreadWriteDelegate <NSObject>
- (void)sleekPostedThreadId:(int)tid;
@end

@interface WriteVC : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, assign) int replyThreadId;
@property (nonatomic, strong) NSString* replySubject;
@property (nonatomic, assign) int boardCategoryId;
@property (nonatomic, weak) id<SleekThreadWriteDelegate> writeDelegate;

@property (nonatomic, weak) IBOutlet UIScrollView* scrView;
@property (nonatomic, weak) IBOutlet UIView* contentView;
@property (nonatomic, weak) IBOutlet UILabel* lbNick;
@property (weak, nonatomic) IBOutlet UILabel *lbSubject;
@property (nonatomic, weak) IBOutlet UIButton* btnCategory;
@property (nonatomic, weak) IBOutlet UITextField* tfSubject;
@property (nonatomic, weak) IBOutlet UITextView* tvBody;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cstrContentWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cstrContentHeight;
@property (weak, nonatomic) IBOutlet UIScrollView *scrPics;

- (IBAction)onSelectCategory;
- (IBAction)onAddPic;
- (IBAction)onTouchForm:(UITapGestureRecognizer *)sender;

@end
