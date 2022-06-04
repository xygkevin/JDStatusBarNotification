//
//  SBCustomStyleViewController.m
//  JDStatusBarNotificationExample
//
//  Created by Markus on 08.11.13.
//  Copyright (c) 2013 Markus. All rights reserved.
//

#import "JDStatusBarLayoutMarginHelper.h"
#import "JDStatusBarNotification.h"
#import "SBSelectPropertyViewController.h"

#import "SBCustomStyleViewController.h"

@interface SBCustomStyleViewController () <UITextFieldDelegate, UIFontPickerViewControllerDelegate, UIColorPickerViewControllerDelegate>
@property (nonatomic, assign) NSInteger colorMode;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, weak) NSTimer *timer;

@property (nonatomic, assign) JDStatusBarAnimationType animationType;
@property (nonatomic, assign) JDStatusBarProgressBarPosition progressBarPosition;
@end

@implementation SBCustomStyleViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = @"Create your own style";
  
  self.animationType = JDStatusBarAnimationTypeMove;
  self.progressBarPosition = JDStatusBarProgressBarPositionBottom;
  
  self.textColorPreview.backgroundColor = self.fontButton.titleLabel.textColor;
  self.barColorPreview.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.000];
  self.progressBarColorPreview.backgroundColor = [UIColor redColor];
  
  self.textColorPreview.layer.cornerRadius = round(CGRectGetHeight(self.textColorPreview.frame)/3.0);
  self.barColorPreview.layer.cornerRadius = self.textColorPreview.layer.cornerRadius;
  self.progressBarColorPreview.layer.cornerRadius = self.textColorPreview.layer.cornerRadius;

  self.fontStepper.value = self.fontButton.titleLabel.font.pointSize;
  
  [self updateFontText];
  [self updateStyle];
  
  [self adjustForLayoutMargin];
}

- (void)adjustForLayoutMargin
{
  // adjust bottom bar to respect layout margins
  CGFloat bottomLayoutMargin = [[UIApplication sharedApplication] windows].firstObject.rootViewController.view.layoutMargins.bottom;
  
  CGRect frame = self.bottomBarView.frame;
  frame.origin.y -= bottomLayoutMargin;
  frame.size.height += bottomLayoutMargin;
  self.bottomBarView.frame = frame;
  
  CGRect scrollViewFrame = self.scrollView.frame;
  scrollViewFrame.size.height -= bottomLayoutMargin;
  self.scrollView.frame = scrollViewFrame;
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  
  self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width,
                                           self.lastRow.frame.origin.y + self.lastRow.frame.size.height + 10.0);
}

#pragma mark - UI Updates

- (void)updateFontText {
  NSString *title = [NSString stringWithFormat: @"Change font (%.1f pt)",
                     self.fontButton.titleLabel.font.pointSize];
  [self.fontButton setTitle:title forState:UIControlStateNormal];
  self.textColorPreview.backgroundColor = self.fontButton.titleLabel.textColor;
}

