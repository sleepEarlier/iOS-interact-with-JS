
# 1.UIWebview与JavaScriptCore
### JavaScriptCore中常用的类型：
 - **JSContext** ：JSContext代表JS的执行环境，它的对象通过`-evaluateScipt:` 方法就可以执行JS代码。可以通过
```
JSContext *jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
```
来从webview上获取相应的JSContext。
 - **JSValue** ：JSValue中封装了JS与ObjC中对应的类型，实现相互间的转换，以及调用JS的API等。
 - **JSExport** ：JSExport是一个协议，一个协议A，只有当协议A继承自JSExport协议时，A中的方法才能被JS调用。

### Objective-C与JS交互
通过JSContext，有两种方式与JS交互：

 1. 通过`-evaluateScipt:` 方法直接调用JS代码
```
    JSContext *context = [[JSContext alloc]init];
    [context evaluateScript:@"function add(a){return a + 10;}"]; // 定义函数
    [context evaluateScript:@"var num = 5;"]; // 定义变量
    JSValue *addFunc = context[@"add"]; // 获取add函数
    JSValue *numVar = context[@"num"]; // 获取变量num
    JSValue *result = [addFunc callWithArguments:@[numVar]];
    NSLog(@"%@",result); // 输出 15
```

 2. 向JSContext中注入对象模型，然后调用模型的方法
 **HTML，在body标签中写如下代码：**
```
    <script>
        function callback(something){
            var target = document.getElementById('result');
            target.innerHTML = something;
        }
        function alertCallback(aString,bString){
            alert(aString+bString);
        }
    </script>
    <br/>
    <br/>
    <div>
        <input type="button" value="调用一个参数或无参数OC方法" onclick="OC.showMessage('are you Objective-C?')">
            <input type="button" value="调用多参数的OC方法" onclick="OC.mixAAndB('hellow','world')">
    </div>
    <br/>
    <br/>
    <div>
        <input type="button" value="调用OC方法并回调" onclick="OC.doSomethingThenCallBack('make it happen')">
    </div>
    <br/>
    <br/>
    <div>
        <h4>回调结果:</h4>
        <span id="result"></span>
    </div>
```
首先，在script标签中声明了两个回调方法，供iOS端来调用；
之后声明了三个button来调用不同的iOS的方法，第一个是一个参数或无参数的方法`showMessage` ,第二个是多参数的方法`- mixAAndB` 。
之所以要区分单个参数和多参数的情况，是因为当多个参数时，如iOS端的方法声明是`- (void)mixA:(NSString *)a andB:(NSString *)b;` 在JS调用时应该将方法名连起来，调整大小写，`mixAAndB(a,b)` 。
三个方法都是通过一个名为 `OC` 的对象调用，这个对象是要在iOS端注入的对象。
最后，callback方法中，将回调结果展示在一个span标签当中。

在协议中声明方法时，可以使用`JSExport` 中的`JSExportAs` 宏来缩短JS端调用时使用的方法名，这样JS端调用时只需要`testArgumentTypes(i,d,b,s,n,a,o)` 即可。
```
@protocol SomeProtocol <JSExport>
JSExportAs(testArgumentTypes,
           - (NSString *)testArgumentTypesWithInt:(int)i double:(double)d 
                    boolean:(BOOL)b string:(NSString *)s number:(NSNumber *)n 
                    array:(NSArray *)a dictionary:(NSDictionary *)o
           );
 
@end
```

 在iOS的viewController的代码（仅做测试，不考虑代码是否合理）:
 首先，声明一个协议`JSInteract` 并让它遵守`JSExport` 协议，在协议中声明需要让JS调用的方法：
```
#import <JavaScriptCore/JavaScriptCore.h>
@protocol JSInteract <JSExport>

- (void)showMessage:(NSString *)message;
- (void)doSomethingThenCallBack:(NSString *)message;
- (void)mixA:(NSString *)aString andB:(NSString*)bString;
@end
```

让`ViewController`遵守`JSInteract`并实现协议中的方法
```
@interface ViewController ()<UIWebViewDelegate,JSInteract>
@property (nonatomic, strong) JSContext *context;
@property (nonatomic, strong)IBOutlet UIWebView *webview;
@end
```

接下来，在webview完成加载时，获取JSContext，并注入 `OC` 对象（即为vc本身），在vc中实现协议中声明的方法：
```
@implementation ViewController
 - (void)viewDidLoad {
    [super viewDidLoad];
    self.webview.delegate = self;
    NSURL *htmlUrl = [[NSBundle mainBundle]URLForResource:@"interact" withExtension:@"html"];
    [self.webview loadRequest:[NSURLRequest requestWithURL:htmlUrl]];
}

 - (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    self.context[@"OC"] = self; // 注入JS需要的“OC”对象
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
```
需要注意的是，JS调用iOS方法时，该方法会在子线程执行，如果需要刷新UI要切换到主线程，而回调JS方法时，保持在子线程即可。
效果：


