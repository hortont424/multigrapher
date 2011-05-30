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
#import "multigrapherAppDelegate.h"

@implementation MGDataSource

@synthesize isResolved;
@synthesize isDiscovered;
@synthesize isLive;
@synthesize type;
@synthesize shortName;
@synthesize longName;
@synthesize url;
@synthesize hostname;
@synthesize netService;

- (id)initWithService:(NSNetService *)service
{
    self = [super init];
    
    if(self)
    {
        isDiscovered = YES;
        isResolved = YES;
        
        // Used when creating a Bonjour-discovered source
        
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d", [service hostName], [service port]]];
        hostname = [service hostName];
        netService = service;
        
        [self parseHeader];
    }
    
    return self;
}

- (id)initWithURL:(NSURL *)inURL
{
    self = [super init];
    
    if(self)
    {
        isDiscovered = NO;
        isResolved = YES;
        
        // Used when creating or deserializing a custom source
        
        url = inURL;
        
        [self parseHeader];
    }
    
    return self;
}

- (id)initWithHostname:(NSString *)inHostname serviceName:(NSString *)inShortName
{
    self = [super init];
    
    if(self)
    {
        isDiscovered = YES;
        isResolved = NO;
        
        // Used when deserializing a Bonjour-discovered source
        
        [[[NSApp delegate] pickerContent] addObserver:self forKeyPath:@"arrangedObjects" options:0 context:nil];
        
        hostname = inHostname;
        shortName = inShortName;
        
        [self attemptResolution];
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
        shortName = [coder decodeObject];
        longName = [coder decodeObject];
        url = [coder decodeObject];
        hostname = [coder decodeObject];
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeValueOfObjCType:@encode(bool) at:&isResolved];
    [coder encodeValueOfObjCType:@encode(bool) at:&isDiscovered];
    [coder encodeObject:type];
    [coder encodeObject:shortName];
    [coder encodeObject:longName];
    [coder encodeObject:url];
    [coder encodeObject:hostname];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(!isResolved && [keyPath isEqualToString:@"arrangedObjects"] && object == [[NSApp delegate] pickerContent])
    {
        [self attemptResolution];
    }
}

- (void)attemptResolution
{
    for(MGDataSource * src in [[[NSApp delegate] pickerContent] arrangedObjects])
    {
        if(!src.isDiscovered)
            continue;
        
        if([[src.netService hostName] isEqualToString:hostname] && [src.shortName isEqualToString:shortName])
        {
            isResolved = YES;
            url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d", [src.netService hostName], [src.netService port]]];
            netService = src.netService;
            
            [self parseHeader];
        }
    }
}

- (NSString *)loadData
{
    if(!isResolved)
    {
        isLive = NO;
        return nil;
    }
    
    NSError * error = nil;
    NSString * result = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    
    isLive = (!error && result);
    
    if(error)
        return nil;
    
    return result;
}

- (void)parseHeader
{
    NSString * temporaryData = [self loadData];
    
    if(temporaryData)
    {
        NSString * headerLine = [[temporaryData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] objectAtIndex:0];
        NSArray * nameParts = [headerLine componentsSeparatedByString:@","];
        
        if([nameParts count] != 4)
        {
            [NSException raise:@"Wrong number of arguments in data header"
                        format:@"Got %d, wanted 4", [nameParts count]];
        }
        
        shortName = [nameParts objectAtIndex:0];
        longName = [nameParts objectAtIndex:1];
        type = [nameParts objectAtIndex:2];
    }
}

- (id<MGSegmentSubview>)createSegmentSubview
{
    Class itemClass = nil;
    
    if([type isEqualToString:@"graph"])
    {
        itemClass = [MGGraphView class];
    }
    else if([type isEqualToString:@"text"])
    {
        itemClass = [MGTextView class];
    }
    
    if(itemClass == nil)
        return nil;
    
    return [[itemClass alloc] initWithDataSource:self];
}

- (void)dealloc
{
    [super dealloc];
}

@end
