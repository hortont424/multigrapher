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

#import <Cocoa/Cocoa.h>

#define MGSegmentDragType @"MGSegmentDragType"
#define MGPickerDragType @"MGPickerDragType"

@class MGPanel;

@interface multigrapherAppDelegate : NSObject <NSApplicationDelegate,NSCollectionViewDelegate,NSNetServiceBrowserDelegate,NSNetServiceDelegate>
{
    NSWindow * window;
    MGPanel * editWindow;
    NSCollectionView * segmentCollectionView;
    NSCollectionView * pickerCollectionView;
    NSArrayController * content;
    NSArrayController * pickerContent;
    
    NSNetServiceBrowser * browser;
    
    NSMutableArray * allServices;
}

@property (assign) IBOutlet NSWindow * window;
@property (assign) IBOutlet MGPanel * editWindow;
@property (assign) IBOutlet NSCollectionView * segmentCollectionView;
@property (assign) IBOutlet NSCollectionView * pickerCollectionView;

@property (assign) NSArrayController * content;

- (void)deleteSelected;

- (IBAction)addCustomSource:(id)sender;

@end
