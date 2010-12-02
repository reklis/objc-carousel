#import <UIKit/UIKit.h>

@class CarouselTestViewController;

@interface CarouselTestAppDelegate : NSObject <UIApplicationDelegate> {

    UIWindow *window;

    CarouselTestViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;


@property (nonatomic, retain) IBOutlet CarouselTestViewController *viewController;

@end

