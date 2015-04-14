//
//  WriteVC.m
//  sleek
//
//  Created by shkim on 9/11/14.
//  Copyright (c) 2014 shkim. All rights reserved.
//

#import "WriteVC.h"
#import "AppDelegate.h"
#import "SleekSession.h"
#import "util.h"

#import "UIViewController+ECSlidingViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface WriteVC () <SleekSessionDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate,
	UITableViewDataSource, UITableViewDelegate, UIPopoverControllerDelegate>
{
	UIAlertView* m_alertCancel;
	UIAlertView* m_alertSave;
	UIActionSheet* m_sheetPicker;
	UIPopoverController* m_popoverPicker;
	UIImagePickerController* m_photoPicker;
	__weak NSArray* m_categories;
	ThreadWriteItem* m_writeItem;
}

@end

@implementation WriteVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
		target:self action:@selector(onCancel)];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemDone
		target:self action:@selector(onDone)];
		
	self.scrView.contentSize = self.contentView.frame.size;
	
	if (self.replyThreadId == 0)
	{
		self.title = GetLocalizedString(@"write_new");
	}
	else
	{
		self.title = GetLocalizedString(@"write_reply");
		self.lbSubject.text = @"Re:";
		self.tfSubject.text = self.replySubject;
		self.tfSubject.enabled = NO;
		self.tfSubject.backgroundColor = [UIColor lightTextColor];
		self.tfSubject.textColor = [UIColor grayColor];
		self.btnCategory.hidden = YES;
	}
	
	SleekSession* sess = GetAppDelegate().currentSession;
	self.lbNick.text = sess.nickname;
	
	m_categories = sess.boardCategories;
	if (self.boardCategoryId == 0)
	{
		BoardCategory* cate = [m_categories objectAtIndex:0];
		[self setCategory:cate];
	}
	else
	{
		for (BoardCategory* cate in m_categories)
		{
			if (cate.cid == self.boardCategoryId)
			{
				[self setCategory:cate];
				break;
			}
		}
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.navigationController.view removeGestureRecognizer:self.slidingViewController.panGesture];
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
	//[self performSelector:@selector(resizeContent)];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)resizeContent
{	
	self.cstrContentWidth.constant = self.scrView.frame.size.width;
	self.cstrContentHeight.constant = self.scrView.frame.size.height - self.scrView.contentInset.top;
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
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self resizeContent];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == self.tfSubject)
	{
		[self.tvBody becomeFirstResponder];
		return NO;
	}
	
	return YES;
}

- (IBAction)onTouchForm:(UITapGestureRecognizer *)sender
{
	if (self.scrView.contentInset.bottom > 0)
	{
		[self.view endEditing:YES];
	}
}

- (void)onCancel
{
	[self.view endEditing:YES];
	
	NSString* title = (self.replyThreadId == 0) ? trimString(self.tfSubject.text) : nil;
	NSString* body = trimString(self.tvBody.text);
	if (title == nil && body == nil)
	{
		[self.navigationController popViewControllerAnimated:YES];
		return;
	}
	
	m_alertCancel = [[UIAlertView alloc]
		initWithTitle:GetLocalizedString(@"q_cancel_write")
		message:nil
		delegate:self
		cancelButtonTitle:GetLocalizedString(@"no")
		otherButtonTitles:GetLocalizedString(@"yes"), nil];
	[m_alertCancel show];
}

