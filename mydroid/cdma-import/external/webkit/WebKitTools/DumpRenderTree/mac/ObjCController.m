/*
 * Copyright (C) 2007 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer. 
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution. 
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ObjCController.h"

#import <WebKit/DOMAbstractView.h>
#import <WebKit/WebScriptObject.h>
#import <WebKit/WebView.h>
#import <wtf/Assertions.h>

@implementation ObjCController

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    if (0
            || aSelector == @selector(classNameOf:)
            || aSelector == @selector(objectOfClass:)
            || aSelector == @selector(identityIsEqual::)
            || aSelector == @selector(longLongRoundTrip:)
            || aSelector == @selector(unsignedLongLongRoundTrip:)
            || aSelector == @selector(testWrapperRoundTripping:)
            || aSelector == @selector(accessStoredWebScriptObject)
            || aSelector == @selector(storeWebScriptObject:)
        )
        return NO;
    return YES;
}

+ (NSString *)webScriptNameForSelector:(SEL)aSelector
{
    if (aSelector == @selector(classNameOf:))
        return @"className";
    if (aSelector == @selector(objectOfClass:))
        return @"objectOfClass";
    if (aSelector == @selector(identityIsEqual::))
        return @"identityIsEqual";
    if (aSelector == @selector(longLongRoundTrip:))
        return @"longLongRoundTrip";
    if (aSelector == @selector(unsignedLongLongRoundTrip:))
        return @"unsignedLongLongRoundTrip";
    if (aSelector == @selector(testWrapperRoundTripping:))
        return @"testWrapperRoundTripping";
    if (aSelector == @selector(storeWebScriptObject:))
        return @"storeWebScriptObject";

    return nil;
}

- (NSString *)classNameOf:(id)object
{
    if (!object)
        return @"nil";
    return NSStringFromClass([object class]);
}

- (id)objectOfClass:(NSString *)aClass
{
    if ([aClass isEqualToString:@"NSNull"])
        return [NSNull null];
    if ([aClass isEqualToString:@"WebUndefined"])
        return [WebUndefined undefined];
    if ([aClass isEqualToString:@"NSCFBoolean"])
        return [NSNumber numberWithBool:true];
    if ([aClass isEqualToString:@"NSCFNumber"])
        return [NSNumber numberWithInt:1];
    if ([aClass isEqualToString:@"NSCFString"])
        return @"";
    if ([aClass isEqualToString:@"WebScriptObject"])
        return self;
    if ([aClass isEqualToString:@"NSArray"])
        return [NSArray array];

    return nil;
}

- (BOOL)identityIsEqual:(WebScriptObject *)a :(WebScriptObject *)b
{
    if ([a isKindOfClass:[NSString class]] && [b isKindOfClass:[NSString class]])
        return [(NSString *)a isEqualToString:(NSString *)b];
    return a == b;
}

- (long long)longLongRoundTrip:(long long)num
{
    return num;
}

- (unsigned long long)unsignedLongLongRoundTrip:(unsigned long long)num
{
    return num;
}

- (BOOL)testWrapperRoundTripping:(WebScriptObject *)webScriptObject
{
    JSObjectRef jsObject = [webScriptObject JSObject];

    if (!jsObject)
        return false;

    if (!webScriptObject)
        return false;

    if ([[webScriptObject evaluateWebScript:@"({ })"] class] != [webScriptObject class])
        return false;

    [webScriptObject setValue:[NSNumber numberWithInt:666] forKey:@"key"];
    if (![[webScriptObject valueForKey:@"key"] isKindOfClass:[NSNumber class]] ||
        ![[webScriptObject valueForKey:@"key"] isEqualToNumber:[NSNumber numberWithInt:666]])
        return false;

    [webScriptObject removeWebScriptKey:@"key"];
    @try {
        if ([webScriptObject valueForKey:@"key"])
            return false;
    } @catch(NSException *exception) {
        // NSObject throws an exception if the key doesn't exist.
    }

    [webScriptObject setWebScriptValueAtIndex:0 value:webScriptObject];
    if ([webScriptObject webScriptValueAtIndex:0] != webScriptObject)
        return false;

    if ([[webScriptObject stringRepresentation] isEqualToString:@"[Object object]"])
        return false;

    if ([webScriptObject callWebScriptMethod:@"returnThis" withArguments:nil] != webScriptObject)
        return false;

    return true;
}

- (void)accessStoredWebScriptObject
{
#if !ASSERT_DISABLED
    BOOL isWindowObject = [storedWebScriptObject isKindOfClass:[DOMAbstractView class]];
#endif
    JSObjectRef jsObject = [storedWebScriptObject JSObject];
    ASSERT((jsObject && isWindowObject) || (!jsObject && !isWindowObject));

    [storedWebScriptObject callWebScriptMethod:@"" withArguments:nil];
    [storedWebScriptObject evaluateWebScript:@""];
    [storedWebScriptObject setValue:[WebUndefined undefined] forKey:@"key"];
    [storedWebScriptObject valueForKey:@"key"];
    [storedWebScriptObject removeWebScriptKey:@"key"];
    [storedWebScriptObject stringRepresentation];
    [storedWebScriptObject webScriptValueAtIndex:0];
    [storedWebScriptObject setWebScriptValueAtIndex:0 value:[WebUndefined undefined]];
    [storedWebScriptObject setException:@"exception"];
}

- (void)storeWebScriptObject:(WebScriptObject *)webScriptObject
{
    if (webScriptObject == storedWebScriptObject)
        return;

    [storedWebScriptObject release];
    storedWebScriptObject = [webScriptObject retain];
}

- (void)dealloc
{
    [storedWebScriptObject release];
    [super dealloc];
}

- (id)invokeUndefinedMethodFromWebScript:(NSString *)name withArguments:(NSArray *)args
{
    // FIXME: Perhaps we should log that this has been called.
    return nil;
}

@end