- (void)updateStyle {
  [[JDStatusBarNotificationPresenter sharedPresenter] addStyleNamed:@"style" prepare:^JDStatusBarStyle *(JDStatusBarStyle *style) {
    style.font = self.fontButton.titleLabel.font;
    style.textColor = self.textColorPreview.backgroundColor;
    style.barColor = self.barColorPreview.backgroundColor;
    style.animationType = self.animationType;
    
    style.progressBarStyle.barColor = self.progressBarColorPreview.backgroundColor;
    style.progressBarStyle.position = self.progressBarPosition;
    
    NSString *height = [self.barHeightLabel.text stringByReplacingOccurrencesOfString:@"ProgressBarHeight (" withString:@""];
    height = [height stringByReplacingOccurrencesOfString:@" pt)" withString:@""];
    style.progressBarStyle.barHeight = [height doubleValue];
    
    return style;
  }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  
  if (textField.text.length == 0) {
    textField.text = @"Notification Text";
  }
  
  [self show:nil];
  
  return YES;
}

#pragma mark - UIFontPickerViewControllerDelegate

- (void)fontPickerViewControllerDidCancel:(UIFontPickerViewController *)viewController {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)fontPickerViewControllerDidPickFont:(UIFontPickerViewController *)viewController {
  self.fontButton.titleLabel.font = [UIFont fontWithDescriptor:viewController.selectedFontDescriptor size:self.fontButton.titleLabel.font.pointSize];
  [self updateFontText];
  [self updateStyle];
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIColorPickerViewController

- (void)showColorPickerWithColor:(UIColor *)color {
  UIColorPickerViewController *colorController = [[UIColorPickerViewController alloc] init];
  colorController.delegate = self;
  colorController.selectedColor = color;
  colorController.supportsAlpha = NO;
  [self presentViewController:colorController animated:YES completion:nil];
}

#pragma mark - UIColorPickerViewControllerDelegate

- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController {
  switch (self.colorMode) {
    case 0: {
      [self.fontButton setTitleColor:viewController.selectedColor forState:UIControlStateNormal];
      self.textColorPreview.backgroundColor = viewController.selectedColor;
      [self updateFontText];
      break;
    }
    case 1: {
      self.barColorPreview.backgroundColor = viewController.selectedColor;
      break;
    }
    case 2: {
      self.progressBarColorPreview.backgroundColor = viewController.selectedColor;
      break;
    }
  }
  
  [self updateStyle];
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Actions

- (IBAction)selectFont:(id)sender {
  UIFontPickerViewControllerConfiguration *config = [UIFontPickerViewControllerConfiguration new];
  config.includeFaces = YES;
  UIFontPickerViewController *controller = [[UIFontPickerViewController alloc] initWithConfiguration:config];
  controller.selectedFontDescriptor = self.fontButton.titleLabel.font.fontDescriptor;
  controller.delegate = self;
  [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)selectFontSize:(UIStepper *)sender {
  self.fontButton.titleLabel.font = [UIFont fontWithName:self.fontButton.titleLabel.font.fontName size:sender.value];
  [self updateFontText];
  [self updateStyle];
}

- (IBAction)selectTextColor:(id)sender {
  self.colorMode = 0;
  [self showColorPickerWithColor:self.textColorPreview.backgroundColor];
}

- (IBAction)selectBarColor:(id)sender {
  self.colorMode = 1;
  [self showColorPickerWithColor:self.barColorPreview.backgroundColor];
}

- (IBAction)selectAnimationStyle:(id)sender {
  NSArray *data = @[@"JDStatusBarAnimationTypeNone",
                    @"JDStatusBarAnimationTypeMove",
                    @"JDStatusBarAnimationTypeBounce",
                    @"JDStatusBarAnimationTypeFade"];
  SBSelectPropertyViewController *controller = [[SBSelectPropertyViewController alloc] initWithData:data resultBlock:^(NSInteger selectedRow) {
    self.animationType = selectedRow;
    [self.animationStyleButton setTitle:data[selectedRow] forState:UIControlStateNormal];
    [self.navigationController popViewControllerAnimated:YES];
    [self updateStyle];
  }];
  controller.title = @"Animation Type";
  controller.activeRow = self.animationType;
  [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)selectProgressBarColor:(id)sender {
  self.colorMode = 2;
  [self showColorPickerWithColor:self.progressBarColorPreview.backgroundColor];
}

- (IBAction)selectProgressBarPosition:(id)sender {
  NSArray *data = @[@"JDStatusBarProgressBarPositionBottom",
                    @"JDStatusBarProgressBarPositionCenter",
                    @"JDStatusBarProgressBarPositionTop"];
  SBSelectPropertyViewController *controller = [[SBSelectPropertyViewController alloc] initWithData:data resultBlock:^(NSInteger selectedRow) {
    self.progressBarPosition = selectedRow;
    [self.barPositionButton setTitle:data[selectedRow] forState:UIControlStateNormal];
    [self.navigationController popViewControllerAnimated:YES];
    [self updateStyle];
  }];
  controller.title = @"Progress Bar Position";
  controller.activeRow = self.progressBarPosition;
  [self.navigationController pushViewController:controller animated:YES];
}

- (IBAction)setProgressBarHeight:(UIStepper *)sender {
  if (sender.value < 1) sender.value = 0.5;
  if (sender.value >= 1) sender.value = round(sender.value);
  
  self.barHeightLabel.text = [NSString stringWithFormat: @"ProgressBarHeight (%.1f pt)", sender.value];
  [self updateStyle];
}

#pragma mark - Presentation

- (IBAction)show:(id)sender {
  [[JDStatusBarNotificationPresenter sharedPresenter] presentWithText:self.textField.text dismissAfterDelay:2.0 customStyle:@"style"];
}

- (IBAction)showWithProgress:(id)sender {
  double delayInSeconds = [[JDStatusBarNotificationPresenter sharedPresenter] isVisible] ? 0.0 : 0.25;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    self.progress = 0.0;
    [self startTimer];
  });
  
  [[JDStatusBarNotificationPresenter sharedPresenter] presentWithText:self.textField.text dismissAfterDelay:1.3 customStyle:@"style"];
}

#pragma mark - Progress Timer

- (void)startTimer {
  [[JDStatusBarNotificationPresenter sharedPresenter] displayProgressBarWithPercentage:self.progress];
  
  [self.timer invalidate];
  self.timer = nil;
  
  if (self.progress < 1.0) {
    CGFloat step = 0.02;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:step target:self
                                                selector:@selector(startTimer)
                                                userInfo:nil repeats:NO];
    self.progress += step;
  } else {
    [self performSelector:@selector(hideProgress)
               withObject:nil afterDelay:0.5];
  }
}

- (void)hideProgress {
  [[JDStatusBarNotificationPresenter sharedPresenter] displayProgressBarWithPercentage:0.0];
}

@end
