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

#import "MGEditingController.h"

#import "multigrapherAppDelegate.h"

#import <Carbon/Carbon.h>
#import "MGSegmentSubview.h"
#import "MGBlankView.h"
#import "MGPanel.h"
#import "MGCenterView.h"

static MGEditingController * sharedInstance = nil;
static bool haveShownInitialHelp = NO;

@implementation MGEditingController

@synthesize isEditing, rootView, editWindow;

- (id)init
{
    self = [super init];
    
    if(self)
    {
        [[[NSApp delegate] content] addObserver:self
                                     forKeyPath:@"arrangedObjects"
                                        options:(NSKeyValueObservingOptionNew| NSKeyValueObservingOptionOld)
                                        context:NULL];
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)Object change:(NSDictionary*)change context:(void*)context
{
    if(!haveShownInitialHelp)
        [self setIsEditing:[self isEditing]];
}

- (void)setIsEditing:(BOOL)inIsEditing
{
    bool oldIsEditing = isEditing;
    isEditing = inIsEditing;
    
    NSRect screenFrame = [[NSScreen mainScreen] frame];
    
    if(isEditing)
    {
        if(oldIsEditing != isEditing)
            [editWindow setAlphaValue:1.0f];
        
        [NSCursor unhide];
        
        NSRect frame;
        
        bool anyNonEmpty = false;
        
        for(id<MGSegmentSubview> sv in [[[NSApp delegate] content] arrangedObjects])
        {
            if(!([sv isKindOfClass:[MGBlankView class]] || [sv isKindOfClass:[MGCenterView class]]))
                anyNonEmpty = true;
        }
        
        haveShownInitialHelp |= anyNonEmpty;
        
        if(anyNonEmpty || haveShownInitialHelp)
        {
            frame = NSMakeRect(screenFrame.size.width / 3, screenFrame.size.height / 3,
                               screenFrame.size.width / 3, screenFrame.size.height / 3);
        }
        else
        {
            frame = NSMakeRect(screenFrame.size.width / 4, screenFrame.size.height / 4,
                               screenFrame.size.width / 2, screenFrame.size.height / 2);
        }
        
        frame = NSInsetRect(frame, 5, 5);
        
        [editWindow setFrame:frame display:YES animate:(oldIsEditing == isEditing)];
        
        [editWindow setLevel:NSModalPanelWindowLevel];
        [editWindow makeKeyAndOrderFront:nil];
    }
    else
    {
        if(oldIsEditing != isEditing)
            [editWindow setAlphaValue:0.0f];
        
        [NSCursor hide];
    }
    
    [rootView setNeedsDisplay:YES];
}

+ (void)handleEvent:(NSEvent *)theEvent
{
    if([theEvent keyCode] == kVK_Tab)
    {
        [[MGEditingController sharedInstance] setIsEditing:![[MGEditingController sharedInstance] isEditing]];
    }
    
    if([theEvent keyCode] == kVK_Delete)
    {
        [[NSApp delegate] deleteSelected];
    }
}

#pragma mark Singleton Methods

+ (MGEditingController *)sharedInstance
{
    @synchronized(self)
    {
        if(sharedInstance == nil)
        {
            sharedInstance = [[MGEditingController alloc] init];
        }
    }
    
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if(sharedInstance == nil)
        {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;
        }
    }
    
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return ULONG_MAX;
}

- (void)release
{
}

- (id)autorelease
{
    return self;
}


@end
