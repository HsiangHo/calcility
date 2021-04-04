//
//  MathRoot.m
//  iCalculator
//
//  Created by curie on 3/31/14.
//  Copyright (c) 2014 Fish Tribe. All rights reserved.
//

#import "MathRoot.h"


@implementation MathRoot

- (id)initWithIndex:(MathExpression *)index radicand:(MathExpression *)radicand
{
    FTAssert(index && radicand);
    self = [super initWithLeftAffinity:MathNonAffinity rightAffinity:MathNonAffinity];
    if (self) {
        _subexpressions = @[index, radicand];
    }
    return self;
}

- (MathExpression *)index
{
    return _subexpressions[0];
}

- (MathExpression *)radicand
{
    return _subexpressions[1];
}

- (NSUInteger)barrier
{
    return 1;
}

- (MathResult *)operate
{
    MathResult *index = [self.index evaluate];
    if (index == nil) return nil;
    decQuad indexValue = index.value;
    MathResult *radicand = [self.radicand evaluate];
    if (radicand == nil) return nil;
    decQuad radicandValue = radicand.value;
    double _radicandValue = IEEE754_dec2bin(&radicandValue);
    double _resultValue;
    decQuad tmpDec;
    do {
        decQuadCompare(&tmpDec, &indexValue, &Dec_2, &DQ_set);
        if (decQuadIsZero(&tmpDec)) {
            _resultValue = sqrt(_radicandValue);
            break;
        }
        
        decQuadCompare(&tmpDec, &indexValue, &Dec_3, &DQ_set);
        if (decQuadIsZero(&tmpDec)) {
            _resultValue = cbrt(_radicandValue);
            break;
        }
        
        /* default: */ {
            double _indexValue = IEEE754_dec2bin(&indexValue);
            _resultValue = pow(_radicandValue, 1.0 / _indexValue);
        }
    } while (0);
    decQuad resultValue;
    IEEE754_bin2dec(_resultValue, &resultValue);
    return [[MathResult alloc] initWithValue:resultValue unitSet:[radicand.unitSet unitSetByRaisingToPowerReciprocal:indexValue]];
}

- (CGFloat)fontSizeOfSubexpressionAtIndex:(NSUInteger)subexpressionIndex whenDrawWithContext:(MathDrawingContext *)context
{
    FTAssert(context);
    switch (subexpressionIndex) {
        case 0: {
            return MAX(3.0, context.fontSize * (2.0 / 3.0));
        }
        default: {
            FTAssert(subexpressionIndex == 1);
            return context.fontSize;
        }
    }
}

#define STANDARD_HOOK_ANGLE         (65.0 * M_PI / 180.0)
#define STANDARD_RAMP_ANGLE         (75.0 * M_PI / 180.0)
#define LINE_WIDTH_RATIO            (1.0 / 20.0)
#define RADICAND_TOP_MARGIN_RATIO   (LINE_WIDTH_RATIO * 1.5)
#define RADICAND_LEFT_MARGIN_RATIO  (1.0 / 6.0)
#define RADICAND_RIGHT_MARGIN_RATIO (1.0 / 5.0)
#define HEIGHT_WEIGHTING_RATIO      (1.0 / 2.0)
#define HOOK_BAR_LENGTH_RATIO       (5.0 / 10.0)
#define HOOK_SERIF_WIDTH_RATIO      (3.0 / 4.0)
#define HOOK_SERIF_LENGTH_RATIO     (1.0 / 4.0)

