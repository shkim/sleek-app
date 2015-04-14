//
//  SettingsVC.m
//  sleek
//
//  Created by shkim on 9/13/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import "SettingsVC.h"
#import "AppDelegate.h"
#import "ServerInfoVC.h"
#import "util.h"

#import "UIViewController+ECSlidingViewController.h"

@interface SettingsVC ()
{
	NSString* m_origFontSizeLabel;
	NSInteger m_nFontSize;	// 1,2,3
	BOOL m_orderNewIsUp;
}

@end

@implementation SettingsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
 
	self.title = GetLocalizedString(@"config");
	
	m_origFontSizeLabel = self.lbFontSize.text;

	m_nFontSize = GetAppDelegate().settings.fontSize;
	if (m_nFontSize < CONTENT_FONTSIZE_MIN || m_nFontSize > CONTENT_FONTSIZE_MAX)
		m_nFontSize = (CONTENT_FONTSIZE_MIN + CONTENT_FONTSIZE_MAX) /2;
	[self onFontSizeEnd:nil];

	m_orderNewIsUp = GetAppDelegate().settings.orderNewIsUp;
	[self setPostOrderText];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.navigationController.view removeGestureRecognizer:self.slidingViewController.panGesture];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	
	int changed = 0;
	if (m_nFontSize != GetAppDelegate().settings.fontSize)
	{
		GetAppDelegate().settings.fontSize = m_nFontSize;
		[ud setInteger:m_nFontSize forKey:PREF_KEY_FONTSIZE];
		++changed;
	}
	
	if (m_orderNewIsUp != GetAppDelegate().settings.orderNewIsUp)
	{
		GetAppDelegate().settings.orderNewIsUp = m_orderNewIsUp;
		[ud setBool:m_orderNewIsUp forKey:PREF_KEY_NEWISUP];
		++changed;
	}
	
	if (changed)
	{
		[ud synchronize];
	}
}

static NSString* aFontSizeNames[] = { @"fs_min", @"fs_mid", @"fs_max" };

- (IBAction)onFontSizeChange:(UISlider *)sender
{
	int nFontSize = (int)floor(sender.value + 0.5f);
	
	if (m_nFontSize != nFontSize || self.lbFontSize.text == m_origFontSizeLabel)
	{
		m_nFontSize = nFontSize;
		self.lbFontSize.text = GetLocalizedString(aFontSizeNames[nFontSize -1]);
	}
}

- (IBAction)onFontSizeEnd:(UISlider *)sender
{
	self.lbFontSize.text = m_origFontSizeLabel;
	self.sliFontSize.value = m_nFontSize;
}

- (void)setPostOrderText
{
	self.lbPostOrder.text = GetLocalizedString(m_orderNewIsUp ? @"ord_newup" : @"ord_newdn");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	if (indexPath.section == 0)
	{
		if (indexPath.row == 0)
		{
			self.swNotifyNew.on = !self.swNotifyNew.on;
		}
		else
		{
			self.swNotifyRe.on = !self.swNotifyRe.on;
		}
	}
	else
	{
		if (indexPath.row == 1)
		{
			m_orderNewIsUp = !m_orderNewIsUp;
			[self setPostOrderText];
		}
	}
}

@end
