//
//  CarouselTestViewController.h
//  CarouselTest
//
//  Created by Steven Fusco on 8/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CarouselView.h"

@interface CarouselTestViewController : UIViewController <CarouselViewDelegate>
{
    IBOutlet CarouselView* carouselView;
}

@end

