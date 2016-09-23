//
//  RXRLogging.h
//  Rexxar
//
//  Created by Tony Li on 12/18/15.
//  Copyright © 2015 Douban.Inc. All rights reserved.
//

#ifdef DEBUG
#define RXRLog(...) NSLog(@"[Rexxar] " __VA_ARGS__)
#else /* DEBUG */
#define RXRLog(...)
#endif /* DEBUG */

#define RXRDebugLog(...)  RXRLog(@"[DEBUG] " __VA_ARGS__)
#define RXRWarnLog(...)   RXRLog(@"[WARN] " __VA_ARGS__)
#define RXRErrorLog(...)  RXRLog(@"[ERROR] " __VA_ARGS__)
