//
//  StwRootController.h
//  Stopwatch
//
//  Created by Andrew's MAC on 2017-15-04.
//  Copyright © 2017 Andrew Chang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMCView.h"

@interface StwRootController : NSObject <AMCViewDelegate>
@property (nonatomic, assign) AMCView *view;
@end
