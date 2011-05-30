/*
 * Copyright 2011 Tim Horton. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY TIM HORTON "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL TIM HORTON OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "MGDataSource.h"

#import "MGGraphView.h"
#import "MGTextView.h"

@implementation MGDataSource

@synthesize isResolved;
@synthesize isDiscovered;
@synthesize type;
@synthesize name;
@synthesize url;
@synthesize uuid;

- (id)initWithService:(NSNetService *)service
{
    self = [super init];
    
    if(self)
    {
        isDiscovered = YES;
        isResolved = YES;
        
        // Used when creating a Bonjour-discovered source
        
        NSArray * nameParts = [[service name] componentsSeparatedByString:@"_"];
        type = [nameParts objectAtIndex:0];
        name = [nameParts objectAtIndex:1];
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d", [service hostName], [service port]]];
    }
    
    return self;
}

- (id)initWithURL:(NSURL *)inURL
{
    self = [super init];
    
    if(self)
    {
        isDiscovered = NO;
        
        // Used when creating or deserializing a custom source
    }
    
    return self;
}

- (id)initWithUUID:(NSString *)inUUID
{
    self = [super init];
    
    if(self)
    {
        isDiscovered = YES;
        
        // Used when deserializing a Bonjour-discovered source
    }
    
    return self;
}

-(id)initWithCoder:(NSCoder*)coder
{
    self = [super init];
    
    if(self)
    {
        [coder decodeValueOfObjCType:@encode(bool) at:&isResolved];
        [coder decodeValueOfObjCType:@encode(bool) at:&isDiscovered];
        type = [coder decodeObject];
        name = [coder decodeObject];
        url = [coder decodeObject];
        uuid = [coder decodeObject];
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeValueOfObjCType:@encode(bool) at:&isResolved];
    [coder encodeValueOfObjCType:@encode(bool) at:&isDiscovered];
    [coder encodeObject:type];
    [coder encodeObject:name];
    [coder encodeObject:url];
    [coder encodeObject:uuid];
}

- (NSString *)loadData
{
    if(!isResolved)
        return nil;
    
    NSError * error = nil;
    NSString * result = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    
    if(error)
        return nil;
    
    return result;
}

- (id<MGSegmentSubview>)createSegmentSubview
{
    Class itemClass;
    
    if([type isEqualToString:@"graph"])
    {
        itemClass = [MGGraphView class];
    }
    else if([type isEqualToString:@"text"])
    {
        itemClass = [MGTextView class];
    }
    
    return [[itemClass alloc] initWithDataSource:self];
}

- (void)dealloc
{
    [super dealloc];
}

@end
