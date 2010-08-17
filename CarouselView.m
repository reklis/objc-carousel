//
//  CarouselView.m
//  CarouselTest
//
//  Created by Steven Fusco on 8/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "CarouselView.h"


@interface CarouselView(Private)

- (void) loadViewForIndex:(NSInteger)index withOffsetX:(CGFloat)offsetX reusingView:(UIView*)culledView;

- (NSInteger) leftOfIndex:(NSInteger)index step:(NSInteger)i;
- (NSInteger) rightOfIndex:(NSInteger)index step:(NSInteger)i;

- (void) beginDraggingAtPoint:(CGPoint)startPoint;
- (void) moveItems:(CGFloat)distance;
- (void) endDraggingAtPoint:(CGPoint)endPoint;
- (void) animateSnapToCenter:(CGFloat)distance;
- (void) animateSnapBack:(CGFloat)distance;

- (void) notifyDelegateCurrentItemChanged;

@end


@implementation CarouselView

@synthesize delegate;

#pragma mark Item Management

- (void)drawRect:(CGRect)rect
{
    if (!isInitialized) {
        [self reloadItems];
        isInitialized = YES;
    }
}

- (void) reloadItems
{
    numberOfItems = [delegate numberOfItemsInCarouselView:self];
    
    if (numberOfItems == 0) {
        return;
    }
    
    itemWidth = [delegate widthOfItemsInCarouselView:self];
    
    CGRect visibleRect = self.frame;
    //CGFloat visibleHeight = CGRectGetHeight(visibleRect);
    CGFloat visibleWidth = CGRectGetWidth(visibleRect);
    
    // load the visible items to the left and right
    // load 1 more on each end offscreen
	numberOfVisibleItems = visibleWidth / itemWidth;
    CGFloat contentWidth = visibleWidth + (itemWidth * 2);
    
    // reset page state
    numberOfItemsOnEachSide = contentWidth / itemWidth / 2;
    currentItemIndex = 0;
    
    [self showItemAtIndex:currentItemIndex];    
    
    [self setNeedsDisplay];
}

- (void) showItemAtIndex:(NSInteger)index
{
    if (numberOfVisibleItems == 0) {
        return;
    }
    
    CGFloat midpoint = self.center.x;
    CGFloat offsetX = midpoint;
    
    // load current item
    [self loadViewForIndex:index withOffsetX:offsetX reusingView:nil];
    
    // load side items
    for (int i=1; i < numberOfItemsOnEachSide; ++i) {
        int leftIndex = [self leftOfIndex:currentItemIndex step:i];
        
        offsetX = (-i * itemWidth) + midpoint;
        [self loadViewForIndex:leftIndex withOffsetX:offsetX reusingView:nil];
        
        int rightIndex = [self rightOfIndex:currentItemIndex step:i];
        
        offsetX = (i * itemWidth) + midpoint;
        [self loadViewForIndex:rightIndex withOffsetX:offsetX reusingView:nil];        
    }
}

- (NSInteger) leftOfIndex:(NSInteger)index step:(NSInteger)stepping
{
    int leftIndex = index;
    for (char i = 0; i < stepping; ++i) {
        if (--leftIndex < 0) {
            leftIndex = numberOfItems - 1;
        }
    }
    NSAssert(leftIndex < numberOfItems && leftIndex >= 0, @"index out of bounds");
    return leftIndex;
}

- (NSInteger) rightOfIndex:(NSInteger)index step:(NSInteger)stepping
{
    int rightIndex = index;
    for (char i = 0; i < stepping; ++i) {
        if (++rightIndex >= numberOfItems) {
            rightIndex = 0;
        }
    }
    NSAssert(rightIndex < numberOfItems && rightIndex >= 0, @"index out of bounds");
    return rightIndex;
}

- (void) loadViewForIndex:(NSInteger)index withOffsetX:(CGFloat)offsetX reusingView:(UIView*)culledView
{
    UIView* v = [self.delegate carouselView:self viewForItemAtIndex:index reusingView:culledView];
    
    v.center = CGPointMake(offsetX, v.center.y);
    
    if (nil == v.superview) {
        [self addSubview:v];
    }
}


@synthesize currentItemIndex;

- (UIView*) currentItem
{
    CGFloat midpoint = CGRectGetMidX(self.frame);
    UIView* closestViewToMidpoint = nil;
    
    for (UIView* v in [self subviews]) {
        if (
            (closestViewToMidpoint == nil) 
            ||
            (abs(v.center.x - midpoint) < abs(closestViewToMidpoint.center.x - midpoint))
        )
        {
            closestViewToMidpoint = v;
        }
        
    }
    
    return closestViewToMidpoint;
}

#pragma mark Dragging

- (void) beginDraggingAtPoint:(CGPoint)startPoint
{
    isDragging = YES;
    dragDistance = 0.0;
}

