//
//  ViewController.m
//  AutoGetterPlugin
//
//  Created by HChong on 2017/6/22.
//  Copyright © 2017年 HChong. All rights reserved.
//

#import "ViewController.h"

@interface ViewController()

@property (nonatomic, strong) NSString *name;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