- (CGPoint)originOfSubexpressionAtIndex:(NSUInteger)subexpressionIndex whenDrawWithContext:(MathDrawingContext *)context
{
    FTAssert(context);
    CGFloat radicandFontSize = [self fontSizeOfSubexpressionAtIndex:1 whenDrawWithContext:context];
    CGRect radicandRect = [self.radicand rectWhenDrawAtPoint:CGPointZero withFontSize:radicandFontSize];
    CGFloat radicandTopMargin = radicandFontSize * RADICAND_TOP_MARGIN_RATIO;
    CGFloat radicandLeftMargin = radicandFontSize * RADICAND_LEFT_MARGIN_RATIO;
    UIFont *radicandFont = [MathDrawingContext primaryFontWithSize:radicandFontSize];
    CGFloat radicandFontHeight = radicandFont.ascender - radicandFont.descender;
    CGFloat radicandHeight = CGRectGetHeight(radicandRect);
    CGFloat weightedRadicandFontHeight = radicandFontHeight + (radicandHeight - radicandFontHeight) * HEIGHT_WEIGHTING_RATIO;
    CGFloat hookBarLength = weightedRadicandFontHeight * HOOK_BAR_LENGTH_RATIO;
    CGFloat lineWidth = context.fontSize * LINE_WIDTH_RATIO;
    CGFloat hookSerifWidth = lineWidth * HOOK_SERIF_WIDTH_RATIO;
    CGFloat hookSerifLength = hookBarLength * HOOK_SERIF_LENGTH_RATIO;
    CGFloat hookSpan = (hookBarLength + hookSerifWidth / 2.0) * cos(STANDARD_HOOK_ANGLE) + hookSerifLength * sin(STANDARD_HOOK_ANGLE);
    CGFloat rampSpan = (weightedRadicandFontHeight + radicandTopMargin) / tan(STANDARD_RAMP_ANGLE);

    CGFloat indexFontSize = [self fontSizeOfSubexpressionAtIndex:0 whenDrawWithContext:context];
    CGRect indexRect = [self.index rectWhenDrawAtPoint:CGPointZero withFontSize:indexFontSize];
    CGFloat indexWidthToTheLeftOfJoint = CGRectGetWidth(indexRect) - indexFontSize / 10.0;
    
    switch (subexpressionIndex) {
        case 0: {
            UIFont *indexFont = [MathDrawingContext primaryFontWithSize:indexFontSize];
            return CGPointMake(context.origin.x + MAX(0.0, ceil(hookSpan - indexWidthToTheLeftOfJoint)), context.origin.y + CGRectGetMinY(radicandRect) - round(radicandTopMargin - indexFont.capHeight + indexFont.descender) - CGRectGetMaxY(indexRect));
        }
        default: {
            FTAssert(subexpressionIndex == 1);
            return CGPointMake(context.origin.x + ceil(MAX(hookSpan, indexWidthToTheLeftOfJoint) + rampSpan + radicandLeftMargin), context.origin.y);
        }
    }
}

- (CGRect)rectWhenDrawWithContext:(MathDrawingContext *)context
{
    FTAssert(context);
    CGPoint indexOrigin = [self originOfSubexpressionAtIndex:0 whenDrawWithContext:context];
    CGPoint radicandOrigin = [self originOfSubexpressionAtIndex:1 whenDrawWithContext:context];
    CGFloat indexFontSize = [self fontSizeOfSubexpressionAtIndex:0 whenDrawWithContext:context];
    CGFloat radicandFontSize = [self fontSizeOfSubexpressionAtIndex:1 whenDrawWithContext:context];
    CGRect indexRect = [self.index rectWhenDrawAtPoint:indexOrigin withFontSize:indexFontSize];
    CGRect radicandRect = [self.radicand rectWhenDrawAtPoint:radicandOrigin withFontSize:radicandFontSize];
    
    CGFloat radicandTopMargin = radicandFontSize * RADICAND_TOP_MARGIN_RATIO;
    CGFloat radicandLeftMargin = radicandFontSize * RADICAND_LEFT_MARGIN_RATIO;
    CGFloat radicandRightMargin = radicandFontSize * RADICAND_RIGHT_MARGIN_RATIO;
    UIFont *radicandFont = [MathDrawingContext primaryFontWithSize:radicandFontSize];
    CGFloat radicandFontHeight = radicandFont.ascender - radicandFont.descender;
    CGFloat radicandHeight = CGRectGetHeight(radicandRect);
    CGFloat weightedRadicandFontHeight = radicandFontHeight + (radicandHeight - radicandFontHeight) * HEIGHT_WEIGHTING_RATIO;
    CGFloat hookBarLength = weightedRadicandFontHeight * HOOK_BAR_LENGTH_RATIO;
    CGFloat lineWidth = context.fontSize * LINE_WIDTH_RATIO;
    CGFloat hookSerifWidth = lineWidth * HOOK_SERIF_WIDTH_RATIO;
    CGFloat hookSerifLength = hookBarLength * HOOK_SERIF_LENGTH_RATIO;
    CGFloat hookSpan = (hookBarLength + hookSerifWidth / 2.0) * cos(STANDARD_HOOK_ANGLE) + hookSerifLength * sin(STANDARD_HOOK_ANGLE);
    CGFloat rampSpan = (weightedRadicandFontHeight + radicandTopMargin) / tan(STANDARD_RAMP_ANGLE);
    return CGRectUnion(indexRect, my_UIEdgeInsetsOutsetRect(radicandRect, UIEdgeInsetsMake(ceil(lineWidth + radicandTopMargin), ceil(hookSpan + rampSpan + radicandLeftMargin), ceil(lineWidth), ceil(radicandRightMargin + lineWidth))));
}

