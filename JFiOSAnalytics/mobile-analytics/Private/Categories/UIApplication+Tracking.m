/*
 * JFiOSAnalytics
 *
 * Created by Jeremy Fox on 10/19/12.
 * Copyright (c) 2012 Jeremy Fox. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "UIApplication+Tracking.h"
#import "JFAnalyticsClient.h"
#import <objc/runtime.h>

@implementation UIApplication (Tracking)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(sendEvent:);
        SEL swizzledSelector = @selector(JF_sendEvent:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)JF_sendEvent:(UIEvent *)event
{
    UIView* view = ((UITouch*)event.allTouches.allObjects[0]).view;
    NSString* viewName = [self getDetailedName:view];
    NSString* superViewName = NSStringFromClass(view.superview.class);
    NSString* fullTag = [NSString stringWithFormat:@"%@_%@_Tapped", superViewName, viewName];
    if (viewName && viewName.length > 0 && superViewName && superViewName.length > 0) {
        [[JFAnalyticsClient sharedClient] fire:@{@"tap": fullTag}];
    }
    [self JF_sendEvent:event];
}

- (NSString*)getDetailedName:(UIView*)view
{
    NSString* name = NSStringFromClass(view.class);
    if ([view isKindOfClass:UIButton.class]) {
        name = [NSString stringWithFormat:@"%@_%@", ((UIButton*)view).titleLabel.text, name];
    } else if ([view isKindOfClass:UISegmentedControl.class]) {
        
    } else if ([view isKindOfClass:UISlider.class]) {
        
    } else if ([view isKindOfClass:UISwitch.class]) {
        
    } else if ([view isKindOfClass:UIStepper.class]) {
        
    }
    
    return [name stringByReplacingOccurrencesOfString:@" " withString:@"_"];
}

@end
