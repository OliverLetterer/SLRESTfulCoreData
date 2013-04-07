//
//  SLRGBHexStringValueTransformer.m
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

#import "SLRGBHexStringValueTransformer.h"



@interface SLRGBHexStringValueTransformer () {
    
}

@end



@implementation SLRGBHexStringValueTransformer

#pragma mark - Initialization

- (id)initWithDefaultColor:(UIColor *)defaultColor
{
    if (self = [super init]) {
        _defaultColor = defaultColor;
    }
    return self;
}

#pragma mark - NSValueTransformer

- (id)transformedValue:(NSString *)value
{
    if (![value isKindOfClass:[NSString class]] || value.length != 6) {
        return value;
    }
    
    NSRange range = NSMakeRange(0, 2);
    
    NSString *rString = [value substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [value substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [value substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((CGFloat)r/255.0f)
                           green:((CGFloat)g/255.0f)
                            blue:((CGFloat)b/255.0f)
                           alpha:1.0f];
}

- (id)reverseTransformedValue:(UIColor *)value
{
    if (![value isKindOfClass:[UIColor class]]) {
        return @"000000";
    }
    
    CGFloat red, green, blue;
    [value getRed:&red green:&green blue:&blue alpha:NULL];
    return [NSString stringWithFormat:@"%2X%2X%2X", (int)red, (int)green, (int)blue];
}

@end
