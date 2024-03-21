//
//  ViewController.m
//  03-纹理渲染
//
//  Created by Van Zhang on 2024/3/21.
//

#import "ViewController.h"
#import "HPGLView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:[[HPGLView alloc]initWithFrame:self.view.bounds]];
}


@end
