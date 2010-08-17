//
//  CarouselTestAppDelegate.h
//  CarouselTest
//
//  Created by Steven Fusco on 8/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//


#import <UIKit/UIKit.h>

@class CarouselTestViewController;

@interface CarouselTestAppDelegate : NSObject <UIApplicationDelegate> {

    UIWindow *window;

    CarouselTestViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;


@property (nonatomic, retain) IBOutlet CarouselTestViewController *viewController;

@end