- (void)onDone
{
	if (![self checkSubmit])
		return;
	
	[self.view endEditing:YES];
	
	m_alertSave = [[UIAlertView alloc]
		initWithTitle:GetLocalizedString(@"q_confirm_write")
		message:nil
		delegate:self
		cancelButtonTitle:GetLocalizedString(@"no")
		otherButtonTitles:GetLocalizedString(@"yes"), nil];
	[m_alertSave show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (alertView == m_alertCancel)
	{
		m_alertCancel = nil;
		
		if (buttonIndex == 1)
		{
			[self.navigationController popViewControllerAnimated:YES];
		}
	}
	else if (alertView == m_alertSave)
	{
		m_alertSave = nil;
		
		if (buttonIndex == 1)
		{
			[self postSleekThread];
		}
	}
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return m_categories.count;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	BoardCategory* cate = [m_categories objectAtIndex:row];
    return cate.name;
}

- (void)setCategory:(BoardCategory*)cate
{
	[self.btnCategory setTitle:cate.name forState:UIControlStateNormal];
	self.boardCategoryId = cate.cid;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	BoardCategory* cate = [m_categories objectAtIndex:row];
	[self setCategory:cate];
}

- (void)showCategoriesWithSheet
{
	UIToolbar* tbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
	tbar.barStyle = UIBarStyleBlackTranslucent;
	[tbar sizeToFit];
	
	NSMutableArray* barItems = [[NSMutableArray alloc] init];
	[barItems addObject:[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
		target:nil action:nil]];
	[barItems addObject:[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemDone
		target:self action:@selector(dismissSheet)]];
	[tbar setItems:barItems animated:YES];

	CGRect frm = CGRectMake(0, 44, self.view.frame.size.width, 320);
	UIPickerView* picker = [[UIPickerView alloc] initWithFrame:frm];
	picker.delegate = self;
	picker.dataSource = self;

	int row = 0;
	for (BoardCategory* cate in m_categories)
	{
		if (cate.cid == self.boardCategoryId)
		{
			[picker selectRow:row inComponent:0 animated:NO];
			break;
		}
		
		++row;
	}
	
	m_sheetPicker = [[UIActionSheet alloc] initWithTitle:nil
		delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
		
	[m_sheetPicker setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
	[m_sheetPicker addSubview:tbar];
    [m_sheetPicker addSubview:picker];
	[m_sheetPicker showInView:self.view];
	
	frm.size.height = picker.frame.size.height + tbar.frame.size.height;
	frm.origin.y = self.view.frame.size.height - frm.size.height;	
	//m_sheetPicker.frame = frm;
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissSheet)];
    tap.cancelsTouchesInView = NO; // So that legit taps on the table bubble up to the tableview
    [m_sheetPicker.superview addGestureRecognizer:tap];
}

-(void)dismissSheet
{
	[m_sheetPicker dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)showCategoriesWithPopover
{
	UITableViewController* tvc = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
	tvc.tableView.dataSource = self;
	tvc.tableView.delegate = self;
	
	m_popoverPicker = [[UIPopoverController alloc] initWithContentViewController:tvc];
    m_popoverPicker.delegate = self;

	[m_popoverPicker presentPopoverFromRect:self.btnCategory.frame
		inView:self.view
		permittedArrowDirections:UIPopoverArrowDirectionAny
		animated:YES];
		
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return m_categories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString* CellIdentifier = @"CatePick";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}

	if (indexPath.row < m_categories.count)
	{
		BoardCategory* cate = [m_categories objectAtIndex:indexPath.row];
		cell.textLabel.text = cate.name;
		
		if (cate.cid == self.boardCategoryId)
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		else
			cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row < m_categories.count)
	{
		BoardCategory* cate = [m_categories objectAtIndex:indexPath.row];
		[self setCategory:cate];

		[m_popoverPicker dismissPopoverAnimated:YES];
	}
}

- (IBAction)onSelectCategory
{
	[self.view endEditing:YES];
	
	if (GetAppDelegate().isIpad)
		[self showCategoriesWithPopover];
	else
		[self showCategoriesWithSheet];
}

#pragma mark -- Gallery Import

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSTRACE(@"photo picked?");
	
	UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
	NSTRACE(@"image: %.1f x %.1f", image.size.width, image.size.height);
	
        NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
        NSTRACE(@"media type: '%@'", mediaType);

        //ivPicture.image = image;

        for( NSString *aKey in info )
        {
                id value = [info objectForKey:aKey];
                NSTRACE(@"img dic %@ --> %@", aKey, value);
        }

        NSURL *imageURL = [info valueForKey: UIImagePickerControllerReferenceURL];
        // The output string will have the file:// prefix
        NSString *filePath1 = [imageURL absoluteString];
        NSLog(@"filePath1: %@", filePath1);
        // The output string will have the file path only
        NSString *filePath2 = [imageURL path];
        NSLog(@"filePath2: %@", filePath2);

        if (imageURL)
        {
        NSData *fileData = [NSData dataWithContentsOfURL:imageURL];
                NSTRACE(@"file data=%@", fileData);
    }


	//[picker dismissModalViewControllerAnimated:YES];
	[self imagePickerControllerDidCancel:picker];

//	curSelImage = [info objectForKey:UIImagePickerControllerOriginalImage];
/*
	confirmPicAlert = [[UIAlertView alloc] initWithTitle:@"사진을 전송하시겠습니까?"
		message:nil delegate:self cancelButtonTitle:@"아니오" otherButtonTitles:@"예", nil];

	[confirmPicAlert show];
	[confirmPicAlert release];
*/
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:^{
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
	}];
}

- (void)pickImage:(UIImagePickerControllerSourceType)sourceType
{
	m_photoPicker = [[UIImagePickerController alloc] init];
	m_photoPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
	m_photoPicker.delegate = self;
	m_photoPicker.sourceType = sourceType;

	[self presentViewController:m_photoPicker animated:YES completion:^{
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
	}];
}

- (IBAction)onAddPic
{
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"죄송합니다."
		message:@"이미지 첨부 기능은 지원 예정입니다."
		delegate:nil cancelButtonTitle:GetLocalizedString(@"ok") otherButtonTitles:nil];
	[alert show];
	
	//[self pickImage:UIImagePickerControllerSourceTypePhotoLibrary];
}

#pragma mark -- Sleek session

extern NSString* trimString(NSString* orig);

- (BOOL)checkSubmit
{
	if (m_writeItem == nil)
		m_writeItem = [ThreadWriteItem new];
	
	if (self.replyThreadId == 0)
	{
		// write new
		m_writeItem.title = trimString(self.tfSubject.text);
		if (m_writeItem.title == nil)
		{
			alertSimpleMessage(GetLocalizedString(@"a_input_title"));
			[self.tfSubject becomeFirstResponder];
			return NO;
		}
	}
	
	m_writeItem.text = trimString(self.tvBody.text);
	if (m_writeItem.text == nil)
	{
		alertSimpleMessage(GetLocalizedString(@"a_input_body"));
		[self.tvBody becomeFirstResponder];
		return NO;
	}

	m_writeItem.categoryId = self.boardCategoryId;
	m_writeItem.replyThreadId = self.replyThreadId;
	
	return YES;
}

- (void)postSleekThread
{
	[GetAppDelegate().currentSession postThread:m_writeItem delegate:self];
}

- (void)sleekSession:(SleekSession*)session postedThreadId:(int)tid
{
	[session hideHud];
	[self.navigationController popViewControllerAnimated:YES];
	[self.writeDelegate sleekPostedThreadId:tid];
}


@end
