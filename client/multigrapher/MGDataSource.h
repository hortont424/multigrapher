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

#import <Foundation/Foundation.h>

#import "MGSegmentSubview.h"

@interface MGDataSource : NSObject<NSCoding>
{
    bool isResolved;
    bool isDiscovered;
    NSString * type;
    NSString * shortName, * longName;
    NSURL * url;
    NSString * uuid;
    NSNetService * netService;
}

@property (nonatomic, assign) bool isResolved;
@property (nonatomic, assign) bool isDiscovered;
@property (nonatomic, copy) NSString * type;
@property (nonatomic, copy) NSString * shortName;
@property (nonatomic, copy) NSString * longName;
@property (nonatomic, copy) NSURL * url;
@property (nonatomic, copy) NSString * uuid;
@property (nonatomic, assign) NSNetService * netService;

- (id)initWithService:(NSNetService *)service;
- (id)initWithURL:(NSURL *)inURL;
- (id)initWithUUID:(NSString *)inUUID;

-(id)initWithCoder:(NSCoder*)coder;
-(void)encodeWithCoder:(NSCoder*)coder;

- (void)parseHeader;
- (NSString *)loadData;
- (id<MGSegmentSubview>)createSegmentSubview;

@end
