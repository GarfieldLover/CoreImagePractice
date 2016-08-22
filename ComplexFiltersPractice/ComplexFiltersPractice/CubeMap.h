//
//  CubeMap.h
//  ComplexFiltersPractice
//
//  Created by ZK on 16/8/22.
//  Copyright © 2016年 ZK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CubeMap : NSObject

@property (assign) int length;
@property (assign) float dimension;
@property (assign) float *data;

+(CubeMap*)createCubeMap:(float)minHueAngle maxHueAngle:(float)maxHueAngle;

@end
