//
//  NSString+SLRESTfulCoreData.m
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

#import "SLRESTfulCoreData.h"

@implementation NSString (SLRESTfulCoreData)

- (NSString *)stringByCamelizingString
{
    static NSCache *cache = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
    });
    
    NSString *cachedString = [cache objectForKey:self];
    if (cachedString) {
        return cachedString;
    }
    
    NSArray *components = [self componentsSeparatedByString:@"_"];
    
    NSMutableString *camelizedString = [NSMutableString stringWithCapacity:self.length];
    [components enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, BOOL *stop) {
        if (idx == 0) {
            [camelizedString appendString:component];
        } else {
            if (component.length > 0) {
                NSString *firstLetter = [component substringToIndex:1];
                NSString *restString = [component substringFromIndex:1];
                [camelizedString appendFormat:@"%@%@", firstLetter.uppercaseString, restString];
            }
        }
    }];
    
    [cache setObject:camelizedString forKey:self];
    
    return camelizedString;
}

- (NSString *)stringByUnderscoringString
{
    static NSCache *cache = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
    });
    
    NSString *cachedString = [cache objectForKey:self];
    if (cachedString) {
        return cachedString;
    }
    
    NSString *underscoredString = self;
    
	underscoredString = [underscoredString stringByReplacingOccurrencesOfString:@"([A-Z]+)([A-Z][a-z])" withString:@"$1_$2" options:NSRegularExpressionSearch range:NSMakeRange(0, underscoredString.length)];
    underscoredString = [underscoredString stringByReplacingOccurrencesOfString:@"([a-z\\d])([A-Z])" withString:@"$1_$2" options:NSRegularExpressionSearch range:NSMakeRange(0, underscoredString.length)];
    underscoredString = [underscoredString stringByReplacingOccurrencesOfString:@"-" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, underscoredString.length)];
    underscoredString = underscoredString.lowercaseString;
    
    [cache setObject:underscoredString forKey:self];
    
	return underscoredString;
}

@end
