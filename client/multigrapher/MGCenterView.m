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

#import "MGCenterView.h"

#import "MGEditingController.h"

@implementation MGCenterView

- (id)initWithURL:(NSURL *)url
{
    self = [super init];

    if(self)
    {

    }
    return self;
}

- (void)tick
{

}

- (bool)wantsBorder
{
    return NO;
}

- (void)drawSegmentInRect:(NSRect)rect withContext:(CGContextRef)ctx miniature:(bool)miniature
{
    if([[MGEditingController sharedInstance] isEditing])
        return;
    
    NSString * time = [[NSDate date] descriptionWithCalendarFormat:@"%H:%M" timeZone:nil
                                                            locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];

    NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 [NSFont fontWithName:@"Helvetica Bold" size:144.0f], NSFontAttributeName,
                                 [NSColor whiteColor],NSForegroundColorAttributeName,
                                 [NSNumber numberWithDouble:3.0],NSKernAttributeName,nil];

    NSSize size = [time sizeWithAttributes:attributes];

    [time drawAtPoint:NSMakePoint((rect.origin.x + (rect.size.width / 2.0f) - (size.width / 2.0f)),
                                  (rect.origin.y + (rect.size.height / 2.0f) - (size.height / 2.0f))) withAttributes:attributes];
}

@end
