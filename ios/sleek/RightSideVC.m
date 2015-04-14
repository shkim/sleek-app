//
//  RightSideVC.m
//  sleek
//
//  Created by shkim on 9/8/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import "RightSideVC.h"
#import "SleekSession.h"
#import "AppDelegate.h"
#import "LeftSideVC.h"
#import "MainListVC.h"
#import "ServerInfoVC.h"
#import "util.h"

#import "UIViewController+ECSlidingViewController.h"

@interface RightSideVC () <UIAlertViewDelegate, SleekSessionDelegate>
{
	UIAlertView* m_alertChangeServer;
	UIAlertView* m_alertAddServer;
	__weak NSString* m_keyToChangeSession;
}

@end

@implementation RightSideVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	if (GetAppDelegate().isIpad)
		self.cstrSideMargin.constant = 88;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onSessionListChanged
{
	[self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    view.tintColor = UIColorFromRGB(0x505050);

	UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
	[header.textLabel setTextColor:[UIColor grayColor]];
	header.textLabel.textAlignment = NSTextAlignmentCenter;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 1)
		return GetLocalizedString(@"sec_etc");
		
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 1)
		return 1;
		
	return [[GetAppDelegate() getSessionList] count] +1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SideListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ServerCell"];

	LeftSideVC* leftVC = (LeftSideVC*) self.slidingViewController.underLeftViewController;
	
	if (indexPath.section == 1)
	{
		cell.contentView.backgroundColor = leftVC.bgColorNonSel;
		cell.textLabel.text = GetLocalizedString(@"config");
		cell.textLabel.textColor = [UIColor lightGrayColor];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else// if (indexPath.section == 0)
	{
		NSArray* arr = [GetAppDelegate() getSessionList];
		if (indexPath.row < [arr count])
		{
			SessionListItem* sli = [arr objectAtIndex:indexPath.row];
			cell.textLabel.text = sli.name;
		
			if (sli.isCurrent)
			{
				cell.backgroundColor = leftVC.bgColorSelected;
				cell.textLabel.textColor = [UIColor whiteColor];
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			}
			else
			{
				cell.backgroundColor = leftVC.bgColorNonSel;
				cell.textLabel.textColor = [UIColor lightGrayColor];
				cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
			}
		}
		else
		{
			cell.textLabel.text = GetLocalizedString(@"add_svr");
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.backgroundColor = leftVC.bgColorNonSel;
			cell.textLabel.textColor = [UIColor lightGrayColor];
		}
	}

	return cell;
}

- (void)showServerInfoWith:(SessionListItem*)sli
{
	ServerInfoVC* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ServerInfo"];
	vc.sli = sli;

	[self.slidingViewController resetTopViewAnimated:NO onComplete:^{
		UINavigationController* navVC = (UINavigationController*) self.slidingViewController.topViewController;
		[navVC pushViewController:vc animated:YES];
	}];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section != 0)
		return;
		
	NSArray* arr = [GetAppDelegate() getSessionList];
	if (indexPath.row < [arr count])
	{
		[self showServerInfoWith:[arr objectAtIndex:indexPath.row]];
	}
		
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	if (indexPath.section == 1)
	{
		// config clicked
		[MainListVC resetTopAndGoSettings:self.slidingViewController];
		return;
	}

	NSArray* arr = [GetAppDelegate() getSessionList];
	if (indexPath.row < [arr count])
	{
		SessionListItem* sli = [arr objectAtIndex:indexPath.row];
		if (sli.isCurrent)
		{
			[self tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
		}
		else
		{
			// change server
			m_keyToChangeSession = sli.key;
			m_alertChangeServer = [[UIAlertView alloc] initWithTitle:nil
				message:GetLocalizedString(@"q_chg_svr")
				delegate:self
				cancelButtonTitle:GetLocalizedString(@"no")
				otherButtonTitles:GetLocalizedString(@"yes"), nil];
			[m_alertChangeServer show];
		}
	}
	else
	{
		// new server add clicked
		m_alertAddServer = [[UIAlertView alloc] initWithTitle:nil
			message:GetLocalizedString(@"q_add_svr")
			delegate:self
			cancelButtonTitle:GetLocalizedString(@"no")
			otherButtonTitles:GetLocalizedString(@"yes"), nil];
		[m_alertAddServer show];
	}
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (alertView == m_alertChangeServer)
	{
		m_alertChangeServer = nil;
		
		if (buttonIndex == 1)
		{
			NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
			NSDictionary* dic = [ud dictionaryForKey:m_keyToChangeSession];
			if (dic != nil)
			{
				SleekSession* chgSess = [[SleekSession alloc] initWithDictionary:dic];
				[chgSess doLogin:self];
			}
		}
		
		m_keyToChangeSession = nil;
	}
	else if (alertView == m_alertAddServer)
	{
		m_alertAddServer = nil;
		
		if (buttonIndex == 1)
		{
			[self showServerInfoWith:nil];
		}
	}
}

- (void)onSessionChanged
{
	[self.tableView reloadData];
}

- (void)sleekSessionLoginPassed:(SleekSession*)session
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:session.saveKey forKey:PREF_KEY_LASTSESSION];
	[ud synchronize];
	
	[GetAppDelegate() setCurrentSession:session];
	[self.slidingViewController resetTopViewAnimated:YES];
}

@end
