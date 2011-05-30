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
        dataLoaded = NO;
        source = inSource;
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
    NSString * rawData = [source loadData];
    NSString * newTitle;
    MGPoint * newData;
    double newMinY, newMaxY;
    NSColor * newColor;
    long newDataCount;
    NSMutableIndexSet * newBarLocations;
    
    if(!rawData)
        return;
    
    NSArray * rows = [rawData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
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
    
    long rowCount = newDataCount = [rows count] - 1;
    newData = (MGPoint *)calloc(newDataCount, sizeof(MGPoint));
    
    NSString * firstDataRow = [rows objectAtIndex:1];
    NSArray * firstDataRowParts = [firstDataRow componentsSeparatedByString:@","];
    
    if([firstDataRowParts count] == 1)
    {
        newMinY = newMaxY = [[firstDataRowParts objectAtIndex:0] doubleValue];
    }
    else if([firstDataRowParts count] == 2)
    {
        newMinY = newMaxY = [[firstDataRowParts objectAtIndex:1] doubleValue];
    }
    
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
            NSString * currentRow = [rows objectAtIndex:i];
            NSArray * rowParts = [currentRow componentsSeparatedByString:@","];
            
            if([rowParts count] == 1)
            {
                if(actualIndex == 1)
                {
                    newData[actualIndex].x = 0;
                }
                else
                {
                    newData[actualIndex].x = newData[actualIndex - 1].x + 1;
                }
                
                newData[actualIndex].y = [[rowParts objectAtIndex:0] doubleValue];
                
                newMinY = MIN(newMinY, newData[actualIndex].y);
                newMaxY = MAX(newMaxY, newData[actualIndex].y);
                
                actualIndex++;
            }
            else if([rowParts count] == 2)
            {
                newData[actualIndex].x = [[rowParts objectAtIndex:0] doubleValue];
                newData[actualIndex].y = [[rowParts objectAtIndex:1] doubleValue];
                
                newMinY = MIN(newMinY, newData[actualIndex].y);
                newMaxY = MAX(newMaxY, newData[actualIndex].y);
                
                actualIndex++;
            }
            else
            {
                NSLog(@"Too many columns: %@", currentRow);
                newDataCount--;
            }
        }
    }
    
    title = newTitle;
    color = newColor;
    data = newData;
    minY = newMinY;
    maxY = newMaxY;
    dataCount = newDataCount;
    barLocations = newBarLocations;
    
    dataLoaded = YES;
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
        
        topStr = [NSString stringWithFormat:@"%0.1f",maxY];
        size = [topStr sizeWithAttributes:topAttributes];
        topDrawPoint = NSMakePoint((rect.origin.x + rect.size.width - size.width - 15),
                                    rect.origin.y + rect.size.height - size.height - 15);
        
        bottomStr = [NSString stringWithFormat:@"%0.1f",minY];
        size = [bottomStr sizeWithAttributes:topAttributes];
        bottomDrawPoint = NSMakePoint((rect.origin.x + rect.size.width - size.width - 15),
                                       rect.origin.y + size.height * 0.5);
        
        midAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSFont fontWithName:@"Helvetica Bold" size:26.0f], NSFontAttributeName,
                         color,NSForegroundColorAttributeName,
                         [NSNumber numberWithDouble:1.0],NSKernAttributeName,nil];
        
        midStr = [NSString stringWithFormat:@"%0.2f",data[dataCount-1].y];
        size = [midStr sizeWithAttributes:midAttributes];
        midDrawPoint = NSMakePoint((rect.origin.x + rect.size.width - size.width - 15),
                                    rect.origin.y + (rect.size.height / 2.0f) - (size.height / 2.0f));
        
        rect.size.height -= size.height + 10;
        rect.origin.y += 3;
        rect.size.width -= size.width + 25;
    }
    
    double yAmplitude = maxY - minY;
    double xAmplitude = data[dataCount-1].x - data[0].x;
    
    double yScale = (rect.size.height / yAmplitude) * 0.9;
    double yShift = (rect.size.height / 2.0f) - ((maxY * yScale + minY * yScale) / 2.0f);
    
    double xScale = (rect.size.width / xAmplitude);
    double xShift = (-data[0].x * xScale) + 1;
    
    if(!miniature)
    {
        if([barLocations count] > 0)
        {
            CGContextSetGrayStrokeColor(ctx, 0.1f, 1.0f);
            CGContextSetLineWidth(ctx, 3.0f);
            [barLocations enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                double x = rect.origin.x + (data[idx].x * xScale) + xShift;
                
                CGContextMoveToPoint(ctx, x, rect.origin.y);
                CGContextAddLineToPoint(ctx, x, rect.origin.y + originalRect.size.height);
            }];
            CGContextStrokePath(ctx);
        }
        
        [title drawAtPoint:titleDrawPoint withAttributes:titleAttributes];
        [topStr drawAtPoint:topDrawPoint withAttributes:topAttributes];
        [bottomStr drawAtPoint:bottomDrawPoint withAttributes:topAttributes];
        [midStr drawAtPoint:midDrawPoint withAttributes:midAttributes];
    }
    
    CGContextBeginPath(ctx);
    
    for(int i = 0; i < dataCount; i++)
    {
        double x = rect.origin.x + (data[i].x * xScale) + xShift;
        double y = rect.origin.y + (data[i].y * yScale) + yShift;
        
        if(i == 0)
        {
            CGContextMoveToPoint(ctx, x, y);
        }
        else
        {
            CGContextAddLineToPoint(ctx, x, y);
        }
    }
    
    [color setStroke];
    CGContextSetLineWidth(ctx, 3.0f);
    CGContextStrokePath(ctx);
}

@end
