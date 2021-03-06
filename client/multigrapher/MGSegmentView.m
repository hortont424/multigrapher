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

#import "MGSegmentView.h"

#import "MGEditingController.h"
#import "MGCenterView.h"
#import "MGBlankView.h"
#import "MGColors.h"

@implementation MGSegmentView

@synthesize child, selected;

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
    if([child isKindOfClass:[MGCenterView class]])
        return;
    
    selected = inSelected;
    
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSaveGState(ctx);
    
    NSRect segmentRect = NSInsetRect([self bounds], 10, 10);
    
    if(child && [child conformsToProtocol:@protocol(MGSegmentSubview)])
    {
        CGContextSaveGState(ctx);
        CGContextClipToRect(ctx, NSRectToCGRect(segmentRect));
        [child drawSegmentInRect:[self bounds] withContext:ctx miniature:NO];
        CGContextRestoreGState(ctx);
        
        if([child wantsBorder])
        {
            [[NSColor colorWithCalibratedWhite:0.1f alpha:1.0f] setStroke];
            [NSBezierPath setDefaultLineWidth:3.0f];
            [[NSBezierPath bezierPathWithRoundedRect:segmentRect xRadius:10 yRadius:10] stroke];
        }
        
        if(![child isKindOfClass:[MGBlankView class]] && ![child isKindOfClass:[MGCenterView class]])
        {
            NSRect pillRect;
            
            [[MGColors colorWithKey:[child isLive] ? @"green" : @"red"] setFill];
            
            if(self.frame.origin.x < [[NSScreen mainScreen] frame].size.width * 0.1)
            {
                pillRect = NSMakeRect(segmentRect.origin.x - 7,
                                      segmentRect.origin.y + (segmentRect.size.height / 2) - 10,
                                      4,
                                      20);
            }
            else if(self.frame.origin.x > [[NSScreen mainScreen] frame].size.width * 0.5)
            {
                pillRect = NSMakeRect(segmentRect.origin.x + segmentRect.size.width + 4,
                                      segmentRect.origin.y + (segmentRect.size.height / 2) - 10,
                                      4,
                                      20);
            }
            else
            {
                if(self.frame.origin.y > [[NSScreen mainScreen] frame].size.width * 0.1)
                {
                    pillRect = NSMakeRect(segmentRect.origin.x + (segmentRect.size.width / 2) - 10,
                                          segmentRect.origin.y - 8,
                                          20,
                                          4);
                }
                else
                {
                    pillRect = NSMakeRect(segmentRect.origin.x + (segmentRect.size.width / 2) - 10,
                                          segmentRect.origin.y + segmentRect.size.height + 3,
                                          20,
                                          4);
                }
            }
            
            [[NSBezierPath bezierPathWithRoundedRect:pillRect xRadius:3 yRadius:3] fill];
        }
    }
    
    if(selected && [[MGEditingController sharedInstance] isEditing])
    {
        [[NSColor colorWithCalibratedWhite:0.3f alpha:1.0f] setStroke];
        [NSBezierPath setDefaultLineWidth:3.0f];
        [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds], 3, 3) xRadius:10 yRadius:10] stroke];
    }
    
    CGContextRestoreGState(ctx);
}

@end
