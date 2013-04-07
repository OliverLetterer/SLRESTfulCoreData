//
//  SLJSONStringValueTransformer.m
//  SLRESTfulCoreData
//
//  The MIT License (MIT)
//  Copyright (c) 2013 Oliver Letterer, Sparrow-Labs
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "SLJSONStringValueTransformer.h"



@interface SLJSONStringValueTransformer () {
    
}

@end



@implementation SLJSONStringValueTransformer

#pragma mark - Initialization

- (id)initWithDesiredJSONObjectClass:(Class)desiredJSONObjectClass
{
    if (self = [super init]) {
        _desiredJSONObjectClass = desiredJSONObjectClass;
    }
    return self;
}

#pragma mark - NSValueTransformer

- (id)transformedValue:(NSString *)value
{
    if (![value isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    @try {
        id object = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        
        if (self.desiredJSONObjectClass) {
            return [object isKindOfClass:self.desiredJSONObjectClass] ? object : nil;
        }
        
        return object;
    } @catch (NSException *exception) { }
}

- (id)reverseTransformedValue:(id)value
{
    if (self.desiredJSONObjectClass && !value) {
        value = [[self.desiredJSONObjectClass alloc] init];
    }
    
    @try {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:0 error:NULL];
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } @catch (NSException *exception) { }
    
    return @"";
}

@end
