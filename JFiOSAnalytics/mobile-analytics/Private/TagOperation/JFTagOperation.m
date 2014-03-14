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

#import "JFTagOperation.h"

static NSString* const kKeenServerAddress = @"https://api.keen.io";
static NSString* const kKeenApiVersion = @"3.0";

@interface JFTagOperation()
@property (nonatomic, strong, readwrite) NSError* error;
@property (nonatomic, strong) NSURLConnection* connection;
@end

@implementation JFTagOperation

+ (instancetype)operationWithTag:(NSDictionary*)tag completionBlock:(JFTagOperationCompletionBlock)completionBlock
{
    NSParameterAssert(tag);
    
    JFTagOperation* tagOperation = [[JFTagOperation alloc] initWithTagURL:tag];
    [tagOperation setJFTagOperationCompletionBlock:completionBlock];
    return tagOperation;
}

- (instancetype)initWithTagURL:(NSDictionary *)tag
{
    if (self = [super init]) {
        _tag = tag;
        _error = nil;
    }
    
    return self;
}

- (void)main
{
    @autoreleasepool {
        
        if (self.isCancelled) {
            return;
        }
    
        NSString *tagURLString = [NSString stringWithFormat:@"%@/%@/projects/%@/events", kKeenServerAddress, kKeenApiVersion, [JFAnalyticsClient sharedClient].projectID];
        NSLog(@"Sending request to: %@", tagURLString);
        NSURL *url = [NSURL URLWithString:tagURLString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        if (self.isCancelled) {
            return;
        }

        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[JFAnalyticsClient sharedClient].writeKey forHTTPHeaderField:@"Authorization"];
        
        if (self.isCancelled) {
            return;
        }
        
        NSData* data = [NSJSONSerialization dataWithJSONObject:self.tag options:NSJSONWritingPrettyPrinted error:nil];
        [request setValue:[NSString stringWithFormat:@"%lud",(unsigned long) [data length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:data];
        
        if (self.isCancelled) {
            return;
        }
        
        NSHTTPURLResponse* response;
        NSError* error;
        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (!response || response.statusCode != 200 || error) {
            NSString* errorDescription = [NSString stringWithFormat:@"Tag request returned response code: %ld and error description: %@", (long)response.statusCode, error.localizedDescription];
            self.error = [NSError errorWithDomain:@"JFTagOperationError" code:333 userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
        }
    }
}

- (void)setJFTagOperationCompletionBlock:(JFTagOperationCompletionBlock)completionBlock {
    if (completionBlock) {
        __block JFTagOperation* _self = self;
        self.completionBlock = ^{
            if (_self.error) {
                completionBlock(_self, JFTagOperationStatusFAILED);
            } else {
                completionBlock(_self, JFTagOperationStatusSUCCESS);
            }
        };
    }
}

@end
