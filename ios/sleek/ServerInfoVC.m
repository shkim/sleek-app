//
//  ServerInfoVC.m
//  sleek
//
//  Created by shkim on 9/4/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import "ServerInfoVC.h"
#import "AppDelegate.h"
#import "LeftSideVC.h"
#import "RightSideVC.h"
#import "util.h"

#import "UIViewController+ECSlidingViewController.h"

NSString* const PREF_KEY_SITENAME = @"kName";
NSString* const PREF_KEY_ADDRESS = @"kHost";
NSString* const PREF_KEY_PASSWORD = @"kPasswd";
NSString* const PREF_KEY_NICKNAME = @"kNick";
NSString* const PREF_KEY_LASTACESSTIME = @"kTime";
NSString* const PREF_KEY_LASTSESSION = @"kLastSess";
NSString* const PREF_KEY_ALLSESSIONS = @"kSessList";
NSString* const PREF_KEY_FONTSIZE = @"kFontSize";
NSString* const PREF_KEY_NEWISUP = @"kNewIsUp";

@interface ServerInfoVC () <UIAlertViewDelegate>
{
	UIAlertView* m_alertDeleteSvr;
}

@end

@implementation ServerInfoVC

void disableTextField(UITextField* tf)
{
	tf.enabled = NO;
	tf.backgroundColor = [UIColor lightTextColor];
	tf.textColor = [UIColor grayColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.title = GetLocalizedString(self.sli == nil ? @"add_svr" : @"edit_svr");
	
	self.scrView.contentSize = self.contentView.frame.size;
	
	if (self.sli != nil)
	{
		NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
		NSDictionary* dic = [ud dictionaryForKey:self.sli.key];
		self.tfAddress.text = [dic objectForKey:PREF_KEY_ADDRESS];
		self.tfPassword.text = [dic objectForKey:PREF_KEY_PASSWORD];
		self.tfNickname.text = [dic objectForKey:PREF_KEY_NICKNAME];

		disableTextField(self.tfAddress);
		disableTextField(self.tfPassword);
		
		[self.btnOK setTitle:GetLocalizedString(@"update") forState:UIControlStateNormal];
		
		if (!self.sli.isCurrent)
		{
			self.btnDelete.hidden = NO;
		}
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
    // register for keyboard notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(keyboardWasShown:)
		name:UIKeyboardDidShowNotification
		object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
		selector:@selector(keyboardWillHide)
		name:UIKeyboardWillHideNotification
		object:nil];
		
	[self performSelector:@selector(resizeContent) withObject:nil afterDelay:0.001];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.navigationController.view removeGestureRecognizer:self.slidingViewController.panGesture];
	
	if (0)//self.isFirstServer)
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"처음 사용자시군요?"
			message:@"슬릭 서버 정보를 입력해주세요.\n한 번만 입력하면 됩니다."
			delegate:nil
			cancelButtonTitle:GetLocalizedString(@"ok") otherButtonTitles:nil];
		[alert show];
	}
	
#ifdef DEBUG
	if (self.isFirstServer) {
	self.tfAddress.text = @"urizip.ogp.kr:8009";
	self.tfPassword.text = @"1";
	//self.tfAddress.text = @"sleek.the-oz.net:80";
	//self.tfPassword.text = @"gh";
	self.tfNickname.text = @"shkim";
	}
#endif
}

- (void)keyboardWasShown:(NSNotification *)notification
{
	CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
	
	CGFloat kbdHeight;
	if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
	{
		kbdHeight = keyboardSize.width;
	}
	else
	{
		kbdHeight = keyboardSize.height;
	}

	UIEdgeInsets inset = self.scrView.contentInset;
	inset.bottom = kbdHeight;
	self.scrView.contentInset = inset;
}

-(void)keyboardWillHide
{
	UIEdgeInsets inset = self.scrView.contentInset;
	inset.bottom = 0;
	self.scrView.contentInset = inset;

	// scroll to top
	CGPoint ptOffset;
	ptOffset.x = 0;
	ptOffset.y = -self.scrView.contentInset.top;
	[self.scrView setContentOffset:ptOffset animated:YES];
}

- (void)resizeContent
{
	self.cstrContentWidth.constant = self.scrView.frame.size.width;
		
	//CGFloat height = self.scrView.frame.size.height - self.scrView.contentInset.top;
	//self.cstrContentHeight.constant = height;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.view endEditing:YES];
	[self resizeContent];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	[self.scrView scrollRectToVisible:textField.frame animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == self.tfAddress)
	{
		[self.tfPassword becomeFirstResponder];
	}
	else if (textField == self.tfPassword)
	{
		[self.tfNickname becomeFirstResponder];
	}
	else if (textField == self.tfNickname)
	{
		[textField resignFirstResponder];
	}
	else return NO;

	return YES;
}

