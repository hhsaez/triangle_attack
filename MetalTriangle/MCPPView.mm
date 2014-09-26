//
//  MCPPView.m
//  MetalTriangle
//
//  Created by Hernan Saez on 9/26/14.
//  Copyright (c) 2014 Hernan Saez. All rights reserved.
//

#import "MCPPView.h"

#import <QuartzCore/CAMetalLayer.h>

@implementation MCPPView

+ (Class)layerClass
{
    return [CAMetalLayer class];
}

@end