![](https://github.com/sleepEarlier/iOS-interact-with-JS/raw/master/images/UIWebview.gif)

参考文章：


[iOS与JS交互实战篇（Objc版）](http://mp.weixin.qq.com/s?__biz=MzIzMzA4NjA5Mw==&mid=214063688&idx=1&sn=903258ec2d3ae431b4d9ee55cb59ed89#rd)

更多关于JavaScriptCore：

[iOS7新JavaScriptCore框架入门介绍](http://www.cnblogs.com/ider/p/introduction-to-ios7-javascriptcore-framework.html)

[JavaScriptCore框架在iOS7中的对象交互和管理](http://blog.iderzheng.com/ios7-objects-management-in-javascriptcore-framework/)

使用Safari对webview进行调试
[使用Safari对webview进行调试](http://www.brighttj.com/ios/ios-user-safari-debug-webview.html)
模拟器或真机，在设置--Safari--高级 中打开Web检查器(web Inspector)
Mac Safari 浏览器，偏好设置--高级--打开'开发'菜单
在开发菜单中即可连接当前机器正在打开的webview页面


# 2. WKWebview
在WKWebview中，不能使用`JavascriptCore`进行交互，而是使用`messageHandlers`，相关的方法在`WebKit`的`WKScriptMessageHandler`中：
```
/*! A class conforming to the WKScriptMessageHandler protocol provides a
 method for receiving messages from JavaScript running in a webpage.
 */
@protocol WKScriptMessageHandler <NSObject>

@required

/*! @abstract Invoked when a script message is received from a webpage.
 @param userContentController The user content controller invoking the
 delegate method.
 @param message The script message received.
 */
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;

@end
```

除此之外，在`WKUIDelegate`也有一些与JS的Alert相关的方法
```
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler;

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler;

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler;
```
在`WKWebview`中，JS似乎不能直接  弹出alert，只能通过上面几个方法，将消息和回调作为参数传入，由iOS端来展示Alert。这也算交互的一小部分吧。


回到正题，我们一般想要的交互是JS调用iOS的函数，或者iOS调用JS的函数。

### iOS 调用 JS中的函数
直接通过`WKWebview`的`evaluateJavaScript:completionHandler:`实例方法
```
// 调用JS中的callbackForiOS方法，参数为'Yes im'
[wkWebviewObj evaluateJavaScript:@"callbackForiOS(\"Yes Im\")" completionHandler:^(_Nullable id obj, NSError * _Nullable error) {
            NSLog(@"finish callback");
        }];
```

### JS 调用iOS中的函数
以调用某个`UIViewController`的方法为例，让其遵守`WKScriptMessageHandler`：
```
#import <WebKit/WebKit.h>
@interface MKViewController ()<WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webview;
@end
```


初始化:
```
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
    // 如果需要WKWebview创建、关闭webview的回调或者与AlertPanel相关的回调，使用UIDelegate
    // self.webview.UIDelegate = self;
}
```

在初始化代码中，为`cfg`创建了`userContentController`， 并注册了一个名为`iOSShowMessage`的`MessageHandler`.在JS中，对应地使用下面代码调用`MessageHandler`的方法：
```
// iOSShowMessage为上面WKWebview初始化时注册的name
window.webkit.messageHandlers.iOSShowMessage.postMessage("Are u iOS?")
```

如果JS执行了上面的代码，iOS中会在`WKScriptMessageHandler`协议的方法中得到回调：
```
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    // message.name即注册时使用的name，message.body为参数
    if ([message.name isEqualToString:@"iOSShowMessage"]) {
        // code to execute when receive JS message
    }
    
}
```

效果图:

![](https://github.com/sleepEarlier/iOS-interact-with-JS/raw/master/images/wkwebview.gif)

示例的HTML代码：
```
<!DOCTYPE html>
<html>
<head>
	<title>interact with ios</title>
    <meta charset="UTF-8"/>
</head>
<body>
<script>
    function callbackForiOS(something){
        var target = document.getElementById('result');
        var content = target.innerHTML
        content = "iOS回应: " + something
        target.innerHTML = content;
    }
    function iOSShowMessage(msg) {
        var target = document.getElementById('input');
        var content = target.innerHTML
        content = "给iOS发送消息:'Are u iOS'"
        target.innerHTML = content;
        window.webkit.messageHandlers.iOSShowMessage.postMessage("Are u iOS?")
    }
</script>

<br/>
<br/>

<div>
    <input type="button" value="调用iOS方法" onclick="iOSShowMessage('are you Objective-C?')">
    
</div>

<br/>
<br/>

<div>
    <h4>回调结果:</h4>
    <span id="input"></span>
    <br/>
    <span id="result"></span>
</div>

</body>
</html>

```
