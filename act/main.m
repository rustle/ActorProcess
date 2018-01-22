//
//  main.m
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "act-Swift.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        [[Agent shared] resume];
        dispatch_main();
    }
    return EXIT_SUCCESS;
}
