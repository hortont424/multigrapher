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

@synthesize child, selected, fakeItem;

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

- (void)setChild:(MGDataSource *)inChild
{
    child = inChild;
    
    if(child == nil)
        return;
    
    fakeItem = [child createSegmentSubview]; 
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSaveGState(ctx);
    
    NSRect rect = NSInsetRect([self bounds], 5, 5);
    NSRect iconRect = NSMakeRect(rect.origin.x, rect.origin.y + 20, rect.size.width, rect.size.height - 20);
    
    [[NSColor colorWithCalibratedWhite:0.1f alpha:1.0f] setFill];
    [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(iconRect, 5, 5) xRadius:10 yRadius:10] fill];
    
    [fakeItem drawSegmentInRect:NSInsetRect(iconRect, 6, 6) withContext:ctx miniature:YES];
    
    [[NSColor colorWithCalibratedWhite:0.3f alpha:1.0f] setStroke];
    [NSBezierPath setDefaultLineWidth:3.0f];
    [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(iconRect, 5, 5) xRadius:10 yRadius:10] stroke];
    
    
    if(selected)
    {
        [[NSColor colorWithCalibratedWhite:0.5f alpha:1.0f] setStroke];
        [NSBezierPath setDefaultLineWidth:3.0f];
        [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds], 3, 3) xRadius:10 yRadius:10] stroke];
    }
    
    NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 [NSFont fontWithName:@"Lucida Grande" size:13.0f], NSFontAttributeName,
                                 [NSColor whiteColor],NSForegroundColorAttributeName,nil];
    
    NSSize size = [[child shortName] sizeWithAttributes:attributes];
    
    [[child shortName] drawAtPoint:NSMakePoint((rect.origin.x + (rect.size.width / 2.0f) - (size.width / 2.0f)),
                                          (rect.origin.y + 2)) withAttributes:attributes];
    
    CGContextRestoreGState(ctx);
}

@end
