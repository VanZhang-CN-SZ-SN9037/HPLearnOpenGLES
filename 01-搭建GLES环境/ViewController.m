//
//  ViewController.m
//  01-搭建GLES环境
//
//  Created by Van Zhang on 2024/3/21.
//

#import "ViewController.h"
#import "GLView.h"
@interface ViewController ()

@end

@implementation ViewController
//- (void)loadView{
//    self.view = [[GLView alloc]init];
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:[[GLView alloc]initWithFrame:self.view.bounds]];
}


@end