- (void) moveItems:(CGFloat)distance
{
    if (distance == 0) {
        return;
    }
        
    for (UIView* v in [self subviews]) {
        CGFloat x = v.center.x - distance;
        v.center = CGPointMake(x, v.center.y);
        
        if (isDragging) {
            CGFloat maxX = CGRectGetMaxX(self.frame);
            CGFloat minX = CGRectGetMinX(self.frame);
            
            // use the distance sign bit to check direction of the move, preventing flickering of edge views
            if (distance < 0) {
                
                if (x > maxX) {
                    int leftIndex = [self leftOfIndex:currentItemIndex step:(-dragDistance / itemWidth) + numberOfItemsOnEachSide];
                    CGFloat offsetX = x - (itemWidth * ((numberOfItemsOnEachSide * 2) - 1));
                    
                    [self loadViewForIndex:leftIndex withOffsetX:offsetX reusingView:v];
                }
            } else {
                if (x < minX) {
                    int rightIndex = [self rightOfIndex:currentItemIndex step:(dragDistance / itemWidth) + numberOfItemsOnEachSide];
                    CGFloat offsetX = x + (itemWidth * ((numberOfItemsOnEachSide * 2) - 1));
                    //int stepping = (offsetX - x) / itemWidth;
                    //int rightIndex = [self rightOfIndex:currentItemIndex step:numberOfItemsOnEachSide];
                    //currentItemIndex = [self rightOfIndex:currentItemIndex step:1];
                    
                    [self loadViewForIndex:rightIndex withOffsetX:offsetX reusingView:v];
                }
            }
        }
    }
}

- (void) endDraggingAtPoint:(CGPoint)endPoint
{
    CGFloat d = dragDistance;
    
    isDragging = NO;
    
    CGFloat integral = CGFLOAT_MAX;
    CGFloat fractional = modff(d / itemWidth, &integral);
    
    if (integral == 0.0 && fractional == 0.0) {
        // aligned, nothing to do
        return;
    }
    
    if (integral != 0.0) {
        
        // update the current item index appropriately
        if (integral < 0) {
            currentItemIndex = [self leftOfIndex:currentItemIndex step:-integral];
        } else {
            currentItemIndex = [self rightOfIndex:currentItemIndex step:integral];
        }

        if (fractional != 0.0) {
            NSLog(@"animateSnapToCenter");
            // animate to appropriate center, notify when animation is complete
            CGFloat offsetX = -fractional * itemWidth;
            [self animateSnapToCenter:offsetX];
        } else {
            NSLog(@"no animation");
            // nothing to animate, but we should still notify
            [self notifyDelegateCurrentItemChanged];
        }

    } else {
        // animate back, notify when animation is complete
        NSLog(@"animateSnapBack");
        [self animateSnapBack:d];
    }
    
}

#pragma mark Animation

- (void) animateSnapToCenter:(CGFloat)distance
{
    [UIView beginAnimations:@"snaptocenterpoint" context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:.25];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationWillStartSelector:@selector(animationWillStart)];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    
    [self moveItems:distance];
    
    [UIView commitAnimations];
}

- (void) animateSnapBack:(CGFloat)distance
{
    [UIView beginAnimations:@"snapback" context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView setAnimationDuration:0.15];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationWillStartSelector:@selector(animationWillStart)];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    
    [self moveItems:-distance];
    
    [UIView commitAnimations];
}

- (void) animationWillStart:(NSString *)animationID context:(void *)context
{
    isAnimating = YES;
}

- (void) animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [self notifyDelegateCurrentItemChanged];
    
    
    for (UIView* v in [self subviews]) {
        CGFloat x = v.center.x;
        
        CGFloat maxX = CGRectGetMaxX(self.frame);
        CGFloat minX = CGRectGetMinX(self.frame);
        
        if (x > maxX) {
            int leftIndex = [self leftOfIndex:currentItemIndex step:numberOfItemsOnEachSide-1];
            CGFloat offsetX = x - (itemWidth * ((numberOfItemsOnEachSide * 2) - 1));
            
            [self loadViewForIndex:leftIndex withOffsetX:offsetX reusingView:v];
        }
        
        if (x < minX) {
            int rightIndex = [self rightOfIndex:currentItemIndex step:numberOfItemsOnEachSide-1];
            CGFloat offsetX = x + (itemWidth * ((numberOfItemsOnEachSide * 2) - 1));
            
            [self loadViewForIndex:rightIndex withOffsetX:offsetX reusingView:v];
        }
    }
    
    isAnimating = NO;
    

}

- (void) notifyDelegateCurrentItemChanged
{
    if ([delegate respondsToSelector:@selector(carouselView:didFinishAnimatingToIndex:)]) {
        [delegate carouselView:self didFinishAnimatingToIndex:currentItemIndex];
    }
}

#pragma mark UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (isAnimating) {
        return;
    }
    
    UITouch* t = [touches anyObject];
    CGPoint p = [t locationInView:self];
    
    [self beginDraggingAtPoint:p];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (isAnimating) {
        return;
    }
    
    UITouch* t = [touches anyObject];
    CGPoint p1 = [t locationInView:self];
    
    if (!isDragging) {
        NSLog(@"drag state compromised by animation, compensating");
        [self beginDraggingAtPoint:p1]; // race condition, it's possible that the touch began while still animating
    }
    
    CGPoint p2 = [t previousLocationInView:self];
    CGFloat d = p2.x - p1.x;
    
    // accumulate movement into dragDistance
    dragDistance = dragDistance + d;
    
    [self moveItems:d];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (isAnimating) {
        return;
    }
    
    UITouch* t = [touches anyObject];
    CGPoint p = [t locationInView:self];
    
    [self endDraggingAtPoint:p];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (isAnimating) {
        return;
    }
    
    [self animateSnapBack:-dragDistance];
    
    dragDistance = 0.0;
    isDragging = NO;
}

@end

