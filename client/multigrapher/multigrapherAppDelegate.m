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

#import "multigrapherAppDelegate.h"

#import <Carbon/Carbon.h>

#import "MGSegmentView.h"
#import "MGSegmentSubview.h"
#import "MGGraphView.h"
#import "MGCenterView.h"
#import "MGTextView.h"
#import "MGBlankView.h"
#import "MGEditingController.h"
#import "MGPickerItemView.h"

#define SEGMENT_COLUMNS 3
#define SEGMENT_ROWS 3

@implementation multigrapherAppDelegate

@synthesize window, segmentCollectionView, editWindow, pickerCollectionView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[MGEditingController sharedInstance] setRootView:[window contentView]];
    [[MGEditingController sharedInstance] setEditWindow:editWindow];

    allServices = [[NSMutableArray alloc] init];
    
    [window setLevel:NSFloatingWindowLevel];
    SetSystemUIMode(kUIModeAllHidden, 0);
    
    NSSize segmentSize = NSMakeSize([[NSScreen mainScreen] frame].size.width / SEGMENT_COLUMNS,
                                    [[NSScreen mainScreen] frame].size.height / SEGMENT_ROWS);
    
    [segmentCollectionView setMaxItemSize:segmentSize];
    [segmentCollectionView setMinItemSize:segmentSize];
    
    [editWindow setMovableByWindowBackground:NO];
    
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    
    [[MGEditingController sharedInstance] setIsEditing:NO];
    
    // Main Segments
    
    content = [[NSArrayController alloc] init];
    [segmentCollectionView bind:@"content" toObject:content withKeyPath:@"arrangedObjects" options:nil];
    
    for(int i = 0; i < SEGMENT_COLUMNS * SEGMENT_ROWS; i++)
    {
        if(i == 4)
            [content addObject:[[MGCenterView alloc] init]];
        else
            [content addObject:[[MGBlankView alloc] init]];
    }

    [segmentCollectionView setDelegate:self];
    [segmentCollectionView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
    [segmentCollectionView registerForDraggedTypes:[NSArray arrayWithObjects:MGSegmentDragType,MGPickerDragType,nil]];
    
    // Picker
    
    pickerContent = [[NSArrayController alloc] init];
    [pickerCollectionView bind:@"content" toObject:pickerContent withKeyPath:@"arrangedObjects" options:nil];
    
    [pickerCollectionView setDelegate:self];
    [pickerCollectionView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
    [pickerCollectionView registerForDraggedTypes:[NSArray arrayWithObjects:MGPickerDragType,nil]];
    
    [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
    
    browser = [[NSNetServiceBrowser alloc] init];
    [browser setDelegate:self];
    [browser searchForServicesOfType:@"_multigrapher._tcp." inDomain:@""];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreDomainsComing
{
    [allServices addObject:netService];
    [netService setDelegate:self];
    [netService resolveWithTimeout:30.0f];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    [pickerContent addObject:sender];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreDomainsComing
{
    [pickerContent removeObject:netService];
}

- (void)updateTime:(NSTimer *)timer
{
    for(id<MGSegmentSubview> subview in [segmentCollectionView content])
    {
        [subview tick];
    }
    
    [segmentCollectionView setNeedsDisplay:YES];
    
    if([[MGEditingController sharedInstance] isEditing])
    {
        for(int i = 0; i < [[pickerContent arrangedObjects] count]; i++)
        {
            [[(MGPickerItemView *)[[pickerCollectionView itemAtIndex:i] view] fakeItem] tick];
        }
        
        [pickerCollectionView setNeedsDisplay:YES];
    }
}

-(BOOL)collectionView:(NSCollectionView *)cv acceptDrop:(id < NSDraggingInfo >)draggingInfo index:(NSInteger)toIndex dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    if(cv == segmentCollectionView)
    {
        NSPasteboard * pboard = [draggingInfo draggingPasteboard];
        NSData * pboardData = [pboard dataForType:MGSegmentDragType];
        
        if(pboardData)
        {
            NSInteger fromIndex = [[NSKeyedUnarchiver unarchiveObjectWithData:pboardData] firstIndex];
            
            NSObject * fromObj = [[content arrangedObjects] objectAtIndex:fromIndex];
            NSObject * toObj = [[content arrangedObjects] objectAtIndex:toIndex];
            
            if(toIndex < fromIndex)
            {
                [content removeObject:fromObj];
                [content removeObject:toObj];
                [content insertObject:fromObj atArrangedObjectIndex:toIndex];
                [content insertObject:toObj atArrangedObjectIndex:fromIndex];
            }
            else
            {
                [content removeObject:toObj];
                [content removeObject:fromObj];
                [content insertObject:toObj atArrangedObjectIndex:fromIndex];
                [content insertObject:fromObj atArrangedObjectIndex:toIndex];
            }
        }
        else
        {
            pboardData = [pboard dataForType:MGPickerDragType];
            
            if(!pboardData)
                return NO;
            
            NSDictionary * newSegmentInfo = [NSKeyedUnarchiver unarchiveObjectWithData:pboardData];
            
            NSObject * toObj = [[content arrangedObjects] objectAtIndex:toIndex];
            NSObject * newObj = [[NSClassFromString([newSegmentInfo objectForKey:@"type"]) alloc] initWithURL:[newSegmentInfo objectForKey:@"url"]];
            [content removeObject:toObj];
            [content insertObject:newObj atArrangedObjectIndex:toIndex];
        }
    }
    
    return YES;
}

-(NSDragOperation)collectionView:(NSCollectionView *)cv validateDrop:(id < NSDraggingInfo >)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{
    if(cv == segmentCollectionView)
    {
        if(((*proposedDropIndex) == 4) || (*proposedDropOperation == NSCollectionViewDropBefore))
        {
            return NSDragOperationNone;
        }
    }
    
    return NSDragOperationEvery;
}


- (BOOL)collectionView:(NSCollectionView *)cv writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    if(![[MGEditingController sharedInstance] isEditing])
        return NO;
    
    if(cv == segmentCollectionView)
    {
        if([indexes firstIndex] == 4)
            return NO;
        
        if([[[segmentCollectionView itemAtIndex:[indexes firstIndex]] representedObject] isKindOfClass:[MGBlankView class]])
            return NO;
        
        NSData * data = [NSKeyedArchiver archivedDataWithRootObject:indexes];
        
        [pasteboard declareTypes:[NSArray arrayWithObject:MGSegmentDragType] owner:self];
        [pasteboard setData:data forType:MGSegmentDragType];
    }
    else if(cv == pickerCollectionView)
    {
        MGPickerItemView * picked = (MGPickerItemView *)[[pickerCollectionView itemAtIndex:[indexes firstIndex]] view];
        NSData * data = [NSKeyedArchiver archivedDataWithRootObject:
                         [NSDictionary dictionaryWithObjectsAndKeys:
                          NSStringFromClass([picked itemClass]),@"type",
                          [picked itemURL],@"url",nil]];
        
        [pasteboard declareTypes:[NSArray arrayWithObject:MGPickerDragType] owner:self];
        [pasteboard setData:data forType:MGPickerDragType];
    }
    
    return YES;
}

@end
