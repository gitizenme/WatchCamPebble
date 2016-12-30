

#import "SnapWatchDebug.h"

#import "PebbleSnapMessageQueue.h"
#import <PebbleKit/PebbleKit.h>

@interface PebbleSnapMessageQueue () {
    NSInteger failureCount;
    bool stopMessages;
}
- (void)sendRequest;
@end

@implementation PebbleSnapMessageQueue

- (id)init
{
    self = [super init];
    if (self) {
        has_active_request = NO;
        queue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)enqueue:(NSDictionary *)message {
    DebugLog(@"BEGIN");
    if(!_watch) {
        DebugLog(@"No watch; discarding message.");
        return;
    }
    if(!message) return;
    @synchronized(queue) {
        DebugLog(@"Enqueued message: %@", message);
        [queue addObject:message];
        [self sendRequest];
    }
}


- (void)sendRequest {
    DebugLog(@"BEGIN");
    @synchronized(queue) {
        if(has_active_request) { DebugLog(@"Request in-flight; stalling."); return; }
        if([queue count] == 0) { DebugLog(@"Nothing in queue."); return; }
        if(![_watch isConnected]) {
            has_active_request = false;
            return;
        }
        //NSLog(@"Sending message.");
        has_active_request = YES;
        NSDictionary* message = [queue objectAtIndex:0];
        [_watch appMessagesPushUpdate:message onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
            if(!error) {
                if(queue.count > 0) {
                    [queue removeObjectAtIndex:0];
                }
                failureCount = 0;
                DebugLog(@"Successfully pushed: %@", message);
            } else {
                DebugLog(@"Send failed; will retransmit.");
                DebugLog(@"Error: %@", error);
                sleep(1);
                if(++failureCount > 5) {
                    [queue removeAllObjects];
                    DebugLog(@"Aborting.");
                }
            }
            has_active_request = NO;
            DebugLog(@"Next message.");
            if(stopMessages) {
                [queue removeAllObjects];
                stopMessages = false;
            }
            else {
                [self sendRequest];
            }
        }];
    }
}

- (void)clear {
    DebugLog(@"BEGIN");
    stopMessages = true;
}


@end
