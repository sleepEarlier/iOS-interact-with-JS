//
//  JSInteract.h
//  JSInteract
//
//  Created by kimiLin on 2017/7/5.
//  Copyright © 2017年 KimiLin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol JSInteract <JSExport>

- (void)showMessage:(NSString *)message;
- (void)doSomethingThenCallBack:(NSString *)message;
- (void)mixA:(NSString *)aString andB:(NSString*)bString;

@end