NSString* trimString(NSString* orig)
{
	NSString* ret = [orig stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	return ([ret length] == 0) ? nil : ret;
}

- (IBAction)clickOK:(id)sender
{
	NSString* address = trimString([self.tfAddress.text lowercaseString]);
	if (address == nil)
	{
		alertSimpleMessage(GetLocalizedString(@"a_input_addr"));
		[self.tfAddress becomeFirstResponder];
		return;
	}
	
	NSString* passwd = trimString(self.tfPassword.text);		
	if (passwd == nil)
	{
		alertSimpleMessage(GetLocalizedString(@"a_input_pass"));
		[self.tfPassword becomeFirstResponder];
		return;
	}
	
	NSString* nick = trimString(self.tfNickname.text);
	if (nick == nil)
	{
		alertSimpleMessage(GetLocalizedString(@"a_input_nick"));
		[self.tfNickname becomeFirstResponder];
		return;
	}
	
	[self.view endEditing:YES];
	
	if (self.sli != nil)
	{
		NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
		NSDictionary* dic = [ud dictionaryForKey:self.sli.key];
		NSString* oldNick = [dic objectForKey:PREF_KEY_NICKNAME];

		if (oldNick != nil && ![oldNick isEqualToString:nick])
		{
			NSMutableDictionary* mdic = [[NSMutableDictionary alloc] initWithDictionary:dic];
			[mdic setObject:nick forKey:PREF_KEY_NICKNAME];
	
			[ud setObject:mdic forKey:self.sli.key];
			[ud synchronize];
			
			if (self.sli.isCurrent)
			{
				GetAppDelegate().currentSession.nickname = nick;
				
				LeftSideVC* leftVC = (LeftSideVC*) self.slidingViewController.underLeftViewController;
				[leftVC onSessionChanged];
			}
		}
		
		[self.navigationController popViewControllerAnimated:YES];
	}
	else
	{
		SleekSession* sess = [[SleekSession alloc] initWithAddress:address andPassword:passwd];
	
		// check if address conflicts with the existing server
		{
			NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
			if ([ud dictionaryForKey:sess.saveKey])
			{
				alertSimpleMessage(GetLocalizedString(@"a_conflict_addr"));
				return;
			}
		}
		
		sess.nickname = nick;
		[sess doLogin:self];
	}
}

- (IBAction)clickRemove:(id)sender
{
	m_alertDeleteSvr = [[UIAlertView alloc] initWithTitle:GetLocalizedString(@"q_del_svr")
		message:nil delegate:self
		cancelButtonTitle:GetLocalizedString(@"no")
		otherButtonTitles:GetLocalizedString(@"yes"), nil];
	[m_alertDeleteSvr show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (alertView == m_alertDeleteSvr)
	{
		m_alertDeleteSvr = nil;
		if (buttonIndex == 1)
		{
			NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

			NSArray* arrSess = [ud arrayForKey:PREF_KEY_ALLSESSIONS];
			NSMutableArray* arrNewSess = [arrSess mutableCopy];
			[arrNewSess removeObject:self.sli.key];
			[ud setObject:arrNewSess forKey:PREF_KEY_ALLSESSIONS];

			[ud removeObjectForKey:self.sli.key];
			[ud synchronize];
			
			[GetAppDelegate() updateSessionList];
		
			RightSideVC* rightVC = (RightSideVC*) self.slidingViewController.underRightViewController;
			[rightVC onSessionChanged];
			
			[self.navigationController popViewControllerAnimated:YES];
		}
	}
}

- (void)sleekSessionLoginPassed:(SleekSession *)session
{
	// save server info
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

	NSArray* arrSess = [ud arrayForKey:PREF_KEY_ALLSESSIONS];
	if (arrSess != nil)
	{
		if (NSNotFound == [arrSess indexOfObject:session.saveKey])
		{
			NSMutableArray* arrNewSess = [arrSess mutableCopy];
			[arrNewSess addObject:session.saveKey];
			[ud setObject:arrNewSess forKey:PREF_KEY_ALLSESSIONS];
		}
	}
	else
	{
		NSMutableArray* arrNewSess = [[NSMutableArray alloc] initWithCapacity:1];
		[arrNewSess addObject:session.saveKey];
		[ud setObject:arrNewSess forKey:PREF_KEY_ALLSESSIONS];
	}
	
	NSDictionary* dic = [session makeDictionaryForSave];
	[ud setObject:dic forKey:session.saveKey];
	[ud setObject:session.saveKey forKey:PREF_KEY_LASTSESSION];
	[ud synchronize];
	
	if (self.isFirstServer)
	{
		[GetAppDelegate() dismissServerInfoAndShowMainList:self];
	}
	else
	{
		[self.navigationController popViewControllerAnimated:YES];
	}
	
	[GetAppDelegate() updateSessionList];
	[GetAppDelegate() setCurrentSession:session];
}

@end