- (CGRect)drawWithContext:(MathDrawingContext *)context
{
    FTAssert(context);
    CGPoint indexOrigin = [self originOfSubexpressionAtIndex:0 whenDrawWithContext:context];
    CGPoint radicandOrigin = [self originOfSubexpressionAtIndex:1 whenDrawWithContext:context];
    CGFloat indexFontSize = [self fontSizeOfSubexpressionAtIndex:0 whenDrawWithContext:context];
    CGFloat radicandFontSize = [self fontSizeOfSubexpressionAtIndex:1 whenDrawWithContext:context];
    CGRect indexRect = [self.index drawAtPoint:indexOrigin withFontSize:indexFontSize];
    CGRect radicandRect = [self.radicand drawAtPoint:radicandOrigin withFontSize:radicandFontSize];
    
    CGFloat radicandTopMargin = radicandFontSize * RADICAND_TOP_MARGIN_RATIO;
    CGFloat radicandLeftMargin = radicandFontSize * RADICAND_LEFT_MARGIN_RATIO;
    CGFloat radicandRightMargin = radicandFontSize * RADICAND_RIGHT_MARGIN_RATIO;
    UIFont *radicandFont = [MathDrawingContext primaryFontWithSize:radicandFontSize];
    CGFloat radicandFontHeight = radicandFont.ascender - radicandFont.descender;
    CGFloat radicandHeight = CGRectGetHeight(radicandRect);
    CGFloat weightedRadicandFontHeight = radicandFontHeight + (radicandHeight - radicandFontHeight) * HEIGHT_WEIGHTING_RATIO;
    CGFloat hookBarLength = weightedRadicandFontHeight * HOOK_BAR_LENGTH_RATIO;
    CGFloat lineWidth = context.fontSize * LINE_WIDTH_RATIO;
    CGFloat hookSerifWidth = lineWidth * HOOK_SERIF_WIDTH_RATIO;
    CGFloat hookSerifLength = hookBarLength * HOOK_SERIF_LENGTH_RATIO;
    CGFloat hookSpan = (hookBarLength + hookSerifWidth / 2.0) * cos(STANDARD_HOOK_ANGLE) + hookSerifLength * sin(STANDARD_HOOK_ANGLE);
    CGFloat rampSpan = (weightedRadicandFontHeight + radicandTopMargin) / tan(STANDARD_RAMP_ANGLE);
    CGFloat rampHeight = radicandHeight + radicandTopMargin;
    CGFloat realRampAngle;
    CGFloat hookSideBarIndent;
    if (radicandHeight != weightedRadicandFontHeight) {
        realRampAngle = atan(rampHeight / rampSpan);
        hookSideBarIndent = hookSerifWidth * tan(M_PI_2 - M_PI + STANDARD_HOOK_ANGLE + realRampAngle);
    }
    else {
        //$ realRampAngle = STANDARD_RAMP_ANGLE;
        hookSideBarIndent = hookSerifWidth / tan(M_PI - STANDARD_HOOK_ANGLE - STANDARD_RAMP_ANGLE);
    }
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, CGRectGetMinX(radicandRect) - radicandLeftMargin - rampSpan, CGRectGetMaxY(radicandRect));
    CGContextRotateCTM(ctx, -(M_PI_2 - STANDARD_HOOK_ANGLE));
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, hookSerifWidth, -hookSideBarIndent);
    CGContextAddLineToPoint(ctx, hookSerifWidth, -hookBarLength);
    CGContextAddLineToPoint(ctx, -hookSerifLength, -hookBarLength);
    CGContextSetLineWidth(ctx, hookSerifWidth);
    CGContextStrokePath(ctx);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, 0.0, -hookBarLength);
    CGContextAddLineToPoint(ctx, 0.0, 0.0);
    CGContextRotateCTM(ctx, M_PI_2 - STANDARD_HOOK_ANGLE);
    CGContextAddLineToPoint(ctx, rampSpan, -rampHeight);
    CGContextAddLineToPoint(ctx, rampSpan + radicandLeftMargin + CGRectGetWidth(radicandRect) + radicandRightMargin, -rampHeight);
    CGContextSetLineWidth(ctx, lineWidth);
    CGContextSetLineJoin(ctx, kCGLineJoinBevel);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);
    return CGRectUnion(indexRect, my_UIEdgeInsetsOutsetRect(radicandRect, UIEdgeInsetsMake(ceil(lineWidth + radicandTopMargin), ceil(hookSpan + rampSpan + radicandLeftMargin), ceil(lineWidth), ceil(radicandRightMargin + lineWidth))));
}

@end