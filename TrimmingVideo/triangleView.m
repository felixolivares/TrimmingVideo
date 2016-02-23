//
//  triangleView.m
//  TrimmingVideo
//
//  Created by Jose Felix Olivares Estrada on 2/22/16.
//  Copyright © 2016 Jose Felix Olivares Estrada. All rights reserved.
//

#import "triangleView.h"

@implementation triangleView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint   (ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));  // top left
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMidY(rect));  // mid right
    CGContextAddLineToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect));  // bottom left
    CGContextClosePath(ctx);
    
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    CGContextFillPath(ctx);
}


@end
