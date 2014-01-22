//
//  HideTabBarViewController.m
//  Presentice
//
//  Created by レー フックダイ on 1/22/14.
//  Copyright (c) 2014 Presentice. All rights reserved.
//

#import "HideTabBarViewController.h"

@interface HideTabBarViewController ()

@end

@implementation HideTabBarViewController {
#pragma hide tab bar
    CGFloat startContentOffset;
    CGFloat lastContentOffset;
    BOOL hidden;
}

#define hideScrollWhenObjectsCount (5)
#define trackingThreshold (20)

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
#pragma hide tab bar
        hidden = NO;
    }
    return self;
}

#pragma hide tab bar
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:hidden animated:YES];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tabBarController setTabBarHidden:hidden animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.tabBarController setTabBarHidden:NO animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

-(void)expand {
    if(hidden)
        return;
    hidden = YES;
    [self.tabBarController setTabBarHidden:YES animated:YES];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

-(void)contract {
    if(!hidden)
        return;
    hidden = NO;
    [self.tabBarController setTabBarHidden:NO animated:YES];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    startContentOffset = lastContentOffset = scrollView.contentOffset.y;
    //NSLog(@"scrollViewWillBeginDragging: %f", scrollView.contentOffset.y);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.objects.count > hideScrollWhenObjectsCount) {
        CGFloat currentOffset = scrollView.contentOffset.y;
        CGFloat differenceFromStart = startContentOffset - currentOffset;
        CGFloat differenceFromLast = lastContentOffset - currentOffset;
        lastContentOffset = currentOffset;
        if((differenceFromStart) < 0) {
            // scroll up
            if(scrollView.isTracking && (abs(differenceFromLast)>trackingThreshold))
                [self expand];
        }
        else {
            if(scrollView.isTracking && (abs(differenceFromLast)>trackingThreshold))
                [self contract];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    [self contract];
    return YES;
}



@end
