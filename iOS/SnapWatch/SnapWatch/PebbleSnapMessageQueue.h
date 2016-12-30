
#import <Foundation/Foundation.h>




@class PBWatch;

@interface PebbleSnapMessageQueue : NSObject {
    NSMutableArray *queue;
    BOOL has_active_request;
}

- (void)enqueue:(NSDictionary*)message;
- (void)clear;

@property (nonatomic, retain) PBWatch* watch;

@end
