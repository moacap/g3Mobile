//
//  MyLoginDelegate.h
//  g3Mobile
//
//  Created by David Steinberger on 3/13/11.
//  Copyright 2011 -. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol MyLoginDelegate

- (void)finishedLogin;
- (void)dispatchToRootController:(id)sender;

@end
