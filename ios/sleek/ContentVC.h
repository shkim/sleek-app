//
//  ContentVC.h
//  sleek
//
//  Created by shkim on 9/4/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WriteVC.h"

@class Thread;

@interface ContentVC : UIViewController

@property (nonatomic, strong) Thread* sleekThread;
@property (nonatomic, weak) id<SleekThreadWriteDelegate> writeDelegate;

@end
