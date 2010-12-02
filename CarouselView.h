#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol CarouselViewDelegate;

@interface CarouselView : UIView {
    @private
    CGFloat itemWidth;
    CGFloat minX;
    CGFloat maxX;
    CGFloat viewportStride;
    
    NSInteger numberOfItems;
    NSInteger numberOfVisibleItems;
    NSInteger numberOfItemsOnEachSide;
    
    NSInteger currentItemIndex;
    
    BOOL isInitialized;
    
    CGFloat dragDistance;
    BOOL isDragging;
    
    BOOL isAnimating;
}

@property (readwrite,nonatomic,assign) IBOutlet id<CarouselViewDelegate> delegate; // weak reference
    
@property (readonly,nonatomic) UIView* currentItem;
@property (readonly,nonatomic) NSInteger currentItemIndex;

- (void) reloadItems;
- (void) showItemAtIndex:(NSInteger)index;

@end


@protocol CarouselViewDelegate <NSObject>

// TODO: move these to data source protocol
- (NSInteger) numberOfItemsInCarouselView:(CarouselView*)carouselView;
- (CGFloat) widthOfItemsInCarouselView:(CarouselView*)carouselView;
- (UIView*) carouselView:(CarouselView*)carouselView viewForItemAtIndex:(NSInteger)index reusingView:(UIView*)culledView;

@optional

- (void) carouselView:(CarouselView*)carouselView didFinishAnimatingToIndex:(NSInteger)index;

@end
