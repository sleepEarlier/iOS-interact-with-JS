//
//  ViewController.m
//  JSInteract
//
//  Created by kimiLin on 2017/7/5.
//  Copyright © 2017年 KimiLin. All rights reserved.
//

#import "ViewController.h"
#import "JSInteract.h"



@interface ViewController ()<UIWebViewDelegate,JSInteract>
@property (nonatomic, strong) JSContext *context;
@property (nonatomic, strong)IBOutlet UIWebView *webview;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.webview.delegate = self;
    NSURL *htmlUrl = [[NSBundle mainBundle]URLForResource:@"interact" withExtension:@"html"];
    [self.webview loadRequest:[NSURLRequest requestWithURL:htmlUrl]];
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    self.context[@"OC"] = self; // 注入JS需要的“OC”对象
    NSLog(@"context:%@",self.context);
}

- (void)showMessage:(NSString *)message
{
    NSLog(@"current:%@",[NSThread currentThread]);// 子线程
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"JS 调用了 OC" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)doSomethingThenCallBack:(NSString *)message
{
    NSString *result = [message stringByAppendingString:@"<br/>OC get message from JS then call back."];
    JSValue *callback = self.context[@"callback"];
    [callback callWithArguments:@[result]];
}

- (void)mixA:(NSString *)aString andB:(NSString *)bString
{
    NSLog(@"A:%@ and B:%@",aString,bString);
    JSValue *alertCallback = self.context[@"alertCallback"];
    [alertCallback callWithArguments:@[aString,bString]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
