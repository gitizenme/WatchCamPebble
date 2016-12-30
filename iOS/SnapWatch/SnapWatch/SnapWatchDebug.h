//
//  SnapWatchDebug.h
//  SnapWatch
//
//  Created by Joe Chavez on 7/28/13.
//  Copyright (c) 2013 izen.me. All rights reserved.
//


#ifdef DEBUG
    #define DebugLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
    #define DebugLog(...) do { } while (0)
#endif

