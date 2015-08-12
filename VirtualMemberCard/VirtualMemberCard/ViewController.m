//
//  ViewController.m
//  VirtualMemberCard
//
//  Created by 薛纪杰 on 15/8/10.
//  Copyright (c) 2015年 薛纪杰. All rights reserved.
//

#import "ViewController.h"
#import "XSVirtualMemberCardViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)getVirtualMemberCard:(UIButton *)sender {
    XSVirtualMemberCardViewController *mvc = [[XSVirtualMemberCardViewController alloc] init];
    [self.navigationController pushViewController:mvc animated:YES];
}

@end
