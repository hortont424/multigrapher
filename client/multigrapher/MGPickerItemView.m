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

#import "MGPickerItemView.h"
#import "MGEditingController.h"
#import "MGTextView.h"
#import "MGGraphView.h"

@implementation MGPickerItemView

@synthesize child, selected, itemClass, itemURL;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    if(self)
    {
        
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)keyDown:(NSEvent *)theEvent
{
    [MGEditingController handleEvent:theEvent];
}

- (void)setSelected:(BOOL)inSelected
{
    selected = inSelected;
    
    [self setNeedsDisplay:YES];
}

- (void)setChild:(NSNetService *)inChild
{
    child = inChild;
    
    if(child == nil)
        return;
    
    NSArray * nameParts = [[child name] componentsSeparatedByString:@"_"];
    NSString * typeName = [nameParts objectAtIndex:0];
    actualName = [nameParts objectAtIndex:1];
    
    if([typeName isEqualToString:@"graph"])
    {
        itemClass = [MGGraphView class];
    }
    else if([typeName isEqualToString:@"text"])
    {
        itemClass = [MGTextView class];
    }
    
    itemURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d", [child hostName], [child port]]];
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSaveGState(ctx);
    
    NSRect rect = NSInsetRect([self bounds], 5, 5);
    
    CGContextSetGrayFillColor(ctx, 0.2f, 1.0f);
    CGContextFillRect(ctx, CGRectMake(rect.origin.x, rect.origin.y + 20, rect.size.width, rect.size.height - 20));
    
    if(selected)
    {
        [[NSColor colorWithCalibratedWhite:0.3f alpha:1.0f] setStroke];
        [NSBezierPath setDefaultLineWidth:3.0f];
        [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds], 3, 3) xRadius:10 yRadius:10] stroke];
    }
    
    NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 [NSFont fontWithName:@"Lucida Grande" size:13.0f], NSFontAttributeName,
                                 [NSColor whiteColor],NSForegroundColorAttributeName,nil];
    
    NSSize size = [actualName sizeWithAttributes:attributes];
    
    [actualName drawAtPoint:NSMakePoint((rect.origin.x + (rect.size.width / 2.0f) - (size.width / 2.0f)),
                                          (rect.origin.y + 2)) withAttributes:attributes];
    
    CGContextRestoreGState(ctx);
}

@end
