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
#import "MGDataSource.h"

#define SEGMENT_COLUMNS 3
#define SEGMENT_ROWS 3

@implementation multigrapherAppDelegate

@synthesize window, segmentCollectionView, editWindow, pickerCollectionView, content;
@synthesize topInstructions, bottomInstructions, customSourceURI, pickerContent;
@synthesize noServerLabel;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    content = [[NSArrayController alloc] init];
    pickerContent = [[NSArrayController alloc] init];
    
    for(int i = 0; i < SEGMENT_COLUMNS * SEGMENT_ROWS; i++)
    {
        if(i == 4)
            [content addObject:[[MGCenterView alloc] init]];
        else
            [content addObject:[[MGBlankView alloc] init]];
    }
    
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
    
    [[MGEditingController sharedInstance] setIsEditing:YES];
    
    // Main Segments

    [segmentCollectionView bind:@"content" toObject:content withKeyPath:@"arrangedObjects" options:nil];

    [segmentCollectionView setDelegate:self];
    [segmentCollectionView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
    [segmentCollectionView registerForDraggedTypes:[NSArray arrayWithObjects:MGSegmentDragType,MGPickerDragType,nil]];
    
    // Picker

    [pickerCollectionView bind:@"content" toObject:pickerContent withKeyPath:@"arrangedObjects" options:nil];
    
    [pickerCollectionView setDelegate:self];
    [pickerCollectionView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
    [pickerCollectionView registerForDraggedTypes:[NSArray arrayWithObjects:MGPickerDragType,nil]];
    
    [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
    
    browser = [[NSNetServiceBrowser alloc] init];
    [browser setDelegate:self];
    [browser searchForServicesOfType:@"_multigrapher._tcp." inDomain:@""];
    
    [pickerContent addObserver:self forKeyPath:@"arrangedObjects" options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"arrangedObjects"] && object == pickerContent)
    {
        noServerLabel.layer.opacity = [[pickerContent arrangedObjects] count] ? 0.0f : 1.0f;
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreDomainsComing
{
    [allServices addObject:netService];
    [netService setDelegate:self];
    [netService resolveWithTimeout:30.0f];
}

- (void)netServiceDidResolveAddress:(NSNetService *)netService
{
    [pickerContent addObject:[[MGDataSource alloc] initWithService:netService]];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreDomainsComing
{
    for(MGDataSource * source in [pickerContent arrangedObjects])
        if([source isDiscovered] && [[source netService] isEqualTo:netService])
            [pickerContent removeObject:source];
}

- (void)updateTime:(NSTimer *)timer
{
    for(id<MGSegmentSubview> subview in [segmentCollectionView content])
    {
        [subview tick];
    }
    
    [segmentCollectionView setNeedsDisplay:YES];
    
    /*if([[MGEditingController sharedInstance] isEditing])
    {
        for(int i = 0; i < [[pickerContent arrangedObjects] count]; i++)
        {
            [[(MGPickerItemView *)[[pickerCollectionView itemAtIndex:i] view] fakeItem] tick];
        }
        
        [pickerCollectionView setNeedsDisplay:YES];
    }*/
}

- (void)deleteSelected
{
    NSIndexSet * selected = [segmentCollectionView selectionIndexes];
    
    if([selected count] > 0)
    {
        [content removeObjectAtArrangedObjectIndex:[selected firstIndex]];
        [content insertObject:[[MGBlankView alloc] init] atArrangedObjectIndex:[selected firstIndex]];
        [segmentCollectionView setSelectionIndexes:[[NSIndexSet alloc] init]];
    }
}

- (IBAction)addCustomSource:(id)sender
{
    [[customSourceURI layer] setOpacity:0.0f];
    [[pickerCollectionView window] makeFirstResponder:pickerCollectionView];
    [[topInstructions layer] setOpacity:1.0f];
    [[bottomInstructions layer] setOpacity:1.0f];
    
    [pickerContent addObject:[[MGDataSource alloc] initWithURL:[NSURL URLWithString:[customSourceURI stringValue]]]];
}

- (IBAction)showAddCustomSource:(id)sender
{
    [customSourceURI setStringValue:@""];
    [[customSourceURI window] makeFirstResponder:customSourceURI];
    [[customSourceURI layer] setOpacity:1.0f];
    [[topInstructions layer] setOpacity:0.0f];
    [[bottomInstructions layer] setOpacity:0.0f];
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
                [segmentCollectionView setSelectionIndexes:[[NSIndexSet alloc] init]];
            }
            else
            {
                [content removeObject:toObj];
                [content removeObject:fromObj];
                [content insertObject:toObj atArrangedObjectIndex:fromIndex];
                [content insertObject:fromObj atArrangedObjectIndex:toIndex];
                [segmentCollectionView setSelectionIndexes:[[NSIndexSet alloc] init]];
            }
        }
        else
        {
            pboardData = [pboard dataForType:MGPickerDragType];
            
            if(!pboardData)
                return NO;
            
            MGDataSource * dataSource = [NSKeyedUnarchiver unarchiveObjectWithData:pboardData];
            
            NSObject * toObj = [[content arrangedObjects] objectAtIndex:toIndex];
            id<MGSegmentSubview> newObj = [dataSource createSegmentSubview];
            [content removeObject:toObj];
            [content insertObject:newObj atArrangedObjectIndex:toIndex];
            [segmentCollectionView setSelectionIndexes:[[NSIndexSet alloc] init]];
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
    else
    {
        return NSDragOperationNone;
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
        NSData * data = [NSKeyedArchiver archivedDataWithRootObject:[picked child]];
        
        [pasteboard declareTypes:[NSArray arrayWithObject:MGPickerDragType] owner:self];
        [pasteboard setData:data forType:MGPickerDragType];
    }
    
    return YES;
}

@end
