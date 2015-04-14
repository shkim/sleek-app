//
//  LeftSideVC.m
//  sleek
//
//  Created by shkim on 9/4/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import "LeftSideVC.h"
#import "MainListVC.h"
#import "AppDelegate.h"
#import "SleekSession.h"
#import "util.h"

#import "UIViewController+ECSlidingViewController.h"

@implementation SideListCell

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = UIColorFromRGB(0x444444);
    bgColorView.layer.masksToBounds = YES;
    self.selectedBackgroundView = bgColorView;
}

@end

@interface LeftSideVC () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
{
	UIColor* m_colorNonSel;
	UIColor* m_colorSelected;
	NSInteger m_selectedCategoryIndex;
}

@end

@implementation LeftSideVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	m_colorNonSel = [UIColor darkGrayColor];
	m_colorSelected = UIColorFromRGB(0x444444);
	
	UITextField *searchField = [self.searchBar valueForKey:@"_searchField"];
	searchField.textColor = [UIColor lightGrayColor];
	
	if (GetAppDelegate().isIpad)
		self.cstrSideMargin.constant = 88;
}

- (UIColor*)getColorNonSel
{
	return m_colorNonSel;
}

- (UIColor*)getColorSelected
{
	return m_colorSelected;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (void)onSessionChanged
{
	SleekSession* session = GetAppDelegate().currentSession;
	
	int cid = session.categoryId;
	if (cid == 0)
	{
		m_selectedCategoryIndex = 0;
	}
	else
	{
		int idx = 0;
		for (BoardCategory* cate in session.boardCategories)
		{
			++idx;
			if (cate.cid == cid)
			{
				m_selectedCategoryIndex = idx;
			}
		}
	}
	
	[self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Background color
    view.tintColor = UIColorFromRGB(0x505050);

	// Text Color
	UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
	[header.textLabel setTextColor:[UIColor grayColor]];
//	header.textLabel.font = [UIFont systemFontOfSize:11];

    // Another way to set the background color
    // Note: does not preserve gradient effect of original header
    // header.contentView.backgroundColor = [UIColor blackColor];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0)
		return GetLocalizedString(@"sec_nickname");
		
	return GetLocalizedString(@"sec_category");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 1;
		
	return 1 + [GetAppDelegate().currentSession.boardCategories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	SideListCell* cell = [tableView dequeueReusableCellWithIdentifier:@"CategoryCell"];
//	cell.accessoryType = UITableViewCellAccessoryNone;
	
	SleekSession* session = GetAppDelegate().currentSession;
	
	if (indexPath.section == 0)
	{
		// nickname
		cell.contentView.backgroundColor = m_colorNonSel;
		cell.textLabel.text = session.nickname;
		cell.textLabel.textColor = [UIColor whiteColor];
		cell.accessoryType = UITableViewCellAccessoryNone;//UITableViewCellAccessoryDetailButton;
	}
	else
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		if (indexPath.row == 0)
		{
			cell.textLabel.text = @"All";//GetLocalizedString(@"all_cate_name");
		}
		else
		{
			BoardCategory* cate = [session.boardCategories objectAtIndex:(indexPath.row -1)];
			cell.textLabel.text = cate.name;
		}
		
		if (indexPath.row == m_selectedCategoryIndex)
		{
			cell.contentView.backgroundColor = m_colorSelected;
			cell.textLabel.textColor = [UIColor whiteColor];
			cell.userInteractionEnabled = NO;
		}
		else
		{
			cell.contentView.backgroundColor = m_colorNonSel;
			cell.textLabel.textColor = [UIColor lightGrayColor];
			cell.userInteractionEnabled = YES;
		}
	}
	
	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == 0)
	{
		// nickname clicked
		[MainListVC resetTopAndGoSettings:self.slidingViewController];
		return;
	}

	
	SleekSession* session = GetAppDelegate().currentSession;

	int reqCid;
	if (indexPath.row == 0)
	{
		reqCid = 0;
	}
	else
	{
		BoardCategory* cate = [session.boardCategories objectAtIndex:(indexPath.row -1)];
		reqCid = cate.cid;
	}

	[session selectCategory:reqCid delegate:[MainListVC getMainListVC:self.slidingViewController]];
	
	m_selectedCategoryIndex = indexPath.row;
	[self.tableView reloadData];
	
	[self.slidingViewController resetTopViewAnimated:YES];
}

- (void)closeSearchBar
{
	self.searchBar.showsCancelButton = NO;
	self.tableView.userInteractionEnabled = YES;
	self.tableView.alpha = 1;
	
	[self.searchBar endEditing:YES];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
	// begin search-bar edit
	self.searchBar.showsCancelButton = YES;
	self.tableView.userInteractionEnabled = NO;
	self.tableView.alpha = 0.3;
	
	return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
	[self closeSearchBar];
	return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	alertSimpleMessage(@"TODO: search");
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
	[self closeSearchBar];
	NSTRACE(@"cancel search?");
}

@end
