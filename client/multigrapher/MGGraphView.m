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

#import "MGGraphView.h"

#import "MGDataSource.h"
#import "MGColors.h"

@implementation MGGraphView

- (id)initWithDataSource:(MGDataSource *)inSource
{
    self = [super init];
    
    if(self)
    {
        source = inSource;
        [self tick];
    }
    
    return self;
}

- (void)tick
{
    [self updateData];
}

- (void)updateData
{
    // TODO: better error handling when the server doesn't respond
    NSError * error = nil;
    NSString * rawData = [source loadData];
    NSString * newTitle;
    double * newData;
    double newMinData, newMaxData;
    NSColor * newColor;
    long newDataCount;
    NSMutableIndexSet * newBarLocations;
    
    if(error)
    {
        return;
    }
    
    NSArray * rows = [rawData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    if([rows count] < 2)
        return;
    
    NSArray * titleParts = [[rows objectAtIndex:0] componentsSeparatedByString:@","];
    
    if([titleParts count] != 2)
        return;
    
    newTitle = [titleParts objectAtIndex:0];
    
    if([titleParts count] > 1)
    {
        newColor = [MGColors colorWithKey:[titleParts objectAtIndex:1]];
    }
    
    if(newColor == nil)
    {
        newColor = [MGColors colorWithKey:@"blue"];
    }
    
    long rowCount = newDataCount = [rows count] - 1;
    newData = (double *)calloc(newDataCount, sizeof(double));
    newMinData = newMaxData = [[rows objectAtIndex:1] doubleValue];
    
    newBarLocations = [[NSMutableIndexSet alloc] init];
    
    for(int i = 1, actualIndex = 0; i <= rowCount; i++)
    {
        if([[rows objectAtIndex:i] isEqualToString:@"--"])
        {
            [newBarLocations addIndex:actualIndex];
            newDataCount--;
        }
        else
        {
            newData[actualIndex] = [[rows objectAtIndex:i] doubleValue];
            newMinData = MIN(newMinData, newData[actualIndex]);
            newMaxData = MAX(newMaxData, newData[actualIndex]);
            actualIndex++;
        }
    }
    
    title = newTitle;
    color = newColor;
    data = newData;
    minData = newMinData;
    maxData = newMaxData;
    dataCount = newDataCount;
    barLocations = newBarLocations;
    
    dataLoaded = true;
}

- (bool)wantsBorder
{
    return YES;
}

- (void)drawSegmentInRect:(NSRect)rect withContext:(CGContextRef)ctx miniature:(bool)miniature
{
    NSRect originalRect = rect;
    NSString * topStr, * bottomStr, * midStr;
    NSDictionary * titleAttributes, * topAttributes, * midAttributes;
    NSPoint titleDrawPoint, topDrawPoint, bottomDrawPoint, midDrawPoint;
    
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
    
    if(!miniature)
    {
        titleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSFont fontWithName:@"Helvetica Bold" size:22.0f], NSFontAttributeName,
                           [NSColor whiteColor],NSForegroundColorAttributeName,
                           [NSNumber numberWithDouble:1.0],NSKernAttributeName,nil];
        NSSize size = [title sizeWithAttributes:titleAttributes];
        titleDrawPoint = NSMakePoint((rect.origin.x + (rect.size.width / 2.0f) - (size.width / 2.0f)),
                                      rect.origin.y + rect.size.height - size.height - 15);
        
        topAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSFont fontWithName:@"Helvetica" size:22.0f], NSFontAttributeName,
                         [NSColor darkGrayColor],NSForegroundColorAttributeName,
                         [NSNumber numberWithDouble:1.0],NSKernAttributeName,nil];
        
        topStr = [NSString stringWithFormat:@"%0.1f",maxData];
        size = [topStr sizeWithAttributes:topAttributes];
        topDrawPoint = NSMakePoint((rect.origin.x + rect.size.width - size.width - 15),
                                    rect.origin.y + rect.size.height - size.height - 15);
        
        bottomStr = [NSString stringWithFormat:@"%0.1f",minData];
        size = [bottomStr sizeWithAttributes:topAttributes];
        bottomDrawPoint = NSMakePoint((rect.origin.x + rect.size.width - size.width - 15),
                                       rect.origin.y + size.height * 0.5);
        
        midAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSFont fontWithName:@"Helvetica Bold" size:26.0f], NSFontAttributeName,
                         color,NSForegroundColorAttributeName,
                         [NSNumber numberWithDouble:1.0],NSKernAttributeName,nil];
        
        midStr = [NSString stringWithFormat:@"%0.2f",data[dataCount-1]];
        size = [midStr sizeWithAttributes:midAttributes];
        midDrawPoint = NSMakePoint((rect.origin.x + rect.size.width - size.width - 15),
                                    rect.origin.y + (rect.size.height / 2.0f) - (size.height / 2.0f));
        
        rect.size.height -= size.height + 10;
        rect.origin.y += 3;
        rect.size.width -= size.width + 25;
    }
    
    double xPerRow = rect.size.width / dataCount;
    double x = rect.origin.x;
    double amplitude = maxData - minData;
    
    double scale = (rect.size.height / amplitude) * 0.9;
    double shift = (rect.size.height / 2.0f) - ((maxData*scale + minData*scale) / 2.0f);
    
    if([barLocations count] > 0)
    {
        CGContextSetGrayStrokeColor(ctx, 0.1f, 1.0f);
        CGContextSetLineWidth(ctx, 3.0f);
        [barLocations enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            CGContextMoveToPoint(ctx, rect.origin.x + (xPerRow * idx), rect.origin.y);
            CGContextAddLineToPoint(ctx, rect.origin.x + (xPerRow * idx), rect.origin.y + originalRect.size.height);
        }];
        CGContextStrokePath(ctx);
    }
    
    if(!miniature)
    {
        [title drawAtPoint:titleDrawPoint withAttributes:titleAttributes];
        [topStr drawAtPoint:topDrawPoint withAttributes:topAttributes];
        [bottomStr drawAtPoint:bottomDrawPoint withAttributes:topAttributes];
        [midStr drawAtPoint:midDrawPoint withAttributes:midAttributes];
    }
    
    CGContextBeginPath(ctx);
    
    for(int i = 0; i < dataCount; i++)
    {
        double y = rect.origin.y + (data[i] * scale) + shift;
        
        if(i == 0)
        {
            CGContextMoveToPoint(ctx, x, y);
        }
        else
        {
            CGContextAddLineToPoint(ctx, x, y);
        }
        
        x += xPerRow;
    }
    
    [color setStroke];
    CGContextSetLineWidth(ctx, 3.0f);
    CGContextStrokePath(ctx);
}

@end
