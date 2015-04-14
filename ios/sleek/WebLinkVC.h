//
//  WebLinkVC.h
//  SleekClient
//
//  Created by shkim on 5/27/13.
//  Copyright (c) 2013 shkim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebLinkVC : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) NSString* linkUrl;

@end
