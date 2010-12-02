#import "CarouselTestViewController.h"

@implementation CarouselTestViewController

#pragma mark CarouselViewDelegate

- (NSInteger) numberOfItemsInCarouselView:(CarouselView*)carouselView
{
    return 5;
}

- (CGFloat) widthOfItemsInCarouselView:(CarouselView*)carouselView
{
    return 50;
}

- (UIView*) carouselView:(CarouselView*)carouselView viewForItemAtIndex:(NSInteger)index reusingView:(UIView*)culledView
{
    UIImage* i = [UIImage imageNamed:[NSString stringWithFormat:@"%d.png", index+1]];
    UIImageView* iv = (UIImageView*)culledView;
    
    if (iv == nil) {
        iv = [[[UIImageView alloc] initWithImage:i] autorelease];
    } else {
        [iv setImage:i];
    }
    
    return iv;
}

- (void) carouselView:(CarouselView*)carouselView didFinishAnimatingToIndex:(NSInteger)index
{
    NSLog(@"%d", index);
}

@end
