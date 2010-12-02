#import "CarouselView.h"


@interface CarouselView(Private)

- (void) loadViewForIndex:(NSInteger)index withOffsetX:(CGFloat)offsetX reusingView:(UIView*)culledView;

- (NSInteger) leftOfIndex:(NSInteger)index step:(NSInteger)i;
- (NSInteger) rightOfIndex:(NSInteger)index step:(NSInteger)i;

- (void) beginDragging;
- (void) moveItems:(CGFloat)distance;
- (void) endDragging;
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
    maxX = CGRectGetMaxX(self.frame);
    minX = CGRectGetMinX(self.frame);
    
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
    
    viewportStride = itemWidth * ((numberOfItemsOnEachSide * 2) - 1);
    
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
    //NSLog(@"loadViewForIndex: %d withOffsetX: %1.2f reusingView: %@", index, offsetX, culledView);
    
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

- (void) beginDragging
{
    isDragging = YES;
    dragDistance = 0.0;
}

- (void) moveItems:(CGFloat)distance
{
    // TODO: scary... fix it
    
    if (distance == 0) {
        return;
    }
    
    for (UIView* v in [self subviews]) {
        CGFloat x = v.center.x - distance;
        v.center = CGPointMake(x, v.center.y);
        
        if (isDragging) {
            
            if (distance < 0) {
                // right culling
                
                if (x > maxX) {
                    CGFloat penetration = (x-maxX);
                    CGFloat offsetX = x - viewportStride;
                    int dragDelta = (-dragDistance / itemWidth);
                    int stride = (viewportStride / itemWidth);
                    int leg = (numberOfItemsOnEachSide-1);
                    int stepping = dragDelta + stride - leg;
                    
                    if (-distance >= itemWidth) {
                        stepping -= ((int)penetration / (int)itemWidth);
                    }
                    
                    // special case for "tugging" left first then right
                    if (dragDistance > 0) {
                        stepping -= 1;
                    }
                    
                    int newIndex = [self leftOfIndex:currentItemIndex step:stepping];
                    
                    NSLog(@"RIGHT: dragDistance: %1.2f  penetration: %1.2f  offsetX: %1.2f  dragDelta: %d  stride: %d  leg: %d  stepping: %d", dragDistance, penetration, offsetX, dragDelta, stride, leg, stepping);
                    [self loadViewForIndex:newIndex withOffsetX:offsetX reusingView:v];
                } 
                
            } else {
                // left culling
                
                if (x < minX) {
                    CGFloat penetration = (minX-x);
                    CGFloat offsetX = x + viewportStride;
                    int dragDelta = (dragDistance / itemWidth);
                    int stride = (viewportStride / itemWidth);
                    int leg = (numberOfItemsOnEachSide-1);
                    int stepping = dragDelta + stride - leg;
                    
                    if (distance >= itemWidth) {
                        stepping -= ((int)penetration / (int)itemWidth);
                    }
                    
                    // special case for "tugging" right first then left
                    if (dragDistance < 0) {
                        stepping -= 1;
                    }
                    
                    int newIndex = [self rightOfIndex:currentItemIndex step:stepping];
                    
                    NSLog(@"LEFT: dragDistance: %1.2f  penetration: %1.2f  offsetX: %1.2f  dragDelta: %d  stride: %d  leg: %d  stepping: %d", dragDistance, penetration, offsetX, dragDelta, stride, leg, stepping);
                    [self loadViewForIndex:newIndex withOffsetX:offsetX reusingView:v];
                }
            }
            
        }
    }
}

- (void) endDragging
{
    CGFloat d = dragDistance;
    
    if (dragDistance == 0) {
        return;
    }
    
    isDragging = NO;
    
    CGFloat quotient = d / itemWidth;
    CGFloat integral = CGFLOAT_MAX;
    CGFloat fractional = modff(quotient, &integral);
    CGFloat roundedQuotient = roundf(quotient);
    CGFloat stepping = ceilf((quotient > 0) ? quotient : -quotient);
        
    if (roundedQuotient != 0.0) {
        NSLog(@"quotient: %1.2f  integral: %1.2f  fractional %1.2f  roundedQuotient: %1.2f  stepping: %1.2f", quotient, integral, fractional, roundedQuotient, stepping);
        // update the current item index appropriately
        if (roundedQuotient < 0) {
            currentItemIndex = [self leftOfIndex:currentItemIndex step:stepping];
        } else {
            currentItemIndex = [self rightOfIndex:currentItemIndex step:stepping];
        }

        if (fractional != 0.0) {
            // animate to appropriate center, notify when animation is complete
            CGFloat offsetX = (fractional > 0) ? ((1.0 - fractional) * itemWidth) : ((fractional + 1.0) * -itemWidth);
            NSLog(@"animateSnapToCenter %1.2f %1.2f %1.2f", integral, fractional, offsetX);
            [self animateSnapToCenter:offsetX];
        } else {
            //NSLog(@"no animation");
            // nothing to animate, but we should still notify
            [self notifyDelegateCurrentItemChanged];
        }

    } else {
        // animate back, notify when animation is complete
        //NSLog(@"animateSnapBack %1.2f %1.2f", integral, fractional);
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
    
    isAnimating = NO;
    
    
    // We need to wait until spring animation is complete before readjusting the views,
    // otherwise the views to fly across the screen during re-culling because their center property is adjusted
    
    // TODO: refactor this and movement view culling into single place
    
    for (UIView* v in [self subviews]) {
        CGFloat x = v.center.x;
            
        if (x > maxX) {
            CGFloat offsetX = x - viewportStride;
            int leg = (numberOfItemsOnEachSide-1);
            int newIndex = [self leftOfIndex:currentItemIndex step:leg];
            
            [self loadViewForIndex:newIndex withOffsetX:offsetX reusingView:v];
            
        } else if (x < minX) {
            CGFloat offsetX = x + viewportStride;
            int leg = (numberOfItemsOnEachSide-1);
            int newIndex = [self rightOfIndex:currentItemIndex step:leg];
            
            [self loadViewForIndex:newIndex withOffsetX:offsetX reusingView:v];
        }
    }

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
    
    [self beginDragging];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (isAnimating) {
        return;
    }
    
    if (!isDragging) {
        NSLog(@"drag state compromised by animation, compensating");
        [self beginDragging]; // race condition, it's possible that the touch began while still animating
    }
    
    UITouch* t = [touches anyObject];
    CGPoint p1 = [t locationInView:self];
    CGPoint p2 = [t previousLocationInView:self];
    CGFloat d = p2.x - p1.x;
    
    // accumulate horizontal movement into dragDistance
    dragDistance = dragDistance + d;
    
    [self moveItems:d];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (isAnimating) {
        return;
    }
    
    if (!isDragging) {
        return;
    }

    [self endDragging];
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

