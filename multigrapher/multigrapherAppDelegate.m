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
#import "MGGraphView.h"
#import "MGCenterView.h"
#import "MGTextView.h"
#import "MGEditingController.h"

@implementation multigrapherAppDelegate

@synthesize window, segmentCollectionView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[MGEditingController sharedInstance] setRootView:[window contentView]];

    [window setLevel:NSFloatingWindowLevel];
    SetSystemUIMode(kUIModeAllHidden, 0);
    
    content = [[NSArrayController alloc] init];
    [segmentCollectionView bind:@"content" toObject:content withKeyPath:@"arrangedObjects" options:nil];

    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];

    [content addObject:[[MGGraphView alloc] initWithURL:[NSURL URLWithString:@"http://localhost/~hortont/sin.csv"]]];
    [content addObject:[[MGGraphView alloc] initWithURL:[NSURL URLWithString:@"http://localhost/~hortont/sinover.csv"]]];
    [content addObject:[[MGGraphView alloc] initWithURL:[NSURL URLWithString:@"http://localhost/~hortont/weird.csv"]]];
    [content addObject:[[MGGraphView alloc] initWithURL:[NSURL URLWithString:@"http://localhost/~hortont/aapl.csv"]]];
    [content addObject:[[MGCenterView alloc] init]];
    [content addObject:[[MGGraphView alloc] initWithURL:[NSURL URLWithString:@"http://localhost/~hortont/btv-temp.csv"]]];
    [content addObject:[[MGTextView alloc] initWithURL:[NSURL URLWithString:@"http://localhost/~hortont/points.txt"]]];
    [content addObject:[[MGGraphView alloc] initWithURL:[NSURL URLWithString:@"http://localhost/~hortont/btv-temp.csv"]]];
    [content addObject:[[MGGraphView alloc] initWithURL:[NSURL URLWithString:@"http://localhost/~hortont/btv-temp.csv"]]];

    [[MGEditingController sharedInstance] setIsEditing:NO];
    [segmentCollectionView setDelegate:self];
    [segmentCollectionView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
    [segmentCollectionView registerForDraggedTypes:[NSArray arrayWithObject:MGSegmentDragType]];

    [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
}

- (void)updateTime:(NSTimer *)timer
{
    [segmentCollectionView setNeedsDisplay:YES];
}

-(BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id < NSDraggingInfo >)draggingInfo index:(NSInteger)toIndex dropOperation:(NSCollectionViewDropOperation)dropOperation
{
    NSPasteboard * pboard = [draggingInfo draggingPasteboard];
    NSData * indexData = [pboard dataForType:MGSegmentDragType];
    NSInteger fromIndex = [[NSKeyedUnarchiver unarchiveObjectWithData:indexData] firstIndex];
	
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
    
    return YES;
}

-(NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id < NSDraggingInfo >)draggingInfo proposedIndex:(NSInteger *)proposedDropIndex dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation
{
    if(((*proposedDropIndex) == 4) || (*proposedDropOperation == NSCollectionViewDropBefore))
    {
        return NSDragOperationNone;
    }
    
    return NSDragOperationEvery;
}


- (BOOL)collectionView:(NSCollectionView *)cv writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pasteboard
{
    if((![[MGEditingController sharedInstance] isEditing]) || ([indexes firstIndex] == 4))
        return NO;

    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:indexes];
    
    [pasteboard declareTypes:[NSArray arrayWithObject:MGSegmentDragType] owner:self];
    [pasteboard setData:data forType:MGSegmentDragType];
    
    return YES;
}

@end
