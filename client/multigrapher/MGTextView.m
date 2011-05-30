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

#import "MGTextView.h"

#import "MGDataSource.h"
#import "MGColors.h"

@implementation MGTextView

- (id)initWithDataSource:(MGDataSource *)inSource
{
    self = [super init];
    
    if(self)
    {
        source = inSource;
        dataLoaded = NO;
        [self tick];
    }
    
    return self;
}

- (void)tick
{
    [self updateData];
}

- (bool)isLive
{
    return [source isLive];
}

- (void)updateData
{
    NSError * error = nil;
    NSString * newTitle;
    NSColor * newColor;
    NSString * rawData = [source loadData];
    
    if(!rawData)
        return;
    
    NSMutableArray * rows = [[rawData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
    
    if([rows count] < 2)
        return;
    
    NSArray * titleParts = [[rows objectAtIndex:0] componentsSeparatedByString:@","];
    
    if([titleParts count] != 4)
    {
        [NSException raise:@"Wrong number of arguments in data header"
                    format:@"Got %d, wanted 4", [titleParts count]];
    }
    
    newTitle = [titleParts objectAtIndex:1];
    newColor = [MGColors colorWithKey:[titleParts objectAtIndex:3]];
    
    if(newColor == nil)
    {
        newColor = [MGColors colorWithKey:@"blue"];
    }
    
    [rows removeObjectAtIndex:0];
    
    if(error)
        return;
    
    title = newTitle;
    color = newColor;
    data = [rows componentsJoinedByString:@"\n"];
    data = [data stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    dataLoaded = YES;
}

- (bool)wantsBorder
{
    return NO;
}

- (void)drawSegmentInRect:(NSRect)rect withContext:(CGContextRef)ctx miniature:(bool)miniature
{
    if(!dataLoaded)
    {
        NSString * failedToLoad = @"Loading...";
        NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     [NSFont fontWithName:@"Helvetica Bold" size:miniature ? 16.0f : 48.0f], NSFontAttributeName,
                                     [NSColor whiteColor],NSForegroundColorAttributeName,nil];
        
        NSSize size = [failedToLoad sizeWithAttributes:attributes];
        
        [failedToLoad drawAtPoint:NSMakePoint((rect.origin.x + (rect.size.width / 2.0f) - (size.width / 2.0f)),
                                              (rect.origin.y + (rect.size.height / 2.0f) - (size.height / 2.0f))) withAttributes:attributes];
        
        return;
    }
    
    NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 [NSFont fontWithName:@"Helvetica Bold" size:miniature ? 16.0f : 48.0f], NSFontAttributeName,
                                 color,NSForegroundColorAttributeName,
                                 [NSNumber numberWithDouble:miniature ? 1.0 : 3.0],NSKernAttributeName,nil];
    
    NSSize size = [data sizeWithAttributes:attributes];
    
    [data drawAtPoint:NSMakePoint((rect.origin.x + (rect.size.width / 2.0f) - (size.width / 2.0f)),
                                  (rect.origin.y + (rect.size.height / 2.0f) - (size.height / 2.0f))) withAttributes:attributes];
}

@end
