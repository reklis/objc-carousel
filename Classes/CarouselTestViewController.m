//
//  CarouselTestViewController.m
//  CarouselTest
//
//  Created by Steven Fusco on 8/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "CarouselTestViewController.h"

@implementation CarouselTestViewController



/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


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
