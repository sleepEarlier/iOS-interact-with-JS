//
//  MKViewController.m
//  JSInteract
//
//  Created by kimiLin on 2017/7/5.
//  Copyright © 2017年 KimiLin. All rights reserved.
//

#import "MKViewController.h"
#import <WebKit/WebKit.h>
@interface MKViewController ()<WKScriptMessageHandler, WKUIDelegate>
@property (nonatomic, strong) WKWebView *webview;
@end

@implementation MKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 偏好设置
    WKPreferences *prefs = [[WKPreferences alloc]init];
    prefs.minimumFontSize = 20;
    prefs.javaScriptEnabled = YES;
    
    WKWebViewConfiguration *cfg = [WKWebViewConfiguration new];
    cfg.preferences = prefs;
    cfg.processPool = [WKProcessPool new];
    
    // UserContentController, 与JS交互发生的地方
    cfg.userContentController = [WKUserContentController new];
    // 只有注册了的name，js使用这个name发送消息才会进入回调
    [cfg.userContentController addScriptMessageHandler:self name:@"iOSShowMessage"];
    
    self.webview = [[WKWebView alloc]initWithFrame:self.view.bounds configuration:cfg];
    [self.view addSubview:self.webview];
    
    NSString *paht = [[NSBundle mainBundle] pathForResource:@"WKInteract" ofType:@"html"];
    NSString *content = [[NSString alloc] initWithContentsOfFile:paht encoding:NSUTF8StringEncoding error:nil];
    [self.webview loadHTMLString:content baseURL:nil];
    self.webview.UIDelegate = self;
}

/*! @abstract Invoked when a script message is received from a webpage.
 @param userContentController The user content controller invoking the
 delegate method.
 @param message The script message received.
 */
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    // message.name即注册时使用的name，message.body为参数
    if ([message.name isEqualToString:@"iOSShowMessage"]) {
        [self.webview evaluateJavaScript:@"callbackForiOS(\"Yes Im\")" completionHandler:^(_Nullable id obj, NSError * _Nullable error) {
            NSLog(@"finish callback");
        }];
    }
    
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    NSLog(@"%s",__func__);
    if (completionHandler) {
        completionHandler();
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    NSLog(@"%s",__func__);
    if (completionHandler) {
        completionHandler(YES);
    }
}

- (void)showMessage:(NSString *)message {
    NSLog(@"%s",__func__);
}

- (void)doSomethingThenCallBack:(NSString *)message {
    NSLog(@"%s",__func__);
}

- (void)mixA:(NSString *)aString andB:(NSString*)bString {
    NSLog(@"%s",__func__);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
